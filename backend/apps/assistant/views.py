from django.db.models import Prefetch
from rest_framework import generics, mixins
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated

from .models import Consultation, ConsultationCitation
from .serializers import ConsultationDetailSerializer, ConsultationListSerializer


class ConsultationPagination(PageNumberPagination):
    page_size = 20


def own_consultations(user):
    """Toda consulta se filtra por propietario: las ajenas no existen (404)."""
    return Consultation.objects.filter(user=user).select_related('area')


class ConsultationListView(generics.ListAPIView):
    """Historial privado. La creación llegará con el asistente (E16/E17)."""

    serializer_class = ConsultationListSerializer
    pagination_class = ConsultationPagination
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return own_consultations(self.request.user)


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
