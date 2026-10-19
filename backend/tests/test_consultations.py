"""Historial privado de consultas y servicio de registro (sin llamadas a IA)."""

import uuid

from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.assistant.models import Consultation, ConsultationCitation, ConsultationStatus
from apps.assistant.services import (
    AnswerResult,
    ConsultationError,
    IdempotencyConflict,
    record_consultation,
)
from apps.library.models import SourceFragment

from .library_factories import (
    approved,
    make_area,
    make_document,
    make_fragment,
    make_reviewer,
    published,
)
from .test_accounts import create_account


class ConsultationTestCase(TestCase):
    def setUp(self):
        self.user_a = create_account('persona.a@ejemplo.invalid')
        self.user_b = create_account('persona.b@ejemplo.invalid')
        self.area = make_area()
        reviewer = make_reviewer()
        document = make_document(**published(reviewer))
        self.fragment = make_fragment(document, locator='Art. 1', **approved(reviewer))
        self.other_fragment = make_fragment(document, locator='Art. 2', **approved(reviewer))
        self.pending_fragment = make_fragment(document, locator='Art. 3')

    def record(self, user, question='¿Pregunta ficticia?', result=None, request_id=None, sent=None):
        return record_consultation(
            user=user,
            area=self.area,
            question=question,
            client_request_id=request_id or uuid.uuid4(),
            result=result
            or AnswerResult(
                status=ConsultationStatus.ANSWERED,
                answer='Respuesta ficticia respaldada.',
                cited_fragment_ids=[self.fragment.pk],
            ),
            sent_fragments=sent if sent is not None else [self.fragment, self.other_fragment],
        )

    def client_for(self, user):
        client = APIClient()
        client.force_authenticate(user)
        return client


class RecordConsultationTests(ConsultationTestCase):
    def test_answered_consultation_stores_citation_snapshot(self):
        consultation = self.record(self.user_a)
        citation = consultation.citations.get()
        self.assertEqual(citation.fragment, self.fragment)
        self.assertEqual(citation.quoted_text, self.fragment.text)
        self.assertEqual(citation.locator, 'Art. 1')
        self.assertEqual(citation.document_title, self.fragment.document.title)

    def test_answer_without_citations_is_rejected(self):
        with self.assertRaises(ConsultationError) as ctx:
            self.record(
                self.user_a,
                result=AnswerResult(status=ConsultationStatus.ANSWERED, answer='Sin citas.'),
            )
        self.assertEqual(ctx.exception.code, 'answer_without_citations')
        self.assertFalse(Consultation.objects.exists())

    def test_citation_not_sent_to_provider_is_rejected(self):
        with self.assertRaises(ConsultationError) as ctx:
            self.record(self.user_a, sent=[self.other_fragment])
        self.assertEqual(ctx.exception.code, 'unknown_citation')

    def test_citation_of_unreviewed_fragment_is_rejected(self):
        with self.assertRaises(ConsultationError) as ctx:
            self.record(
                self.user_a,
                result=AnswerResult(
                    status=ConsultationStatus.ANSWERED,
                    answer='Respuesta.',
                    cited_fragment_ids=[self.pending_fragment.pk],
                ),
                sent=[self.pending_fragment],
            )
        self.assertEqual(ctx.exception.code, 'ineligible_citation')

    def test_no_support_and_error_are_stored_without_inventing_answers(self):
        no_support = self.record(
            self.user_a, result=AnswerResult(status=ConsultationStatus.NO_SUPPORT)
        )
        self.assertEqual(no_support.answer, '')
        self.assertFalse(no_support.citations.exists())

        error = self.record(
            self.user_a,
            result=AnswerResult(
                status=ConsultationStatus.ERROR,
                answer='texto del proveedor que no debe guardarse',
                error_code='provider_timeout',
            ),
        )
        self.assertEqual(error.answer, '')
        self.assertEqual(error.error_code, 'provider_timeout')

    def test_citations_only_allowed_on_answered(self):
        with self.assertRaises(ConsultationError):
            self.record(
                self.user_a,
                result=AnswerResult(
                    status=ConsultationStatus.NO_SUPPORT,
                    cited_fragment_ids=[self.fragment.pk],
                ),
            )

    def test_question_is_validated(self):
        for question in ('   ', 'x' * 1001):
            with self.subTest(length=len(question)), self.assertRaises(ConsultationError):
                self.record(self.user_a, question=question)

    def test_same_request_id_is_idempotent(self):
        request_id = uuid.uuid4()
        first = self.record(self.user_a, request_id=request_id)
        second = self.record(self.user_a, request_id=request_id)
        self.assertEqual(first.pk, second.pk)
        self.assertEqual(Consultation.objects.count(), 1)

    def test_reusing_request_id_with_other_question_is_rejected(self):
        request_id = uuid.uuid4()
        self.record(self.user_a, request_id=request_id)
        with self.assertRaises(IdempotencyConflict):
            self.record(self.user_a, question='¿Otra pregunta?', request_id=request_id)

    def test_request_id_is_scoped_per_user(self):
        request_id = uuid.uuid4()
        self.record(self.user_a, request_id=request_id)
        self.record(self.user_b, request_id=request_id)
        self.assertEqual(Consultation.objects.count(), 2)

    def test_citation_survives_fragment_deletion_as_snapshot(self):
        consultation = self.record(self.user_a)
        SourceFragment.objects.filter(pk=self.fragment.pk).delete()
        citation = consultation.citations.get()
        self.assertIsNone(citation.fragment)
        self.assertEqual(citation.locator, 'Art. 1')


class ConsultationApiTests(ConsultationTestCase):
    list_url = reverse('assistant:consultation-list')

    def detail_url(self, consultation):
        return reverse('assistant:consultation-detail', args=[consultation.pk])

    def test_requires_authentication(self):
        consultation = self.record(self.user_a)
        anonymous = APIClient()
        self.assertEqual(anonymous.get(self.list_url).status_code, 401)
        self.assertEqual(anonymous.get(self.detail_url(consultation)).status_code, 401)
        self.assertEqual(anonymous.delete(self.detail_url(consultation)).status_code, 401)

    def test_lists_only_own_consultations_newest_first(self):
        first = self.record(self.user_a, question='¿Primera?')
        second = self.record(self.user_a, question='¿Segunda?')
        self.record(self.user_b, question='¿De B?')

        response = self.client_for(self.user_a).get(self.list_url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual([c['id'] for c in response.data['results']], [second.pk, first.pk])
        self.assertNotIn('¿De B?', response.content.decode())

    def test_detail_includes_answer_and_citations(self):
        consultation = self.record(self.user_a)
        response = self.client_for(self.user_a).get(self.detail_url(consultation))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], 'answered')
        self.assertEqual(response.data['status_label'], 'Respondida con respaldo')
        self.assertEqual(response.data['citations'][0]['locator'], 'Art. 1')

    def test_b_cannot_open_or_delete_consultation_of_a_with_known_id(self):
        consultation = self.record(self.user_a)
        client_b = self.client_for(self.user_b)

        detail = client_b.get(self.detail_url(consultation))
        self.assertEqual(detail.status_code, 404)
        self.assertEqual(detail.json()['error']['code'], 'not_found')

        delete = client_b.delete(self.detail_url(consultation))
        self.assertEqual(delete.status_code, 404)
        self.assertTrue(Consultation.objects.filter(pk=consultation.pk).exists())

    def test_owner_delete_removes_question_answer_and_citations(self):
        consultation = self.record(self.user_a)
        response = self.client_for(self.user_a).delete(self.detail_url(consultation))
        self.assertEqual(response.status_code, 204)
        self.assertFalse(Consultation.objects.filter(pk=consultation.pk).exists())
        self.assertFalse(ConsultationCitation.objects.exists())
        # Los fragmentos citados no se borran.
        self.assertTrue(SourceFragment.objects.filter(pk=self.fragment.pk).exists())

    def test_creation_and_edition_are_not_exposed_yet(self):
        client = self.client_for(self.user_a)
        consultation = self.record(self.user_a)
        self.assertEqual(client.post(self.list_url, {}, format='json').status_code, 405)
        self.assertEqual(
            client.patch(self.detail_url(consultation), {}, format='json').status_code, 405
        )
