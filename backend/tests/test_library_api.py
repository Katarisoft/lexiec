"""API de biblioteca: áreas, listado filtrado y paginado, detalle con fuentes."""

from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.library.choices import ReviewStatus

from .library_factories import (
    approved,
    make_area,
    make_document,
    make_fragment,
    make_reviewer,
    make_topic,
    published,
)
from .test_accounts import create_account


class LibraryApiTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.client.force_authenticate(create_account('persona.a@ejemplo.invalid'))
        self.reviewer = make_reviewer()
        self.area = make_area(slug='area-uno', name='Área ficticia uno')
        self.other_area = make_area(slug='area-dos', name='Área ficticia dos')

    def published_topic(self, slug, area=None, **overrides):
        return make_topic(area or self.area, slug=slug, **published(self.reviewer), **overrides)

    def error_code(self, response):
        return response.json()['error']['code']


class AuthenticationRequiredTests(TestCase):
    def test_library_endpoints_require_session(self):
        client = APIClient()
        for url in (
            reverse('library:area-list'),
            reverse('library:topic-list'),
            reverse('library:topic-detail', args=[1]),
        ):
            with self.subTest(url=url):
                response = client.get(url)
                self.assertEqual(response.status_code, 401)
                self.assertEqual(response.json()['error']['code'], 'not_authenticated')


class AreaListTests(LibraryApiTestCase):
    def test_lists_areas_with_published_topic_counts(self):
        self.published_topic('publicada')
        make_topic(self.area, slug='borrador')
        make_topic(self.area, slug='aprobada-sin-publicar', **approved(self.reviewer))

        response = self.client.get(reverse('library:area-list'))
        self.assertEqual(response.status_code, 200)
        counts = {item['slug']: item['published_topics'] for item in response.data}
        self.assertEqual(counts, {'area-uno': 1, 'area-dos': 0})


class TopicListTests(LibraryApiTestCase):
    url = reverse('library:topic-list')

    def test_lists_only_published_topics(self):
        visible = self.published_topic('publicada')
        make_topic(self.area, slug='borrador')
        make_topic(self.area, slug='aprobada-sin-publicar', **approved(self.reviewer))

        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['count'], 1)
        item = response.data['results'][0]
        self.assertEqual(item['id'], visible.pk)
        self.assertEqual(item['area'], {'slug': 'area-uno', 'name': 'Área ficticia uno'})

    def test_filters_by_area(self):
        self.published_topic('en-uno')
        self.published_topic('en-dos', area=self.other_area)
        response = self.client.get(self.url, {'area': 'area-dos'})
        self.assertEqual([t['slug'] for t in response.data['results']], ['en-dos'])

    def test_unknown_area_is_422(self):
        response = self.client.get(self.url, {'area': 'area-inexistente'})
        self.assertEqual(response.status_code, 422)
        self.assertEqual(self.error_code(response), 'unknown_area')

    def test_malformed_parameters_are_400(self):
        for params in ({'area': 'no válida'}, {'search': 'x' * 101}, {'page': '0'}, {'page': 'abc'}):
            with self.subTest(params=params):
                response = self.client.get(self.url, params)
                self.assertEqual(response.status_code, 400)
                self.assertEqual(self.error_code(response), 'validation_error')

    def test_search_matches_title_summary_and_terms_case_insensitively(self):
        self.published_topic('por-titulo', title='Ficha ficticia sobre plazos')
        self.published_topic('por-resumen', summary='Explicación ficticia sobre PLAZOS.')
        self.published_topic('por-termino', search_terms=['plazos', 'tiempo'])
        self.published_topic('sin-relacion', title='Otra ficha ficticia')
        make_topic(self.area, slug='borrador-con-plazos', title='Plazos en borrador')

        response = self.client.get(self.url, {'search': 'Plazos'})
        self.assertEqual(
            sorted(t['slug'] for t in response.data['results']),
            ['por-resumen', 'por-termino', 'por-titulo'],
        )

    def test_paginates_twenty_per_page(self):
        for index in range(25):
            self.published_topic(f'ficha-{index:02d}', title=f'Ficha ficticia {index:02d}')

        first = self.client.get(self.url)
        self.assertEqual(first.data['count'], 25)
        self.assertEqual(len(first.data['results']), 20)
        self.assertIsNotNone(first.data['next'])

        second = self.client.get(self.url, {'page': 2})
        self.assertEqual(len(second.data['results']), 5)
        self.assertIsNone(second.data['next'])

        beyond = self.client.get(self.url, {'page': 3})
        self.assertEqual(beyond.status_code, 404)
        self.assertEqual(self.error_code(beyond), 'not_found')


class TopicDetailTests(LibraryApiTestCase):
    def detail(self, topic_id):
        return self.client.get(reverse('library:topic-detail', args=[topic_id]))

    def test_detail_includes_only_published_sources_with_metadata(self):
        document = make_document(limitations='Limitación ficticia.', **published(self.reviewer))
        visible = make_fragment(document, locator='Art. 1', **approved(self.reviewer))
        pending = make_fragment(document, locator='Art. 2')
        draft_document = make_document(title='Documento borrador', **approved(self.reviewer))
        from_draft = make_fragment(draft_document, locator='Art. 1', **approved(self.reviewer))

        topic = self.published_topic('con-fuentes')
        topic.fragments.add(visible, pending, from_draft)

        response = self.detail(topic.pk)
        self.assertEqual(response.status_code, 200)
        self.assertEqual([s['id'] for s in response.data['sources']], [visible.pk])

        source = response.data['sources'][0]
        self.assertEqual(source['locator'], 'Art. 1')
        doc = source['document']
        self.assertEqual(doc['official_url'], 'https://ejemplo.invalid/documento-ficticio')
        self.assertEqual(doc['validity_status'], 'not_verified')
        self.assertEqual(doc['validity_status_label'], 'Vigencia no comprobada')
        self.assertEqual(doc['limitations'], 'Limitación ficticia.')
        self.assertIsNotNone(doc['reviewed_at'])

    def test_detail_never_exposes_reviewer_identity(self):
        topic = self.published_topic('privada')
        content = self.detail(topic.pk).content.decode()
        self.assertNotIn('reviewed_by', content)
        self.assertNotIn(self.reviewer.username, content)

    def test_unpublished_or_missing_topic_is_404(self):
        draft = make_topic(self.area, slug='borrador')
        rejected = make_topic(self.area, slug='rechazada', review_status=ReviewStatus.REJECTED)
        for topic_id in (draft.pk, rejected.pk, 999999):
            with self.subTest(topic_id=topic_id):
                response = self.detail(topic_id)
                self.assertEqual(response.status_code, 404)
                self.assertEqual(self.error_code(response), 'not_found')
