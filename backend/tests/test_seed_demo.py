"""Comando de datos ficticios de demostración (solo desarrollo)."""

from io import StringIO

from django.contrib.auth import get_user_model
from django.core.management import CommandError, call_command
from django.test import TestCase, override_settings

from apps.library.models import LegalArea, SourceDocument, SourceFragment, TopicCard

from .library_factories import make_area, make_document, make_topic


def run(*args):
    call_command('seed_demo_library', *args, stdout=StringIO())


class SeedDemoLibraryTests(TestCase):
    def test_refuses_to_run_without_debug(self):
        with self.assertRaises(CommandError):
            run()
        self.assertFalse(TopicCard.objects.exists())

    @override_settings(DEBUG=True)
    def test_creates_clearly_fictitious_published_content_idempotently(self):
        run()
        run()
        self.assertEqual(LegalArea.objects.count(), 3)
        self.assertEqual(TopicCard.objects.published().count(), 9)
        self.assertEqual(SourceFragment.objects.published().count(), 9)

        for topic in TopicCard.objects.all():
            self.assertTrue(topic.slug.startswith('demo-'))
            self.assertIn('DEMO', topic.title)
            self.assertIn('ficticio', topic.summary)
        for document in SourceDocument.objects.all():
            self.assertIn('ejemplo.invalid', document.official_url)
            self.assertIn('no es legislación', document.limitations)

        reviewer = get_user_model().objects.get(username='demo_revisor_ficticio')
        self.assertFalse(reviewer.has_usable_password())

    @override_settings(DEBUG=True)
    def test_clear_removes_only_demo_data(self):
        real_area = make_area(slug='area-real', name='Área no demo')
        real_document = make_document(title='Documento no demo')
        real_topic = make_topic(real_area, slug='ficha-no-demo')

        run()
        run('--clear')

        self.assertEqual(list(LegalArea.objects.all()), [real_area])
        self.assertEqual(list(SourceDocument.objects.all()), [real_document])
        self.assertEqual(list(TopicCard.objects.all()), [real_topic])
        self.assertFalse(
            get_user_model().objects.filter(username='demo_revisor_ficticio').exists()
        )
