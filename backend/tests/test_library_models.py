"""Pruebas del esquema documental: estados, validaciones y exclusión de borradores."""

from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.test import TestCase

from apps.library.choices import PublicationStatus, ReviewStatus, ValidityStatus
from apps.library.models import SourceDocument, SourceFragment, TopicCard

from .library_factories import (
    TODAY,
    approved,
    make_area,
    make_document,
    make_fragment,
    make_reviewer,
    make_topic,
    published,
)


class DefaultStatesTests(TestCase):
    def test_new_content_starts_pending_draft_and_unverified(self):
        document = make_document()
        fragment = make_fragment(document)
        topic = make_topic(make_area())

        self.assertEqual(document.review_status, ReviewStatus.PENDING)
        self.assertEqual(document.publication_status, PublicationStatus.DRAFT)
        self.assertEqual(document.validity_status, ValidityStatus.NOT_VERIFIED)
        self.assertEqual(fragment.review_status, ReviewStatus.PENDING)
        self.assertEqual(topic.review_status, ReviewStatus.PENDING)
        self.assertEqual(topic.publication_status, PublicationStatus.DRAFT)


class ValidationTests(TestCase):
    def setUp(self):
        self.reviewer = make_reviewer()

    def assert_invalid(self, instance):
        with self.assertRaises(ValidationError):
            instance.full_clean()

    def test_document_cannot_be_published_without_approval(self):
        document = make_document()
        document.publication_status = PublicationStatus.PUBLISHED
        self.assert_invalid(document)

    def test_topic_cannot_be_published_without_approval(self):
        topic = make_topic(make_area())
        topic.publication_status = PublicationStatus.PUBLISHED
        self.assert_invalid(topic)

    def test_approval_requires_reviewer_and_date(self):
        document = make_document()
        document.review_status = ReviewStatus.APPROVED
        self.assert_invalid(document)

        document.reviewed_by = self.reviewer
        self.assert_invalid(document)

    def test_fragment_approval_requires_reviewer_and_date(self):
        fragment = make_fragment(make_document())
        fragment.review_status = ReviewStatus.APPROVED
        self.assert_invalid(fragment)

    def test_verified_validity_requires_date_and_evidence(self):
        document = make_document()
        document.validity_status = ValidityStatus.VERIFIED_CURRENT
        self.assert_invalid(document)

        document.validity_checked_at = TODAY
        document.validity_note = '   '
        self.assert_invalid(document)

        document.validity_note = 'Evidencia ficticia de comprobación.'
        document.full_clean()

    def test_official_url_must_use_https(self):
        document = make_document()
        document.official_url = 'http://ejemplo.invalid/documento-ficticio'
        self.assert_invalid(document)

    def test_approved_and_published_document_is_valid(self):
        document = make_document(**published(self.reviewer))
        document.full_clean()

    def test_locator_is_unique_per_document(self):
        document = make_document()
        make_fragment(document, locator='Art. ficticio 1')
        duplicate = SourceFragment(document=document, locator='Art. ficticio 1', text='Otro.')
        self.assert_invalid(duplicate)

        other_document = make_document(title='Otro documento ficticio')
        make_fragment(other_document, locator='Art. ficticio 1')


class DatabaseConstraintTests(TestCase):
    """Las restricciones se aplican aunque se omita full_clean()."""

    def assert_rejected_by_database(self, create):
        with self.assertRaises(IntegrityError), transaction.atomic():
            create()

    def test_database_rejects_published_document_without_approval(self):
        self.assert_rejected_by_database(
            lambda: make_document(publication_status=PublicationStatus.PUBLISHED)
        )

    def test_database_rejects_published_topic_without_approval(self):
        area = make_area()
        self.assert_rejected_by_database(
            lambda: make_topic(area, publication_status=PublicationStatus.PUBLISHED)
        )

    def test_database_rejects_approval_without_reviewer(self):
        self.assert_rejected_by_database(
            lambda: make_document(review_status=ReviewStatus.APPROVED)
        )

    def test_database_rejects_verified_validity_without_evidence(self):
        self.assert_rejected_by_database(
            lambda: make_document(validity_status=ValidityStatus.VERIFIED_CURRENT)
        )

    def test_database_rejects_duplicate_locator(self):
        document = make_document()
        make_fragment(document, locator='Art. ficticio 1')
        self.assert_rejected_by_database(
            lambda: make_fragment(document, locator='Art. ficticio 1')
        )


class PublicationQuerysetTests(TestCase):
    def setUp(self):
        self.reviewer = make_reviewer()
        self.area = make_area()

    def test_published_topics_exclude_drafts_and_unapproved(self):
        visible = make_topic(self.area, slug='publicada', **published(self.reviewer))
        make_topic(self.area, slug='borrador')
        make_topic(self.area, slug='aprobada-sin-publicar', **approved(self.reviewer))

        self.assertQuerySetEqual(TopicCard.objects.published(), [visible])

    def test_assistant_only_receives_approved_fragments_of_published_documents(self):
        published_doc = make_document(**published(self.reviewer))
        eligible = make_fragment(published_doc, locator='Art. 1', **approved(self.reviewer))
        make_fragment(published_doc, locator='Art. 2')
        make_fragment(
            published_doc,
            locator='Art. 3',
            review_status=ReviewStatus.REJECTED,
        )

        draft_doc = make_document(title='Documento borrador', **approved(self.reviewer))
        make_fragment(draft_doc, locator='Art. 1', **approved(self.reviewer))

        pending_doc = make_document(title='Documento pendiente')
        make_fragment(pending_doc, locator='Art. 1', **approved(self.reviewer))

        self.assertQuerySetEqual(SourceFragment.objects.eligible_for_assistant(), [eligible])

    def test_unpublishing_a_document_removes_its_fragments_from_assistant(self):
        document = make_document(**published(self.reviewer))
        make_fragment(document, **approved(self.reviewer))
        self.assertEqual(SourceFragment.objects.eligible_for_assistant().count(), 1)

        SourceDocument.objects.filter(pk=document.pk).update(
            publication_status=PublicationStatus.DRAFT
        )
        self.assertEqual(SourceFragment.objects.eligible_for_assistant().count(), 0)

    def test_reviewer_cannot_be_deleted_while_referenced(self):
        from django.db.models import ProtectedError

        make_document(**approved(self.reviewer))
        with self.assertRaises(ProtectedError):
            self.reviewer.delete()
