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
    def published(self):
        """Fragmentos aprobados de documentos aprobados y publicados.

        Es lo único que la API muestra como fuente de una ficha.
        """
        return self.filter(
            review_status=ReviewStatus.APPROVED,
            document__review_status=ReviewStatus.APPROVED,
            document__publication_status=PublicationStatus.PUBLISHED,
        )

    def eligible_for_assistant(self):
        """Único conjunto que puede alimentar al asistente (mismo criterio)."""
        return self.published()
