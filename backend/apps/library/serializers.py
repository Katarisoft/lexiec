from rest_framework import serializers

from .models import LegalArea, SourceDocument, SourceFragment, TopicCard

MAX_SEARCH_LENGTH = 100


class AreaSerializer(serializers.ModelSerializer):
    published_topics = serializers.IntegerField(read_only=True)

    class Meta:
        model = LegalArea
        fields = ('id', 'slug', 'name', 'description', 'order', 'published_topics')


class AreaSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = LegalArea
        fields = ('slug', 'name')


class TopicListSerializer(serializers.ModelSerializer):
    area = AreaSummarySerializer(read_only=True)

    class Meta:
        model = TopicCard
        fields = ('id', 'slug', 'title', 'area', 'summary')


class DocumentSerializer(serializers.ModelSerializer):
    validity_status_label = serializers.CharField(
        source='get_validity_status_display', read_only=True
    )

    class Meta:
        model = SourceDocument
        fields = (
            'id',
            'title',
            'institution',
            'official_url',
            'publication_reference',
            'publication_date',
            'version_label',
            'retrieved_at',
            'reviewed_at',
            'validity_status',
            'validity_status_label',
            'validity_checked_at',
            'limitations',
        )


class SourceSerializer(serializers.ModelSerializer):
    document = DocumentSerializer(read_only=True)

    class Meta:
        model = SourceFragment
        fields = ('id', 'locator', 'text', 'reviewed_at', 'document')


class TopicDetailSerializer(serializers.ModelSerializer):
    area = AreaSummarySerializer(read_only=True)
    sources = SourceSerializer(source='published_fragments', many=True, read_only=True)

    class Meta:
        model = TopicCard
        fields = (
            'id',
            'slug',
            'title',
            'area',
            'summary',
            'search_terms',
            'reviewed_at',
            'updated_at',
            'sources',
        )


class TopicQuerySerializer(serializers.Serializer):
    """Parámetros de consulta del listado de fichas."""

    area = serializers.SlugField(required=False, max_length=64)
    search = serializers.CharField(required=False, max_length=MAX_SEARCH_LENGTH)
    page = serializers.IntegerField(required=False, min_value=1)
