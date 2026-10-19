"""Registro de consultas desacoplado del proveedor de IA.

El proveedor (E16) solo devuelve un `AnswerResult`; este servicio valida las
citas contra los fragmentos enviados y guarda la consulta de forma
idempotente. Nunca inventa respuestas: si no hay respaldo, se guarda como
`no_support`; si falla el proveedor, como `error` sin respuesta.
"""

from dataclasses import dataclass, field
from typing import Optional, Protocol, Sequence

from django.db import IntegrityError, transaction

from apps.library.models import LegalArea, SourceFragment

from .models import QUESTION_MAX_LENGTH, Consultation, ConsultationCitation, ConsultationStatus


@dataclass(frozen=True)
class AnswerResult:
    status: str
    answer: str = ''
    limitations: str = ''
    cited_fragment_ids: Sequence[int] = field(default_factory=tuple)
    error_code: str = ''


class Answerer(Protocol):
    """Interfaz del proveedor. Recibe solo la pregunta, el área y los
    fragmentos elegibles; nunca comentarios ni historial."""

    def answer(
        self, *, question: str, area: LegalArea, fragments: Sequence[SourceFragment]
    ) -> AnswerResult: ...


class ConsultationError(ValueError):
    """Resultado no válido para guardar (citas o estado incoherentes)."""

    def __init__(self, code, message):
        super().__init__(message)
        self.code = code


class IdempotencyConflict(ConsultationError):
    def __init__(self):
        super().__init__(
            'request_id_conflict',
            'El identificador de solicitud ya se usó con otra pregunta.',
        )


def validate_question(question: str) -> str:
    text = (question or '').strip()
    if not text:
        raise ConsultationError('empty_question', 'La pregunta no puede estar vacía.')
    if len(text) > QUESTION_MAX_LENGTH:
        raise ConsultationError(
            'question_too_long', f'La pregunta supera {QUESTION_MAX_LENGTH} caracteres.'
        )
    return text


def find_existing(user, client_request_id, question: str) -> Optional[Consultation]:
    """Devuelve la consulta ya registrada con ese identificador, si existe.

    Reutilizar el identificador con otra pregunta es un conflicto.
    """
    existing = Consultation.objects.filter(
        user=user, client_request_id=client_request_id
    ).first()
    if existing is not None and existing.question != question:
        raise IdempotencyConflict()
    return existing


def _validated_citations(result: AnswerResult, sent_fragments: Sequence[SourceFragment]):
    sent = {fragment.pk: fragment for fragment in sent_fragments}
    eligible = set(
        SourceFragment.objects.eligible_for_assistant()
        .filter(pk__in=sent.keys())
        .values_list('pk', flat=True)
    )
    ordered_ids = list(dict.fromkeys(result.cited_fragment_ids))
    for fragment_id in ordered_ids:
        if fragment_id not in sent:
            raise ConsultationError(
                'unknown_citation', f'Cita {fragment_id} no corresponde a los fragmentos enviados.'
            )
        if fragment_id not in eligible:
            raise ConsultationError(
                'ineligible_citation', f'El fragmento {fragment_id} no está publicado y revisado.'
            )
    return [sent[fragment_id] for fragment_id in ordered_ids]


def record_consultation(
    *,
    user,
    area: LegalArea,
    question: str,
    client_request_id,
    result: AnswerResult,
    sent_fragments: Sequence[SourceFragment],
) -> Consultation:
    """Valida y guarda una consulta. Idempotente por (cuenta, identificador)."""
    text = validate_question(question)
    existing = find_existing(user, client_request_id, text)
    if existing is not None:
        return existing

    if result.status not in ConsultationStatus.values:
        raise ConsultationError('invalid_status', 'Estado de consulta desconocido.')

    citations = []
    if result.status == ConsultationStatus.ANSWERED:
        if not result.answer.strip():
            raise ConsultationError('empty_answer', 'Una respuesta necesita texto.')
        citations = _validated_citations(result, sent_fragments)
        if not citations:
            raise ConsultationError(
                'answer_without_citations', 'Una respuesta afirmativa requiere citas.'
            )
    elif result.cited_fragment_ids:
        raise ConsultationError(
            'citations_without_answer', 'Solo las respuestas respaldadas llevan citas.'
        )

    answer = result.answer.strip() if result.status != ConsultationStatus.ERROR else ''
    try:
        with transaction.atomic():
            consultation = Consultation.objects.create(
                user=user,
                area=area,
                client_request_id=client_request_id,
                question=text,
                status=result.status,
                answer=answer,
                limitations=result.limitations.strip(),
                error_code=result.error_code if result.status == ConsultationStatus.ERROR else '',
            )
            ConsultationCitation.objects.bulk_create(
                ConsultationCitation(
                    consultation=consultation,
                    fragment=fragment,
                    quoted_text=fragment.text,
                    locator=fragment.locator,
                    document_title=fragment.document.title,
                    official_url=fragment.document.official_url,
                    order=index,
                )
                for index, fragment in enumerate(citations)
            )
    except IntegrityError:
        # Dos envíos simultáneos con el mismo identificador.
        existing = find_existing(user, client_request_id, text)
        if existing is None:
            raise
        return existing
    return consultation
