"""Datos de prueba claramente ficticios para la biblioteca.

No representan legislación real; solo sirven para ejercitar el esquema.
"""

import datetime

from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.library.choices import PublicationStatus, ReviewStatus
from apps.library.models import LegalArea, SourceDocument, SourceFragment, TopicCard

TODAY = datetime.date(2026, 10, 16)


def make_reviewer(username='revisora_prueba'):
    return get_user_model().objects.create_user(
        username=username, password='clave-de-prueba-123', is_staff=True
    )


def make_area(slug='area-ficticia', name='Área ficticia de prueba'):
    return LegalArea.objects.create(slug=slug, name=name)


def make_document(**overrides):
    values = {
        'institution': 'Institución ficticia de prueba',
        'title': 'Documento ficticio de prueba',
        'official_url': 'https://ejemplo.invalid/documento-ficticio',
        'version_label': 'Versión ficticia 1',
        'retrieved_at': TODAY,
    }
    values.update(overrides)
    return SourceDocument.objects.create(**values)


def make_fragment(document, locator='Art. ficticio 1', **overrides):
    values = {'document': document, 'locator': locator, 'text': 'Texto ficticio de prueba.'}
    values.update(overrides)
    return SourceFragment.objects.create(**values)


def make_topic(area, slug='ficha-ficticia', **overrides):
    values = {
        'area': area,
        'slug': slug,
        'title': 'Ficha ficticia de prueba',
        'summary': 'Explicación ficticia de prueba.',
    }
    values.update(overrides)
    return TopicCard.objects.create(**values)


def approved(reviewer):
    """Campos de una revisión aprobada atribuida a `reviewer`."""
    return {
        'review_status': ReviewStatus.APPROVED,
        'reviewed_by': reviewer,
        'reviewed_at': timezone.now(),
    }


def published(reviewer):
    return {**approved(reviewer), 'publication_status': PublicationStatus.PUBLISHED}
