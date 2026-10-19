from django.db.models import Count, F, Func, Prefetch, Q, TextField, Value
from rest_framework import generics
from rest_framework.pagination import PageNumberPagination

from config.api_errors import SemanticValidationError

from .choices import PublicationStatus, ReviewStatus
from .models import LegalArea, SourceFragment, TopicCard
from .serializers import (
    AreaSerializer,
    TopicDetailSerializer,
    TopicListSerializer,
    TopicQuerySerializer,
)


class TopicPagination(PageNumberPagination):
    page_size = 20


class AreaListView(generics.ListAPIView):
    serializer_class = AreaSerializer
    pagination_class = None

    def get_queryset(self):
        published = Q(
            topics__publication_status=PublicationStatus.PUBLISHED,
            topics__review_status=ReviewStatus.APPROVED,
        )
        return LegalArea.objects.annotate(published_topics=Count('topics', filter=published))


class TopicListView(generics.ListAPIView):
    serializer_class = TopicListSerializer
    pagination_class = TopicPagination

    def get_queryset(self):
        params = TopicQuerySerializer(data=self.request.query_params)
        params.is_valid(raise_exception=True)
        filters = params.validated_data

        queryset = TopicCard.objects.published().select_related('area')

        area_slug = filters.get('area')
        if area_slug:
            if not LegalArea.objects.filter(slug=area_slug).exists():
                raise SemanticValidationError(
                    'El área indicada no existe.', code='unknown_area'
                )
            queryset = queryset.filter(area__slug=area_slug)

        search = filters.get('search', '').strip()
        if search:
            queryset = queryset.annotate(
                terms_text=Func(
                    F('search_terms'),
                    Value(' '),
                    function='array_to_string',
                    output_field=TextField(),
                )
            ).filter(
                Q(title__icontains=search)
                | Q(summary__icontains=search)
                | Q(terms_text__icontains=search)
            )

        return queryset.order_by('area__order', 'title', 'id')


class TopicDetailView(generics.RetrieveAPIView):
    serializer_class = TopicDetailSerializer

    def get_queryset(self):
        return (
            TopicCard.objects.published()
            .select_related('area')
            .prefetch_related(
                Prefetch(
                    'fragments',
                    queryset=SourceFragment.objects.published()
                    .select_related('document')
                    .order_by('document__title', 'order', 'locator'),
                    to_attr='published_fragments',
                )
            )
        )
