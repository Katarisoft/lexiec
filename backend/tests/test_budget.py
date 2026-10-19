"""Presupuesto de IA: reservas, conciliación, incertidumbre y concurrencia.

Ninguna prueba llama al proveedor. Las tarifas son ficticias y redondas.
"""

import threading
from decimal import Decimal
from io import StringIO

from django.core.management import call_command
from django.db import connection
from django.test import TestCase, TransactionTestCase, override_settings

from apps.assistant import budget
from apps.assistant.models import AIUsage, UsagePurpose, UsageStatus

from .test_accounts import create_account

# Coste máximo por llamada: (8000 × 1 + 1000 × 5) / 1e6 = 0.013 USD
TEST_BUDGET = {
    'ASSISTANT_MODEL': 'modelo-de-prueba',
    'ASSISTANT_PRICE_INPUT_PER_MTOK': '1.00',
    'ASSISTANT_PRICE_OUTPUT_PER_MTOK': '5.00',
    'ASSISTANT_PRICE_TIER_INPUT_LIMIT': 100000,
    'ASSISTANT_MAX_INPUT_TOKENS': 8000,
    'ASSISTANT_MAX_OUTPUT_TOKENS': 1000,
    'ASSISTANT_DAILY_LIMIT_PER_USER': 100,
    'AI_BUDGET_USD': '10',
    'AI_OPERATING_LIMIT_USD': '0.05',  # admite 3 reservas de 0.013
}


@override_settings(**TEST_BUDGET)
class ConfigurationTests(TestCase):
    def test_max_cost_is_rounded_up_from_prices(self):
        self.assertEqual(budget.BudgetConfig.from_settings().max_cost, Decimal('0.013000'))

    def test_fails_closed_without_prices(self):
        for name in ('ASSISTANT_PRICE_INPUT_PER_MTOK', 'ASSISTANT_PRICE_OUTPUT_PER_MTOK'):
            with self.subTest(name=name), override_settings(**{name: None}):
                with self.assertRaises(budget.BudgetNotConfigured):
                    budget.reserve()
        self.assertFalse(AIUsage.objects.exists())

    def test_fails_closed_on_incoherent_configuration(self):
        cases = [
            {'ASSISTANT_PRICE_INPUT_PER_MTOK': '0'},
            {'ASSISTANT_PRICE_OUTPUT_PER_MTOK': 'abc'},
            {'AI_OPERATING_LIMIT_USD': '11'},
            {'ASSISTANT_MAX_INPUT_TOKENS': 200000},
            {'ASSISTANT_MODEL': ''},
            {'ASSISTANT_MAX_OUTPUT_TOKENS': 0},
        ]
        for overrides in cases:
            with self.subTest(overrides=overrides), override_settings(**overrides):
                with self.assertRaises(budget.BudgetNotConfigured):
                    budget.reserve()


@override_settings(**TEST_BUDGET)
class ReservationTests(TestCase):
    def test_reserves_until_operating_limit_then_refuses(self):
        usages = [budget.reserve() for _ in range(3)]
        self.assertTrue(all(u.status == UsageStatus.RESERVED for u in usages))
        with self.assertRaises(budget.BudgetExhausted):
            budget.reserve()
        self.assertEqual(budget.status().committed_usd, Decimal('0.039'))

    def test_reconcile_records_actual_cost_and_frees_the_difference(self):
        usages = [budget.reserve() for _ in range(3)]
        reconciled = budget.reconcile(usages[0], input_tokens=1000, output_tokens=200)
        self.assertEqual(reconciled.status, UsageStatus.RECONCILED)
        self.assertEqual(reconciled.actual_usd, Decimal('0.002'))  # (1000 + 1000) / 1e6
        # 0.039 - 0.013 + 0.002 = 0.028 → cabe otra reserva de 0.013
        budget.reserve()
        with self.assertRaises(budget.BudgetExhausted):
            budget.reserve()

    def test_uncertain_reservation_keeps_counting(self):
        usages = [budget.reserve() for _ in range(3)]
        budget.mark_uncertain(usages[0], note='timeout del proveedor')
        with self.assertRaises(budget.BudgetExhausted):
            budget.reserve()
        self.assertEqual(budget.status().uncertain_count, 1)
        # No se puede liberar dinero posiblemente gastado.
        with self.assertRaises(budget.InvalidTransition):
            budget.release(AIUsage.objects.get(pk=usages[0].pk))

    def test_resolve_uncertain_with_console_amount(self):
        usage = budget.mark_uncertain(budget.reserve())
        resolved = budget.resolve_uncertain(usage, actual_usd=Decimal('0.004'))
        self.assertEqual(resolved.status, UsageStatus.RECONCILED)
        self.assertEqual(budget.status().committed_usd, Decimal('0.004'))

    def test_release_only_when_request_was_never_sent(self):
        usage = budget.reserve()
        released = budget.release(usage, note='fallo antes de enviar')
        self.assertEqual(released.status, UsageStatus.RELEASED)
        self.assertEqual(budget.status().committed_usd, Decimal('0'))
        with self.assertRaises(budget.InvalidTransition):
            budget.reconcile(released, input_tokens=1, output_tokens=1)

    def test_manual_usage_is_discounted(self):
        budget.record_manual(actual_usd=Decimal('0.03'), note='Pruebas en Console')
        budget.reserve()
        with self.assertRaises(budget.BudgetExhausted):
            budget.reserve()

    def test_usage_survives_deletion_of_user_and_consultation(self):
        user = create_account('persona.a@ejemplo.invalid')
        usage = budget.reserve(user=user)
        user.delete()
        usage.refresh_from_db()
        self.assertIsNone(usage.user)
        self.assertEqual(budget.status().committed_usd, Decimal('0.013'))


@override_settings(**{**TEST_BUDGET, 'ASSISTANT_DAILY_LIMIT_PER_USER': 2, 'AI_OPERATING_LIMIT_USD': '1'})
class UserQuotaTests(TestCase):
    def test_daily_limit_per_user(self):
        user_a = create_account('persona.a@ejemplo.invalid')
        user_b = create_account('persona.b@ejemplo.invalid')
        budget.reserve(user=user_a)
        released = budget.reserve(user=user_a)
        budget.release(released)  # lo liberado no cuenta
        budget.reserve(user=user_a)
        with self.assertRaises(budget.UserQuotaExceeded):
            budget.reserve(user=user_a)
        budget.reserve(user=user_b)
        # La evaluación (E18) no consume la cuota de la cuenta.
        budget.reserve(user=user_a, purpose=UsagePurpose.EVALUATION)


@override_settings(**TEST_BUDGET)
class ConcurrencyTests(TransactionTestCase):
    """Reservas simultáneas desde conexiones distintas no superan el límite."""

    def test_parallel_reservations_never_exceed_limit(self):
        attempts = 12
        barrier = threading.Barrier(attempts)
        outcomes = []
        lock = threading.Lock()

        def worker():
            try:
                barrier.wait()
                budget.reserve(note='prueba de concurrencia')
                result = 'ok'
            except budget.BudgetExhausted:
                result = 'exhausted'
            finally:
                connection.close()
            with lock:
                outcomes.append(result)

        threads = [threading.Thread(target=worker) for _ in range(attempts)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(timeout=60)

        self.assertEqual(outcomes.count('ok'), 3)
        self.assertEqual(outcomes.count('exhausted'), attempts - 3)
        self.assertEqual(AIUsage.objects.count(), 3)
        self.assertLessEqual(budget.status().committed_usd, Decimal('0.05'))


@override_settings(**TEST_BUDGET)
class CommandTests(TestCase):
    def test_status_and_manual_record(self):
        out = StringIO()
        call_command('ai_budget', 'record-manual', '--usd', '0.01', '--note', 'Console', stdout=out)
        text = out.getvalue()
        self.assertIn('Conciliado: 0.010000 USD', text)
        self.assertIn('Disponible (operativo): 0.040000 USD', text)
        self.assertIn('contrastar con la Console', text)

    def test_resolve_uncertain_from_command(self):
        usage = budget.mark_uncertain(budget.reserve())
        out = StringIO()
        call_command('ai_budget', 'resolve', '--id', str(usage.pk), '--usd', '0.002', stdout=out)
        self.assertIn(f'Conciliado #{usage.pk}', out.getvalue())
