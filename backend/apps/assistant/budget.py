"""Control de presupuesto de la API de pago (único proveedor: Anthropic).

Reglas:
- Antes de cada llamada se RESERVA el coste máximo posible
  (tokens máximos de entrada y salida × tarifas). Si la reserva supera el
  límite operativo, no se llama.
- Después se CONCILIA con el consumo informado por el proveedor.
- Si hubo timeout y no se sabe cuánto se gastó, la reserva queda INCIERTA y
  sigue contando: no se libera dinero posiblemente gastado.
- Solo se LIBERA si es seguro que la petición no llegó a enviarse.
- Falla de forma cerrada si faltan tarifas o la configuración es incoherente.
- Sin reintentos automáticos de pago: este módulo nunca llama al proveedor.

Las reservas concurrentes se serializan con un bloqueo de PostgreSQL
(pg_advisory_xact_lock), sin servicios adicionales.

El registro es una ESTIMACIÓN: debe contrastarse con la Console de Anthropic
y no garantiza por sí solo el importe exacto de la factura.
"""

from dataclasses import dataclass
from datetime import timedelta
from decimal import ROUND_UP, Decimal

from django.conf import settings
from django.db import connection, transaction
from django.db.models import Count, Q, Sum
from django.utils import timezone

from .models import AIUsage, UsagePurpose, UsageStatus

# Clave arbitraria y estable del bloqueo consultivo de presupuesto.
BUDGET_LOCK_KEY = 74_101_015
MILLION = Decimal(1_000_000)
USD_PLACES = Decimal('0.000001')


class BudgetError(Exception):
    code = 'budget_error'


class BudgetNotConfigured(BudgetError):
    """Tarifas o límites ausentes o incoherentes: no se llama al proveedor."""

    code = 'budget_not_configured'


class BudgetExhausted(BudgetError):
    """La reserva superaría el límite operativo."""

    code = 'budget_exhausted'


class UserQuotaExceeded(BudgetError):
    """La cuenta alcanzó su límite diario de consultas."""

    code = 'user_quota_exceeded'


class InvalidTransition(BudgetError):
    code = 'invalid_transition'


def _decimal_setting(name):
    value = getattr(settings, name, None)
    if value in (None, ''):
        raise BudgetNotConfigured(f'Falta configurar {name}.')
    try:
        number = Decimal(str(value))
    except ArithmeticError as error:
        raise BudgetNotConfigured(f'{name} no es un número válido.') from error
    if number < 0:
        raise BudgetNotConfigured(f'{name} no puede ser negativo.')
    return number


def _int_setting(name):
    value = getattr(settings, name, None)
    try:
        number = int(value)
    except (TypeError, ValueError) as error:
        raise BudgetNotConfigured(f'Falta configurar {name}.') from error
    if number <= 0:
        raise BudgetNotConfigured(f'{name} debe ser positivo.')
    return number


@dataclass(frozen=True)
class BudgetConfig:
    model: str
    input_price_per_mtok: Decimal
    output_price_per_mtok: Decimal
    max_input_tokens: int
    max_output_tokens: int
    budget_usd: Decimal
    operating_limit_usd: Decimal
    daily_user_limit: int
    price_tier_input_limit: int

    @classmethod
    def from_settings(cls):
        config = cls(
            model=getattr(settings, 'ASSISTANT_MODEL', '') or '',
            input_price_per_mtok=_decimal_setting('ASSISTANT_PRICE_INPUT_PER_MTOK'),
            output_price_per_mtok=_decimal_setting('ASSISTANT_PRICE_OUTPUT_PER_MTOK'),
            max_input_tokens=_int_setting('ASSISTANT_MAX_INPUT_TOKENS'),
            max_output_tokens=_int_setting('ASSISTANT_MAX_OUTPUT_TOKENS'),
            budget_usd=_decimal_setting('AI_BUDGET_USD'),
            operating_limit_usd=_decimal_setting('AI_OPERATING_LIMIT_USD'),
            daily_user_limit=_int_setting('ASSISTANT_DAILY_LIMIT_PER_USER'),
            price_tier_input_limit=_int_setting('ASSISTANT_PRICE_TIER_INPUT_LIMIT'),
        )
        if not config.model:
            raise BudgetNotConfigured('Falta configurar ASSISTANT_MODEL.')
        if config.input_price_per_mtok == 0 or config.output_price_per_mtok == 0:
            raise BudgetNotConfigured('Las tarifas no pueden ser cero.')
        if config.operating_limit_usd > config.budget_usd:
            raise BudgetNotConfigured('El límite operativo no puede superar el presupuesto global.')
        if config.max_input_tokens > config.price_tier_input_limit:
            # Por encima del umbral la tarifa cambia: la reserva no sería fiable.
            raise BudgetNotConfigured(
                'ASSISTANT_MAX_INPUT_TOKENS supera el tramo de precio configurado.'
            )
        return config

    def cost(self, input_tokens: int, output_tokens: int) -> Decimal:
        total = (
            Decimal(input_tokens) * self.input_price_per_mtok
            + Decimal(output_tokens) * self.output_price_per_mtok
        ) / MILLION
        return total.quantize(USD_PLACES, rounding=ROUND_UP)

    @property
    def max_cost(self) -> Decimal:
        return self.cost(self.max_input_tokens, self.max_output_tokens)


@dataclass(frozen=True)
class BudgetStatus:
    committed_usd: Decimal
    reconciled_usd: Decimal
    pending_usd: Decimal
    uncertain_count: int
    operating_limit_usd: Decimal
    budget_usd: Decimal

    @property
    def available_usd(self) -> Decimal:
        return max(self.operating_limit_usd - self.committed_usd, Decimal('0'))


def committed_usd() -> Decimal:
    """Consumo conciliado + reservas en curso o inciertas (las liberadas no cuentan)."""
    totals = AIUsage.objects.aggregate(
        reconciled=Sum('actual_usd', filter=Q(status=UsageStatus.RECONCILED)),
        pending=Sum(
            'reserved_usd', filter=Q(status__in=[UsageStatus.RESERVED, UsageStatus.UNCERTAIN])
        ),
    )
    return (totals['reconciled'] or Decimal('0')) + (totals['pending'] or Decimal('0'))


def status() -> BudgetStatus:
    config = BudgetConfig.from_settings()
    totals = AIUsage.objects.aggregate(
        reconciled=Sum('actual_usd', filter=Q(status=UsageStatus.RECONCILED)),
        pending=Sum(
            'reserved_usd', filter=Q(status__in=[UsageStatus.RESERVED, UsageStatus.UNCERTAIN])
        ),
        uncertain=Count('id', filter=Q(status=UsageStatus.UNCERTAIN)),
    )
    reconciled = totals['reconciled'] or Decimal('0')
    pending = totals['pending'] or Decimal('0')
    return BudgetStatus(
        committed_usd=reconciled + pending,
        reconciled_usd=reconciled,
        pending_usd=pending,
        uncertain_count=totals['uncertain'],
        operating_limit_usd=config.operating_limit_usd,
        budget_usd=config.budget_usd,
    )


def _lock():
    with connection.cursor() as cursor:
        cursor.execute('SELECT pg_advisory_xact_lock(%s)', [BUDGET_LOCK_KEY])


def reserve(*, user=None, purpose=UsagePurpose.CONSULTATION, note='') -> AIUsage:
    """Reserva el coste máximo de una llamada o lanza un BudgetError.

    Debe llamarse ANTES de contactar al proveedor; si lanza, no se llama.
    """
    config = BudgetConfig.from_settings()
    amount = config.max_cost
    with transaction.atomic():
        _lock()
        if user is not None and purpose == UsagePurpose.CONSULTATION:
            since = timezone.now() - timedelta(days=1)
            used = (
                AIUsage.objects.filter(user=user, purpose=purpose, created_at__gte=since)
                .exclude(status=UsageStatus.RELEASED)
                .count()
            )
            if used >= config.daily_user_limit:
                raise UserQuotaExceeded('Límite diario de consultas alcanzado.')
        if committed_usd() + amount > config.operating_limit_usd:
            raise BudgetExhausted('Presupuesto operativo agotado.')
        return AIUsage.objects.create(
            user=user,
            purpose=purpose,
            status=UsageStatus.RESERVED,
            model_name=config.model,
            reserved_usd=amount,
            note=note[:200],
        )


def _transition(usage_id, allowed, **changes) -> AIUsage:
    with transaction.atomic():
        usage = AIUsage.objects.select_for_update().get(pk=usage_id)
        if usage.status not in allowed:
            raise InvalidTransition(
                f'No se puede pasar de {usage.status} con esta operación.'
            )
        for field, value in changes.items():
            setattr(usage, field, value)
        usage.resolved_at = timezone.now()
        usage.save()
        return usage


def reconcile(usage: AIUsage, *, input_tokens: int, output_tokens: int) -> AIUsage:
    """Registra el consumo informado por el proveedor (tokens de la respuesta)."""
    config = BudgetConfig.from_settings()
    return _transition(
        usage.pk,
        {UsageStatus.RESERVED, UsageStatus.UNCERTAIN},
        status=UsageStatus.RECONCILED,
        input_tokens=input_tokens,
        output_tokens=output_tokens,
        actual_usd=config.cost(input_tokens, output_tokens),
    )


def mark_uncertain(usage: AIUsage, *, note='') -> AIUsage:
    """Timeout o error con consumo desconocido: la reserva sigue contando."""
    return _transition(
        usage.pk, {UsageStatus.RESERVED}, status=UsageStatus.UNCERTAIN, note=note[:200]
    )


def release(usage: AIUsage, *, note='') -> AIUsage:
    """Solo si es SEGURO que la petición nunca se envió al proveedor."""
    return _transition(
        usage.pk, {UsageStatus.RESERVED}, status=UsageStatus.RELEASED, note=note[:200]
    )


def resolve_uncertain(usage: AIUsage, *, actual_usd: Decimal, note='') -> AIUsage:
    """Conciliación manual de un caso incierto con el importe visto en la Console."""
    if actual_usd < 0:
        raise InvalidTransition('El importe no puede ser negativo.')
    return _transition(
        usage.pk,
        {UsageStatus.UNCERTAIN},
        status=UsageStatus.RECONCILED,
        actual_usd=Decimal(actual_usd).quantize(USD_PLACES, rounding=ROUND_UP),
        note=note[:200],
    )


def record_manual(*, actual_usd: Decimal, note='') -> AIUsage:
    """Descuenta consumo hecho fuera de la app (Console, pruebas manuales)."""
    if actual_usd < 0:
        raise InvalidTransition('El importe no puede ser negativo.')
    amount = Decimal(actual_usd).quantize(USD_PLACES, rounding=ROUND_UP)
    with transaction.atomic():
        _lock()
        return AIUsage.objects.create(
            purpose=UsagePurpose.MANUAL,
            status=UsageStatus.RECONCILED,
            reserved_usd=amount,
            actual_usd=amount,
            note=note[:200],
            resolved_at=timezone.now(),
        )
