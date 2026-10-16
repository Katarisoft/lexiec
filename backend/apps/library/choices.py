"""Estados independientes de revisión, publicación y vigencia."""

from django.db import models


class ReviewStatus(models.TextChoices):
    PENDING = 'pending', 'Pendiente de revisión'
    APPROVED = 'approved', 'Aprobado'
    REJECTED = 'rejected', 'Rechazado'


class PublicationStatus(models.TextChoices):
    DRAFT = 'draft', 'Borrador'
    PUBLISHED = 'published', 'Publicado'


class ValidityStatus(models.TextChoices):
    NOT_VERIFIED = 'not_verified', 'Vigencia no comprobada'
    VERIFIED_CURRENT = 'verified_current', 'Vigencia comprobada'
    REPEALED = 'repealed', 'Derogado'
