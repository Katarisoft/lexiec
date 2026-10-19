"""Carga datos de demostración FICTICIOS para probar la app en desarrollo.

No es legislación ni contenido jurídico: todos los textos lo dicen
explícitamente, las URL usan el dominio reservado `ejemplo.invalid` y los
identificadores empiezan por `demo-`. Solo se ejecuta con DEBUG activo.

    python manage.py seed_demo_library          # crea o actualiza
    python manage.py seed_demo_library --clear  # elimina los datos demo
"""

import datetime

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from apps.library.choices import PublicationStatus, ReviewStatus
from apps.library.models import LegalArea, SourceDocument, SourceFragment, TopicCard

DEMO_PREFIX = 'demo-'
DEMO_REVIEWER = 'demo_revisor_ficticio'
DEMO_NOTICE = 'DEMO — contenido ficticio de prueba, no es legislación ni orientación jurídica.'
DEMO_URL = 'https://ejemplo.invalid/demo'

AREAS = [
    ('demo-area-a', 'DEMO Área A (ficticia)', 1),
    ('demo-area-b', 'DEMO Área B (ficticia)', 2),
    ('demo-area-c', 'DEMO Área C (ficticia)', 3),
]
TOPICS_PER_AREA = 3


class Command(BaseCommand):
    help = 'Crea o elimina datos ficticios de demostración (solo con DEBUG=1).'

    def add_arguments(self, parser):
        parser.add_argument('--clear', action='store_true', help='Eliminar los datos demo.')

    def handle(self, *args, **options):
        if not settings.DEBUG:
            raise CommandError('Comando solo para desarrollo: requiere DJANGO_DEBUG=1.')
        with transaction.atomic():
            if options['clear']:
                self._clear()
                self.stdout.write(self.style.SUCCESS('Datos demo eliminados.'))
                return
            counts = self._seed()
        self.stdout.write(self.style.SUCCESS(f'Datos demo listos: {counts}'))

    def _clear(self):
        TopicCard.objects.filter(slug__startswith=DEMO_PREFIX).delete()
        SourceFragment.objects.filter(document__title__startswith='DEMO').delete()
        SourceDocument.objects.filter(title__startswith='DEMO').delete()
        LegalArea.objects.filter(slug__startswith=DEMO_PREFIX).delete()
        get_user_model().objects.filter(username=DEMO_REVIEWER).delete()

    def _seed(self):
        reviewer, created = get_user_model().objects.get_or_create(
            username=DEMO_REVIEWER, defaults={'is_staff': True}
        )
        if created:
            reviewer.set_unusable_password()
            reviewer.save()
        approved = {
            'review_status': ReviewStatus.APPROVED,
            'reviewed_by': reviewer,
            'reviewed_at': timezone.now(),
            'review_notes': DEMO_NOTICE,
        }

        topics = 0
        for slug, name, order in AREAS:
            area, _ = LegalArea.objects.update_or_create(
                slug=slug, defaults={'name': name, 'order': order, 'description': DEMO_NOTICE}
            )
            document, _ = SourceDocument.objects.update_or_create(
                title=f'DEMO Documento ficticio de {name}',
                defaults={
                    'institution': 'DEMO Institución ficticia',
                    'official_url': f'{DEMO_URL}/{slug}',
                    'publication_reference': 'DEMO sin publicación real',
                    'publication_date': datetime.date(2026, 1, 1),
                    'version_label': 'DEMO versión ficticia',
                    'retrieved_at': datetime.date(2026, 10, 19),
                    'publication_status': PublicationStatus.PUBLISHED,
                    'limitations': DEMO_NOTICE,
                    **approved,
                },
            )
            for index in range(1, TOPICS_PER_AREA + 1):
                fragment, _ = SourceFragment.objects.update_or_create(
                    document=document,
                    locator=f'DEMO Art. {index}',
                    defaults={'text': f'{DEMO_NOTICE} Fragmento {index}.', 'order': index, **approved},
                )
                topic, _ = TopicCard.objects.update_or_create(
                    slug=f'{slug}-ficha-{index}',
                    defaults={
                        'area': area,
                        'title': f'DEMO Ficha ficticia {index} de {name}',
                        'summary': f'{DEMO_NOTICE} Explicación de ejemplo número {index}.',
                        'search_terms': ['demo', f'ejemplo{index}'],
                        'publication_status': PublicationStatus.PUBLISHED,
                        **approved,
                    },
                )
                topic.fragments.set([fragment])
                topics += 1
        return {'areas': len(AREAS), 'topics': topics}
