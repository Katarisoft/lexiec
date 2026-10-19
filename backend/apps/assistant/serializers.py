from rest_framework import serializers

from apps.library.serializers import AreaSummarySerializer

from .models import Consultation, ConsultationCitation


class CitationSerializer(serializers.ModelSerializer):
    class Meta:
        model = ConsultationCitation
        fields = ('fragment', 'locator', 'document_title', 'official_url', 'quoted_text')


class ConsultationListSerializer(serializers.ModelSerializer):
    area = AreaSummarySerializer(read_only=True)
    status_label = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Consultation
        fields = ('id', 'area', 'question', 'status', 'status_label', 'created_at')


class ConsultationDetailSerializer(ConsultationListSerializer):
    citations = CitationSerializer(many=True, read_only=True)

    class Meta(ConsultationListSerializer.Meta):
        fields = ConsultationListSerializer.Meta.fields + (
            'answer',
            'limitations',
            'error_code',
            'citations',
        )
