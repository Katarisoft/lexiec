"""Consultas que delimitan qué contenido es publicable o utilizable por la IA."""

from django.db import models

from .choices import PublicationStatus, ReviewStatus


class TopicCardQuerySet(models.QuerySet):
    def published(self):
        """Fichas revisadas y publicadas; los borradores nunca se incluyen."""
        return self.filter(
            publication_status=PublicationStatus.PUBLISHED,
            review_status=ReviewStatus.APPROVED,
        )


class SourceFragmentQuerySet(models.QuerySet):
    def eligible_for_assistant(self):
        """Fragmentos aprobados de documentos aprobados y publicados.

        Es el único conjunto que puede alimentar al asistente.
        """
        return self.filter(
            review_status=ReviewStatus.APPROVED,
            document__review_status=ReviewStatus.APPROVED,
            document__publication_status=PublicationStatus.PUBLISHED,
        )
