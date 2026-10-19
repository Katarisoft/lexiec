"""Recuperación de fragmentos sin proveedor de IA.

Todos los textos son ficticios y absurdos a propósito: no representan
legislación. Sirven para comprobar filtros, búsqueda y abstención.
"""

from django.test import TestCase, override_settings

from apps.assistant.retrieval import keywords, retrieve
from apps.community.models import Comment

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


class RetrievalTestCase(TestCase):
    def setUp(self):
        reviewer = make_reviewer()
        self.ok = approved(reviewer)
        self.pub = published(reviewer)
        self.area_a = make_area(slug='area-a', name='Área ficticia A')
        self.area_b = make_area(slug='area-b', name='Área ficticia B')
        self.document = make_document(**self.pub)

        self.pesca = self.fragment(
            'Art. 1',
            'Texto ficticio: la renovación del permiso de pesca lunar se solicita '
            'con treinta días de anticipación.',
            topic=('pesca-lunar', self.area_a, ['permiso', 'pesca']),
        )
        self.faro = self.fragment(
            'Art. 2',
            'Texto ficticio: los guardianes del faro disfrutan de un período de '
            'vacaciones anuales.',
            topic=('faro', self.area_a, ['vacaciones', 'faro']),
        )
        self.dragones = self.fragment(
            'Art. 3',
            'Texto ficticio: la pensión de los dragones jubilados se calcula según '
            'sus años de servicio.',
            topic=('dragones', self.area_a, ['retiro']),
        )
        self.pesca_b = self.fragment(
            'Art. 4',
            'Texto ficticio del área B sobre el permiso de pesca lunar.',
            topic=('pesca-b', self.area_b, []),
        )

    def fragment(self, locator, text, topic, fragment_review=True, topic_published=True):
        fragment = make_fragment(
            self.document, locator=locator, text=text, **(self.ok if fragment_review else {})
        )
        slug, area, terms = topic
        card = make_topic(
            area, slug=slug, search_terms=terms, **(self.pub if topic_published else {})
        )
        card.fragments.add(fragment)
        return fragment

    def ids(self, result):
        return [f.id for f in result.fragments]


class RelevanceTests(RetrievalTestCase):
    def test_finds_relevant_fragment_ignoring_accents_and_case(self):
        result = retrieve('¿Cómo se calcula la PENSION de un dragón jubilado?', self.area_a)
        self.assertTrue(result.sufficient)
        self.assertEqual(self.ids(result)[0], self.dragones.pk)

    def test_spanish_stemming_matches_plural_and_singular(self):
        result = retrieve('vacación del guardián del faro', self.area_a)
        self.assertTrue(result.sufficient)
        self.assertEqual(self.ids(result)[0], self.faro.pk)

    def test_controlled_terms_help_when_text_differs(self):
        result = retrieve('retiro de dragones', self.area_a)
        self.assertTrue(result.sufficient)
        self.assertEqual(self.ids(result)[0], self.dragones.pk)

    def test_result_exposes_ids_document_and_locator(self):
        fragment = retrieve('renovar permiso de pesca lunar', self.area_a).fragments[0]
        self.assertEqual(fragment.id, self.pesca.pk)
        self.assertEqual(fragment.locator, 'Art. 1')
        self.assertEqual(fragment.document_title, self.document.title)
        self.assertTrue(fragment.document_url.startswith('https://'))


class FilterTests(RetrievalTestCase):
    def test_area_filter_is_mandatory_and_isolates_areas(self):
        with self.assertRaises(ValueError):
            retrieve('pesca lunar', None)
        self.assertEqual(self.ids(retrieve('permiso de pesca lunar', self.area_a)), [self.pesca.pk])
        self.assertEqual(self.ids(retrieve('permiso de pesca lunar', self.area_b)), [self.pesca_b.pk])

    def test_unreviewed_fragments_and_unpublished_topics_are_excluded(self):
        pending = self.fragment(
            'Art. 5',
            'Texto ficticio pendiente sobre unicornios marinos.',
            topic=('unicornios', self.area_a, ['unicornios']),
            fragment_review=False,
        )
        hidden = self.fragment(
            'Art. 6',
            'Texto ficticio sobre sirenas cantoras.',
            topic=('sirenas', self.area_a, ['sirenas']),
            topic_published=False,
        )
        self.assertFalse(retrieve('unicornios marinos', self.area_a).sufficient)
        self.assertFalse(retrieve('sirenas cantoras', self.area_a).sufficient)
        all_ids = self.ids(retrieve('texto ficticio', self.area_a))
        self.assertNotIn(pending.pk, all_ids)
        self.assertNotIn(hidden.pk, all_ids)

    def test_comments_are_never_evidence(self):
        user = create_account('persona.a@ejemplo.invalid')
        Comment.objects.create(
            topic=self.faro.topics.get(),
            author=user,
            text='Comentario sobre astronautas y cohetes espaciales.',
        )
        self.assertFalse(retrieve('astronautas cohetes espaciales', self.area_a).sufficient)


class AbstentionTests(RetrievalTestCase):
    def test_question_outside_collection_abstains(self):
        result = retrieve('¿Cuál es el horario de los trenes a Marte?', self.area_a)
        self.assertFalse(result.sufficient)
        self.assertEqual(result.fragments, [])

    def test_single_shared_word_in_unrelated_question_abstains(self):
        result = retrieve(
            '¿Qué impuesto paga una empresa minera por exportar diamantes en servicio?',
            self.area_a,
        )
        self.assertFalse(result.sufficient)
        self.assertEqual(result.reason, 'low_coverage')
        self.assertLess(result.best_coverage, 0.5)

    def test_question_without_keywords_abstains(self):
        result = retrieve('¿Qué? ¿Y yo?', self.area_a)
        self.assertFalse(result.sufficient)
        self.assertEqual(result.reason, 'empty_query')

    @override_settings(ASSISTANT_MIN_COVERAGE=0.1)
    def test_coverage_threshold_is_configurable(self):
        result = retrieve(
            '¿Qué impuesto paga una empresa minera por exportar diamantes en servicio?',
            self.area_a,
        )
        self.assertTrue(result.sufficient)


class BoundedContextTests(RetrievalTestCase):
    def test_limits_number_of_fragments_and_characters(self):
        self.assertEqual(len(retrieve('texto ficticio', self.area_a, max_fragments=1).fragments), 1)
        result = retrieve('texto ficticio', self.area_a, max_chars=150)
        self.assertLessEqual(sum(len(f.text) for f in result.fragments), 150)
        self.assertGreaterEqual(len(result.fragments), 1)


class KeywordTests(TestCase):
    def test_keywords_normalize_and_drop_stopwords(self):
        self.assertEqual(keywords('¿Cuánto me pagan por las VACACIONES?'), ['pagan', 'vacaciones'])
        self.assertEqual(keywords('Pensión, pensión y más pensión'), ['pension'])
