"""Flujo completo de una consulta al asistente.

1. Valida la pregunta y aplica idempotencia por `client_request_id`, con un
   bloqueo por (cuenta, identificador) para que dos envíos simultáneos no
   paguen dos veces.
2. Recupera fragmentos; si no hay respaldo, se abstiene SIN reservar ni
   llamar al proveedor.
3. Reserva presupuesto (o rechaza por límite).
4. Llama una sola vez al proveedor (sin reintentos).
5. Concilia el consumo, o deja la reserva incierta o liberada según el fallo.
6. Guarda la consulta validando las citas contra lo enviado.
"""

import zlib
from contextlib import contextmanager

from django.db import connection

from apps.library.models import LegalArea, SourceFragment

from . import budget
from .models import Consultation, ConsultationStatus, UsagePurpose
from .providers import ProviderError, estimated_input_tokens, get_answerer
from .retrieval import retrieve
from .services import AnswerResult, ConsultationError, find_existing, record_consultation, validate_question

# Espacio de claves de los bloqueos por solicitud (distinto del de presupuesto).
REQUEST_LOCK_NAMESPACE = 74_101_016


class ContextTooLarge(Exception):
    code = 'context_too_large'


@contextmanager
def request_lock(user_id: int, client_request_id):
    """Bloqueo de sesión de PostgreSQL por (cuenta, identificador de solicitud)."""
    key = zlib.crc32(f'{user_id}:{client_request_id}'.encode()) - 2**31
    with connection.cursor() as cursor:
        cursor.execute('SELECT pg_advisory_lock(%s, %s)', [REQUEST_LOCK_NAMESPACE, key])
    try:
        yield
    finally:
        with connection.cursor() as cursor:
            cursor.execute('SELECT pg_advisory_unlock(%s, %s)', [REQUEST_LOCK_NAMESPACE, key])


def _record(user, area, question, request_id, result, sent):
    return record_consultation(
        user=user,
        area=area,
        question=question,
        client_request_id=request_id,
        result=result,
        sent_fragments=sent,
    )


def ask(*, user, area: LegalArea, question: str, client_request_id, answerer=None):
    """Devuelve `(consulta, creada)`. Lanza errores de presupuesto o validación."""
    text = validate_question(question)
    with request_lock(user.pk, client_request_id):
        existing = find_existing(user, client_request_id, text)
        if existing is not None:
            return existing, False

        retrieval = retrieve(text, area)
        if not retrieval.sufficient:
            consultation = _record(
                user, area, text, client_request_id,
                AnswerResult(status=ConsultationStatus.NO_SUPPORT), [],
            )
            return consultation, True

        config = budget.BudgetConfig.from_settings()
        if estimated_input_tokens(text, retrieval.fragments) > config.max_input_tokens:
            raise ContextTooLarge('El contexto supera el máximo reservado.')

        provider = answerer or get_answerer()
        usage = budget.reserve(user=user, purpose=UsagePurpose.CONSULTATION)

        by_id = SourceFragment.objects.in_bulk([f.id for f in retrieval.fragments])
        sent = [by_id[f.id] for f in retrieval.fragments if f.id in by_id]

        try:
            reply = provider.answer(
                question=text,
                area=area,
                fragments=retrieval.fragments,
                max_output_tokens=config.max_output_tokens,
            )
        except ProviderError as error:
            if error.billing == 'released':
                budget.release(usage, note=error.code)
            else:
                budget.mark_uncertain(usage, note=error.code)
            consultation = _record(
                user, area, text, client_request_id,
                AnswerResult(status=ConsultationStatus.ERROR, error_code=error.code), sent,
            )
            _link(usage, consultation)
            return consultation, True

        budget.reconcile(
            usage, input_tokens=reply.input_tokens, output_tokens=reply.output_tokens
        )
        try:
            consultation = _record(user, area, text, client_request_id, reply.result, sent)
        except ConsultationError as error:
            consultation = _record(
                user, area, text, client_request_id,
                AnswerResult(status=ConsultationStatus.ERROR, error_code=error.code), sent,
            )
        _link(usage, consultation)
        return consultation, True


def _link(usage, consultation: Consultation):
    type(usage).objects.filter(pk=usage.pk).update(consultation=consultation)
