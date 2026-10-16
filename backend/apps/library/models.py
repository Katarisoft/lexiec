"""Modelos de la biblioteca documental de LexiEC.

La revisión humana, la publicación y la vigencia se registran por separado:
un documento oficial publicado en la app no implica que su texto esté
consolidado ni vigente.
"""

from django.conf import settings
from django.contrib.postgres.fields import ArrayField
from django.core.exceptions import ValidationError
from django.core.validators import URLValidator
from django.db import models
from django.db.models import Q

from .choices import PublicationStatus, ReviewStatus, ValidityStatus
from .querysets import SourceFragmentQuerySet, TopicCardQuerySet


class TimestampedModel(models.Model):
    created_at = models.DateTimeField('creado', auto_now_add=True)
    updated_at = models.DateTimeField('actualizado', auto_now=True)

    class Meta:
        abstract = True


class ReviewFields(models.Model):
    """Registro de la revisión humana del contenido."""

    review_status = models.CharField(
        'estado de revisión',
        max_length=16,
        choices=ReviewStatus.choices,
        default=ReviewStatus.PENDING,
    )
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        verbose_name='revisado por',
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name='+',
    )
    reviewed_at = models.DateTimeField('fecha de revisión', null=True, blank=True)
    review_notes = models.TextField('notas de revisión', blank=True)

    class Meta:
        abstract = True

    @classmethod
    def approved_requires_reviewer(cls, name):
        """Restricción: un contenido aprobado debe indicar quién y cuándo."""
        return models.CheckConstraint(
            condition=~Q(review_status=ReviewStatus.APPROVED)
            | Q(reviewed_by__isnull=False, reviewed_at__isnull=False),
            name=name,
        )

    def clean_review(self):
        if self.review_status == ReviewStatus.APPROVED and (
            self.reviewed_by_id is None or self.reviewed_at is None
        ):
            raise ValidationError(
                'Un contenido aprobado debe indicar quién lo revisó y cuándo.'
            )


def published_requires_approval(name):
    """Restricción: no se publica nada sin revisión aprobada."""
    return models.CheckConstraint(
        condition=~Q(publication_status=PublicationStatus.PUBLISHED)
        | Q(review_status=ReviewStatus.APPROVED),
        name=name,
    )


class LegalArea(TimestampedModel):
    slug = models.SlugField('identificador', max_length=64, unique=True)
    name = models.CharField('nombre', max_length=120, unique=True)
    description = models.TextField('descripción', blank=True)
    order = models.PositiveSmallIntegerField('orden', default=0)

    class Meta:
        ordering = ['order', 'name']
        verbose_name = 'área jurídica'
        verbose_name_plural = 'áreas jurídicas'

    def __str__(self):
        return self.name


class SourceDocument(TimestampedModel, ReviewFields):
    institution = models.CharField('institución emisora', max_length=200)
    title = models.CharField('título', max_length=300)
    official_url = models.URLField(
        'URL oficial',
        max_length=500,
        validators=[URLValidator(schemes=['https'])],
    )
    publication_reference = models.CharField(
        'referencia de publicación',
        max_length=200,
        blank=True,
        help_text='Por ejemplo, edición y número del Registro Oficial.',
    )
    publication_date = models.DateField(
        'fecha de publicación conocida', null=True, blank=True
    )
    version_label = models.CharField(
        'versión identificada',
        max_length=200,
        help_text='Edición o versión del texto consultado (por ejemplo, última reforma identificada).',
    )
    retrieved_at = models.DateField('fecha de consulta')
    text_hash = models.CharField(
        'hash SHA-256 del texto',
        max_length=64,
        blank=True,
        help_text='Opcional: hash del texto incorporado, para detectar cambios.',
    )
    publication_status = models.CharField(
        'estado de publicación en la app',
        max_length=16,
        choices=PublicationStatus.choices,
        default=PublicationStatus.DRAFT,
    )
    validity_status = models.CharField(
        'vigencia',
        max_length=20,
        choices=ValidityStatus.choices,
        default=ValidityStatus.NOT_VERIFIED,
    )
    validity_checked_at = models.DateField(
        'fecha de comprobación de vigencia', null=True, blank=True
    )
    validity_note = models.TextField('evidencia de vigencia', blank=True)
    limitations = models.TextField(
        'limitaciones',
        blank=True,
        help_text='Advertencias visibles: texto no consolidado, reformas pendientes, etc.',
    )

    class Meta:
        ordering = ['title']
        verbose_name = 'documento fuente'
        verbose_name_plural = 'documentos fuente'
        constraints = [
            published_requires_approval('sourcedocument_published_requires_approval'),
            ReviewFields.approved_requires_reviewer(
                'sourcedocument_approved_requires_reviewer'
            ),
            models.CheckConstraint(
                condition=~Q(validity_status=ValidityStatus.VERIFIED_CURRENT)
                | (Q(validity_checked_at__isnull=False) & ~Q(validity_note='')),
                name='sourcedocument_verified_requires_evidence',
            ),
        ]

    def __str__(self):
        return self.title

    def clean(self):
        super().clean()
        self.clean_review()
        if (
            self.publication_status == PublicationStatus.PUBLISHED
            and self.review_status != ReviewStatus.APPROVED
        ):
            raise ValidationError('No se puede publicar un documento sin revisión aprobada.')
        if self.validity_status == ValidityStatus.VERIFIED_CURRENT and (
            self.validity_checked_at is None or not self.validity_note.strip()
        ):
            raise ValidationError(
                'La vigencia comprobada requiere fecha de comprobación y evidencia.'
            )


class SourceFragment(TimestampedModel, ReviewFields):
    document = models.ForeignKey(
        SourceDocument,
        verbose_name='documento',
        on_delete=models.PROTECT,
        related_name='fragments',
    )
    locator = models.CharField(
        'localizador',
        max_length=120,
        help_text='Artículo, página o sección dentro del documento.',
    )
    text = models.TextField('texto')
    order = models.PositiveIntegerField('orden', default=0)

    objects = SourceFragmentQuerySet.as_manager()

    class Meta:
        ordering = ['document', 'order', 'locator']
        verbose_name = 'fragmento'
        verbose_name_plural = 'fragmentos'
        constraints = [
            models.UniqueConstraint(
                fields=['document', 'locator'],
                name='sourcefragment_unique_locator_per_document',
            ),
            ReviewFields.approved_requires_reviewer(
                'sourcefragment_approved_requires_reviewer'
            ),
        ]
        indexes = [
            models.Index(fields=['document', 'order'], name='fragment_document_order_idx'),
        ]

    def __str__(self):
        return f'{self.document} — {self.locator}'

    def clean(self):
        super().clean()
        self.clean_review()


class TopicCard(TimestampedModel, ReviewFields):
    area = models.ForeignKey(
        LegalArea,
        verbose_name='área',
        on_delete=models.PROTECT,
        related_name='topics',
    )
    slug = models.SlugField('identificador', max_length=120, unique=True)
    title = models.CharField('título', max_length=200)
    summary = models.TextField('explicación')
    search_terms = ArrayField(
        models.CharField(max_length=80),
        verbose_name='términos de búsqueda',
        default=list,
        blank=True,
        help_text='Separados por comas.',
    )
    fragments = models.ManyToManyField(
        SourceFragment,
        verbose_name='fragmentos de respaldo',
        related_name='topics',
        blank=True,
    )
    publication_status = models.CharField(
        'estado de publicación',
        max_length=16,
        choices=PublicationStatus.choices,
        default=PublicationStatus.DRAFT,
    )

    objects = TopicCardQuerySet.as_manager()

    class Meta:
        ordering = ['area', 'title']
        verbose_name = 'ficha temática'
        verbose_name_plural = 'fichas temáticas'
        constraints = [
            published_requires_approval('topiccard_published_requires_approval'),
            ReviewFields.approved_requires_reviewer('topiccard_approved_requires_reviewer'),
        ]
        indexes = [
            models.Index(
                fields=['area', 'publication_status'],
                name='topic_area_publication_idx',
            ),
        ]

    def __str__(self):
        return self.title

    def clean(self):
        super().clean()
        self.clean_review()
        if (
            self.publication_status == PublicationStatus.PUBLISHED
            and self.review_status != ReviewStatus.APPROVED
        ):
            raise ValidationError('No se puede publicar una ficha sin revisión aprobada.')
