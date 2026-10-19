"""Historial privado de consultas al asistente.

Cada consulta pertenece a una cuenta y solo su propietario puede verla o
borrarla. Borrar una consulta elimina la pregunta, la respuesta y sus citas.
"""

from django.conf import settings
from django.db import models
from django.db.models import Q

from apps.library.models import LegalArea, SourceFragment

QUESTION_MAX_LENGTH = 1000


class ConsultationStatus(models.TextChoices):
    ANSWERED = 'answered', 'Respondida con respaldo'
    NO_SUPPORT = 'no_support', 'Sin respaldo suficiente'
    ERROR = 'error', 'Error técnico'


class Consultation(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        verbose_name='cuenta',
        on_delete=models.CASCADE,
        related_name='consultations',
    )
    area = models.ForeignKey(
        LegalArea,
        verbose_name='área',
        on_delete=models.PROTECT,
        related_name='consultations',
    )
    client_request_id = models.UUIDField(
        'identificador de solicitud',
        help_text='Generado por la app para que un reenvío no duplique la consulta.',
    )
    question = models.TextField('pregunta', max_length=QUESTION_MAX_LENGTH)
    status = models.CharField('estado', max_length=16, choices=ConsultationStatus.choices)
    answer = models.TextField('respuesta', blank=True)
    limitations = models.TextField('limitaciones de la respuesta', blank=True)
    error_code = models.CharField(
        'código técnico de error',
        max_length=64,
        blank=True,
        help_text='Solo un código estable, nunca texto del proveedor ni datos de la pregunta.',
    )
    created_at = models.DateTimeField('creada', auto_now_add=True)
    updated_at = models.DateTimeField('actualizada', auto_now=True)

    class Meta:
        ordering = ['-created_at', '-id']
        verbose_name = 'consulta'
        verbose_name_plural = 'consultas'
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'client_request_id'],
                name='consultation_unique_request_per_user',
            ),
            models.CheckConstraint(
                condition=~Q(status=ConsultationStatus.ANSWERED) | ~Q(answer=''),
                name='consultation_answered_requires_answer',
            ),
            models.CheckConstraint(
                condition=~Q(status=ConsultationStatus.ERROR) | Q(answer=''),
                name='consultation_error_has_no_answer',
            ),
        ]
        indexes = [
            models.Index(fields=['user', '-created_at'], name='consultation_user_created_idx'),
        ]

    def __str__(self):
        return f'Consulta {self.pk} ({self.get_status_display()})'


class ConsultationCitation(models.Model):
    """Fragmento que respalda una respuesta, con la copia mostrada."""

    consultation = models.ForeignKey(
        Consultation,
        verbose_name='consulta',
        on_delete=models.CASCADE,
        related_name='citations',
    )
    # SET_NULL: la cita conserva su copia (texto, localizador, documento)
    # aunque el fragmento se elimine después.
    fragment = models.ForeignKey(
        SourceFragment,
        verbose_name='fragmento',
        null=True,
        on_delete=models.SET_NULL,
        related_name='citations',
    )
    quoted_text = models.TextField('respaldo mostrado')
    locator = models.CharField('localizador', max_length=120)
    document_title = models.CharField('documento', max_length=300)
    official_url = models.URLField('URL oficial', max_length=500)
    order = models.PositiveSmallIntegerField('orden', default=0)

    class Meta:
        ordering = ['consultation', 'order', 'id']
        verbose_name = 'cita'
        verbose_name_plural = 'citas'
        constraints = [
            models.UniqueConstraint(
                fields=['consultation', 'fragment'],
                name='citation_unique_fragment_per_consultation',
            ),
        ]

    def __str__(self):
        return f'{self.document_title} — {self.locator}'


class UsagePurpose(models.TextChoices):
    CONSULTATION = 'consultation', 'Consulta de la app'
    EVALUATION = 'evaluation', 'Evaluación (E18)'
    MANUAL = 'manual', 'Uso manual externo (Console u otros)'


class UsageStatus(models.TextChoices):
    RESERVED = 'reserved', 'Reservado (llamada en curso)'
    RECONCILED = 'reconciled', 'Conciliado con consumo informado'
    UNCERTAIN = 'uncertain', 'Incierto (consumo desconocido)'
    RELEASED = 'released', 'Liberado (la llamada no llegó a enviarse)'


class AIUsage(models.Model):
    """Registro de consumo estimado de la API de pago.

    No guarda texto de preguntas ni respuestas. Sobrevive al borrado de la
    consulta y de la cuenta para que el presupuesto no se «recupere».
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        verbose_name='cuenta',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='+',
    )
    consultation = models.ForeignKey(
        Consultation,
        verbose_name='consulta',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='+',
    )
    purpose = models.CharField('propósito', max_length=16, choices=UsagePurpose.choices)
    status = models.CharField('estado', max_length=16, choices=UsageStatus.choices)
    model_name = models.CharField('modelo', max_length=64, blank=True)
    reserved_usd = models.DecimalField('reservado (USD)', max_digits=10, decimal_places=6)
    actual_usd = models.DecimalField(
        'consumo conciliado (USD)', max_digits=10, decimal_places=6, null=True, blank=True
    )
    input_tokens = models.PositiveIntegerField('tokens de entrada', null=True, blank=True)
    output_tokens = models.PositiveIntegerField('tokens de salida', null=True, blank=True)
    note = models.CharField(
        'nota técnica', max_length=200, blank=True, help_text='Sin datos personales ni texto de consultas.'
    )
    created_at = models.DateTimeField('creado', auto_now_add=True)
    resolved_at = models.DateTimeField('resuelto', null=True, blank=True)

    class Meta:
        ordering = ['-created_at', '-id']
        verbose_name = 'consumo de IA'
        verbose_name_plural = 'consumos de IA'
        constraints = [
            models.CheckConstraint(
                condition=Q(reserved_usd__gte=0), name='aiusage_reserved_non_negative'
            ),
            models.CheckConstraint(
                condition=~Q(status=UsageStatus.RECONCILED) | Q(actual_usd__isnull=False),
                name='aiusage_reconciled_requires_actual',
            ),
        ]

    def __str__(self):
        return f'Consumo {self.pk} ({self.get_status_display()})'
