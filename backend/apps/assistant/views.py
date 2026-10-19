from django.db.models import Prefetch
from rest_framework import exceptions, generics, mixins, status
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from apps.library.models import LegalArea
from config.api_errors import SemanticValidationError

from . import budget
from .models import Consultation, ConsultationCitation
from .orchestrator import ContextTooLarge, ask
from .providers import ProviderNotConfigured
from .serializers import (
    ConsultationCreateSerializer,
    ConsultationDetailSerializer,
    ConsultationListSerializer,
)
from .services import ConsultationError, IdempotencyConflict


class LimitReached(exceptions.APIException):
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    default_code = 'limit_reached'
    default_detail = 'Se alcanzó el límite de uso del asistente.'


class AssistantUnavailable(exceptions.APIException):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_code = 'assistant_unavailable'
    default_detail = 'El asistente no está disponible en este momento.'


class RequestConflict(exceptions.APIException):
    status_code = status.HTTP_409_CONFLICT
    default_code = 'request_id_conflict'
    default_detail = 'El identificador de solicitud ya se usó con otra pregunta.'


class ConsultationPagination(PageNumberPagination):
    page_size = 20


def own_consultations(user):
    """Toda consulta se filtra por propietario: las ajenas no existen (404)."""
    return Consultation.objects.filter(user=user).select_related('area')


class ConsultationListView(generics.ListAPIView):
    """Historial privado (GET) y nueva consulta al asistente (POST)."""

    serializer_class = ConsultationListSerializer
    pagination_class = ConsultationPagination
    permission_classes = [IsAuthenticated]
    throttle_scope = 'consultation'

    def get_throttles(self):
        if self.request.method == 'POST':
            return [ScopedRateThrottle()]
        return []

    def get_queryset(self):
        return own_consultations(self.request.user)

    def post(self, request):
        params = ConsultationCreateSerializer(data=request.data)
        params.is_valid(raise_exception=True)
        data = params.validated_data
        area = LegalArea.objects.filter(slug=data['area']).first()
        if area is None:
            raise SemanticValidationError('El área indicada no existe.', code='unknown_area')

        try:
            consultation, created = ask(
                user=request.user,
                area=area,
                question=data['question'],
                client_request_id=data['client_request_id'],
            )
        except IdempotencyConflict:
            raise RequestConflict()
        except ConsultationError as error:
            raise exceptions.ValidationError({'question': [str(error)]})
        except (budget.UserQuotaExceeded, budget.BudgetExhausted) as error:
            raise LimitReached(code=error.code)
        except (budget.BudgetNotConfigured, ProviderNotConfigured, ContextTooLarge):
            # Fallo cerrado: nunca se sustituye por respuestas simuladas.
            raise AssistantUnavailable()

        detail = own_consultations(request.user).prefetch_related('citations').get(
            pk=consultation.pk
        )
        return Response(
            ConsultationDetailSerializer(detail).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class ConsultationDetailView(mixins.DestroyModelMixin, generics.RetrieveAPIView):
    serializer_class = ConsultationDetailSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return own_consultations(self.request.user).prefetch_related(
            Prefetch('citations', queryset=ConsultationCitation.objects.order_by('order', 'id'))
        )

    def delete(self, request, *args, **kwargs):
        # Borra pregunta, respuesta y citas (en cascada).
        return self.destroy(request, *args, **kwargs)
