"""Consulta y conciliación manual del presupuesto de IA.

    python manage.py ai_budget status
    python manage.py ai_budget record-manual --usd 0.12 --note "Pruebas en Console"
    python manage.py ai_budget resolve --id 15 --usd 0.004 --note "Visto en Console"

No llama a ningún proveedor.
"""

from decimal import Decimal, InvalidOperation

from django.core.management.base import BaseCommand, CommandError

from apps.assistant import budget
from apps.assistant.models import AIUsage, UsageStatus


def usd(value):
    try:
        return Decimal(value)
    except InvalidOperation as error:
        raise CommandError('Importe en USD no válido.') from error


class Command(BaseCommand):
    help = 'Estado y conciliación manual del presupuesto de IA (sin llamadas al proveedor).'

    def add_arguments(self, parser):
        sub = parser.add_subparsers(dest='action', required=True)
        sub.add_parser('status', help='Muestra consumo, reservas y saldo operativo.')
        manual = sub.add_parser('record-manual', help='Descuenta consumo hecho fuera de la app.')
        manual.add_argument('--usd', required=True, type=usd)
        manual.add_argument('--note', default='')
        resolve = sub.add_parser('resolve', help='Concilia una reserva incierta.')
        resolve.add_argument('--id', required=True, type=int)
        resolve.add_argument('--usd', required=True, type=usd)
        resolve.add_argument('--note', default='')

    def handle(self, *args, **options):
        try:
            if options['action'] == 'record-manual':
                usage = budget.record_manual(actual_usd=options['usd'], note=options['note'])
                self.stdout.write(f'Registrado consumo manual #{usage.pk}: {usage.actual_usd} USD')
            elif options['action'] == 'resolve':
                usage = AIUsage.objects.get(pk=options['id'])
                usage = budget.resolve_uncertain(
                    usage, actual_usd=options['usd'], note=options['note']
                )
                self.stdout.write(f'Conciliado #{usage.pk}: {usage.actual_usd} USD')
            self._print_status()
        except AIUsage.DoesNotExist as error:
            raise CommandError('No existe ese registro de consumo.') from error
        except budget.BudgetError as error:
            raise CommandError(f'{error.code}: {error}') from error

    def _print_status(self):
        current = budget.status()
        config = budget.BudgetConfig.from_settings()
        lines = [
            f'Modelo: {config.model}',
            f'Presupuesto global: {current.budget_usd} USD',
            f'Límite operativo: {current.operating_limit_usd} USD',
            f'Conciliado: {current.reconciled_usd} USD',
            f'Reservado o incierto: {current.pending_usd} USD',
            f'Comprometido: {current.committed_usd} USD',
            f'Disponible (operativo): {current.available_usd} USD',
            f'Reservas inciertas pendientes: {current.uncertain_count}',
            f'Coste máximo por consulta: {config.max_cost} USD',
            'Aviso: estimación interna; contrastar con la Console de Anthropic.',
        ]
        uncertain = AIUsage.objects.filter(status=UsageStatus.UNCERTAIN).values_list('pk', flat=True)
        if uncertain:
            lines.append(f'Ids inciertos: {", ".join(map(str, uncertain))}')
        self.stdout.write('\n'.join(lines))
