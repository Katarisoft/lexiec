"""Pruebas de creación de contenido documental desde Django Admin."""

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse

from apps.library.choices import PublicationStatus, ReviewStatus, ValidityStatus
from apps.library.models import LegalArea, SourceDocument, SourceFragment, TopicCard

from .library_factories import make_area, make_document, make_fragment

DOCUMENT_FORM = {
    'institution': 'Institución ficticia de prueba',
    'title': 'Documento ficticio desde Admin',
    'official_url': 'https://ejemplo.invalid/admin',
    'publication_reference': '',
    'publication_date': '',
    'version_label': 'Versión ficticia 1',
    'retrieved_at': '2026-10-16',
    'text_hash': '',
    'review_status': ReviewStatus.PENDING,
    'reviewed_by': '',
    'reviewed_at_0': '',
    'reviewed_at_1': '',
    'review_notes': '',
    'publication_status': PublicationStatus.DRAFT,
    'validity_status': ValidityStatus.NOT_VERIFIED,
    'validity_checked_at': '',
    'validity_note': '',
    'limitations': 'Texto ficticio no consolidado.',
    # Formulario de fragmentos en línea vacío.
    'fragments-TOTAL_FORMS': '0',
    'fragments-INITIAL_FORMS': '0',
    'fragments-MIN_NUM_FORMS': '0',
    'fragments-MAX_NUM_FORMS': '1000',
}


class LibraryAdminTests(TestCase):
    def setUp(self):
        self.admin_user = get_user_model().objects.create_superuser(
            username='admin_prueba', password='clave-de-prueba-123'
        )
        self.client.force_login(self.admin_user)

    def add_url(self, model):
        return reverse(f'admin:library_{model._meta.model_name}_add')

    def test_add_pages_load(self):
        for model in (LegalArea, SourceDocument, SourceFragment, TopicCard):
            with self.subTest(model=model.__name__):
                response = self.client.get(self.add_url(model))
                self.assertEqual(response.status_code, 200)

    def test_create_area_from_admin(self):
        response = self.client.post(
            self.add_url(LegalArea),
            {'slug': 'area-admin', 'name': 'Área ficticia desde Admin', 'description': '', 'order': 1},
        )
        self.assertEqual(response.status_code, 302)
        self.assertTrue(LegalArea.objects.filter(slug='area-admin').exists())

    def test_create_document_with_inline_fragment_from_admin(self):
        data = {
            **DOCUMENT_FORM,
            'fragments-TOTAL_FORMS': '1',
            'fragments-0-locator': 'Art. ficticio 1',
            'fragments-0-order': '1',
            'fragments-0-text': 'Texto ficticio de prueba.',
            'fragments-0-review_status': ReviewStatus.PENDING,
            'fragments-0-reviewed_by': '',
            'fragments-0-reviewed_at_0': '',
            'fragments-0-reviewed_at_1': '',
        }
        response = self.client.post(self.add_url(SourceDocument), data)
        self.assertEqual(response.status_code, 302)

        document = SourceDocument.objects.get(title='Documento ficticio desde Admin')
        self.assertEqual(document.publication_status, PublicationStatus.DRAFT)
        self.assertEqual(document.fragments.get().locator, 'Art. ficticio 1')

    def test_admin_rejects_publishing_unapproved_document(self):
        data = {**DOCUMENT_FORM, 'publication_status': PublicationStatus.PUBLISHED}
        response = self.client.post(self.add_url(SourceDocument), data)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'No se puede publicar un documento sin revisión aprobada.')
        self.assertFalse(SourceDocument.objects.exists())

    def test_create_fragment_from_admin(self):
        document = make_document()
        response = self.client.post(
            self.add_url(SourceFragment),
            {
                'document': document.pk,
                'locator': 'Art. ficticio 2',
                'order': '2',
                'text': 'Texto ficticio de prueba.',
                'review_status': ReviewStatus.PENDING,
                'reviewed_by': '',
                'reviewed_at_0': '',
                'reviewed_at_1': '',
                'review_notes': '',
            },
        )
        self.assertEqual(response.status_code, 302)
        self.assertTrue(document.fragments.filter(locator='Art. ficticio 2').exists())

    def test_create_topic_with_fragments_from_admin(self):
        area = make_area()
        fragment = make_fragment(make_document())
        response = self.client.post(
            self.add_url(TopicCard),
            {
                'area': area.pk,
                'title': 'Ficha ficticia desde Admin',
                'slug': 'ficha-admin',
                'summary': 'Explicación ficticia.',
                'search_terms': 'término uno, término dos',
                'fragments': [fragment.pk],
                'review_status': ReviewStatus.PENDING,
                'reviewed_by': '',
                'reviewed_at_0': '',
                'reviewed_at_1': '',
                'review_notes': '',
                'publication_status': PublicationStatus.DRAFT,
            },
        )
        self.assertEqual(response.status_code, 302)

        topic = TopicCard.objects.get(slug='ficha-admin')
        self.assertEqual(topic.search_terms, ['término uno', 'término dos'])
        self.assertEqual(list(topic.fragments.all()), [fragment])

    def test_document_list_shows_review_publication_and_validity(self):
        make_document(limitations='Limitación ficticia.')
        response = self.client.get(reverse('admin:library_sourcedocument_changelist'))
        self.assertContains(response, 'Pendiente de revisión')
        self.assertContains(response, 'Borrador')
        self.assertContains(response, 'Vigencia no comprobada')

    def test_reviewer_choices_are_limited_to_staff(self):
        get_user_model().objects.create_user(username='ciudadano_prueba', password='x-prueba-123')
        response = self.client.get(self.add_url(SourceDocument))
        reviewers = response.context['adminform'].form.fields['reviewed_by'].queryset
        self.assertIn(self.admin_user, reviewers)
        self.assertFalse(reviewers.filter(username='ciudadano_prueba').exists())

    def test_admin_requires_staff_login(self):
        self.client.logout()
        response = self.client.get(self.add_url(SourceDocument))
        self.assertEqual(response.status_code, 302)
        self.assertIn(reverse('admin:login'), response['Location'])
