"""Comentarios públicos: CRUD protegido, permisos por objeto y usuarios A/B."""

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.models import Profile
from apps.community.models import Comment
from apps.library.choices import PublicationStatus

from .library_factories import make_area, make_reviewer, make_topic, published
from .test_accounts import create_account


class CommunityTestCase(TestCase):
    def setUp(self):
        self.user_a = create_account('persona.a@ejemplo.invalid')
        self.user_b = create_account('persona.b@ejemplo.invalid')
        Profile.objects.create(user=self.user_a, display_name='Ana')
        self.client_a = self.client_for(self.user_a)
        self.client_b = self.client_for(self.user_b)

        self.reviewer = make_reviewer()
        self.area = make_area()
        self.topic = make_topic(self.area, slug='publicada', **published(self.reviewer))
        self.draft = make_topic(self.area, slug='borrador')

    def client_for(self, user):
        client = APIClient()
        client.force_authenticate(user)
        return client

    def list_url(self, topic=None):
        return reverse('community:topic-comments', args=[(topic or self.topic).pk])

    def detail_url(self, comment):
        return reverse('community:comment-detail', args=[comment.pk])

    def post_comment(self, client, text='Comentario ficticio de prueba.', topic=None, **extra):
        return client.post(self.list_url(topic), {'text': text, **extra}, format='json')

    def error_code(self, response):
        return response.json()['error']['code']


class CreateAndReadTests(CommunityTestCase):
    def test_b_sees_comment_published_by_a(self):
        created = self.post_comment(self.client_a)
        self.assertEqual(created.status_code, 201, created.content)
        self.assertTrue(created.data['is_mine'])
        self.assertEqual(created.data['author'], {'display_name': 'Ana'})
        self.assertFalse(created.data['edited'])

        listed = self.client_b.get(self.list_url())
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.data['count'], 1)
        item = listed.data['results'][0]
        self.assertEqual(item['text'], 'Comentario ficticio de prueba.')
        self.assertFalse(item['is_mine'])
        self.assertEqual(item['author'], {'display_name': 'Ana'})

    def test_author_without_alias_is_shown_generically_and_email_never_leaks(self):
        self.post_comment(self.client_b)
        response = self.client_a.get(self.list_url())
        self.assertEqual(
            response.data['results'][0]['author'], {'display_name': f'Usuario {self.user_b.pk}'}
        )
        content = response.content.decode()
        self.assertNotIn('persona.b@ejemplo.invalid', content)
        self.assertNotIn('persona.a@ejemplo.invalid', content)

    def test_server_assigns_author_and_topic_ignoring_forged_fields(self):
        other_topic = make_topic(self.area, slug='otra-publicada', **published(self.reviewer))
        forged = {
            'text': 'Comentario ficticio de prueba.',
            'author': self.user_a.pk,
            'author_id': self.user_a.pk,
            'topic': other_topic.pk,
            'topic_id': other_topic.pk,
        }
        response = self.client_b.post(self.list_url(), forged, format='json')
        self.assertEqual(response.status_code, 201)
        comment = Comment.objects.get(pk=response.data['id'])
        self.assertEqual(comment.author, self.user_b)
        self.assertEqual(comment.topic, self.topic)

    def test_text_is_trimmed_and_validated(self):
        ok = self.post_comment(self.client_a, text='  Texto con espacios.  ')
        self.assertEqual(ok.data['text'], 'Texto con espacios.')

        for text in ('', '    ', 'x' * 1001):
            with self.subTest(length=len(text)):
                response = self.post_comment(self.client_a, text=text)
                self.assertEqual(response.status_code, 400)
                self.assertEqual(self.error_code(response), 'validation_error')
        self.assertEqual(Comment.objects.count(), 1)

    def test_accepts_exactly_max_length(self):
        self.assertEqual(self.post_comment(self.client_a, text='x' * 1000).status_code, 201)

    def test_newest_first_and_paginated(self):
        for index in range(23):
            Comment.objects.create(topic=self.topic, author=self.user_a, text=f'Comentario {index}')
        first = self.client_b.get(self.list_url())
        self.assertEqual(first.data['count'], 23)
        self.assertEqual(len(first.data['results']), 20)
        self.assertEqual(first.data['results'][0]['text'], 'Comentario 22')
        second = self.client_b.get(self.list_url(), {'page': 2})
        self.assertEqual(len(second.data['results']), 3)

    def test_comments_are_scoped_to_their_topic(self):
        other_topic = make_topic(self.area, slug='otra-publicada', **published(self.reviewer))
        self.post_comment(self.client_a, topic=other_topic)
        self.assertEqual(self.client_b.get(self.list_url()).data['count'], 0)


class AuthenticationTests(CommunityTestCase):
    def test_all_actions_require_session(self):
        comment = Comment.objects.create(topic=self.topic, author=self.user_a, text='Texto.')
        anonymous = APIClient()
        responses = [
            anonymous.get(self.list_url()),
            anonymous.post(self.list_url(), {'text': 'Texto.'}, format='json'),
            anonymous.get(self.detail_url(comment)),
            anonymous.patch(self.detail_url(comment), {'text': 'Cambio.'}, format='json'),
            anonymous.delete(self.detail_url(comment)),
        ]
        for response in responses:
            self.assertEqual(response.status_code, 401)
        comment.refresh_from_db()
        self.assertEqual(comment.text, 'Texto.')


class ObjectPermissionTests(CommunityTestCase):
    def setUp(self):
        super().setUp()
        self.comment_a = Comment.objects.create(
            topic=self.topic, author=self.user_a, text='Comentario de A.'
        )

    def test_author_can_edit_and_is_marked_edited(self):
        response = self.client_a.patch(
            self.detail_url(self.comment_a), {'text': 'Comentario de A editado.'}, format='json'
        )
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(response.data['text'], 'Comentario de A editado.')

        Comment.objects.filter(pk=self.comment_a.pk).update(
            created_at=self.comment_a.created_at.replace(year=2025)
        )
        self.assertTrue(self.client_b.get(self.detail_url(self.comment_a)).data['edited'])

    def test_author_can_delete(self):
        response = self.client_a.delete(self.detail_url(self.comment_a))
        self.assertEqual(response.status_code, 204)
        self.assertFalse(Comment.objects.filter(pk=self.comment_a.pk).exists())

    def test_b_cannot_edit_or_delete_comment_of_a_by_known_id(self):
        edit = self.client_b.patch(
            self.detail_url(self.comment_a), {'text': 'Intento de B.'}, format='json'
        )
        self.assertEqual(edit.status_code, 403)
        self.assertEqual(self.error_code(edit), 'permission_denied')

        delete = self.client_b.delete(self.detail_url(self.comment_a))
        self.assertEqual(delete.status_code, 403)

        self.comment_a.refresh_from_db()
        self.assertEqual(self.comment_a.text, 'Comentario de A.')

    def test_author_cannot_be_reassigned_by_edit(self):
        self.client_a.patch(
            self.detail_url(self.comment_a),
            {'text': 'Texto.', 'author': self.user_b.pk, 'topic': self.draft.pk},
            format='json',
        )
        self.comment_a.refresh_from_db()
        self.assertEqual(self.comment_a.author, self.user_a)
        self.assertEqual(self.comment_a.topic, self.topic)

    def test_staff_has_no_special_api_permission(self):
        staff = get_user_model().objects.create_user(
            username='staff_prueba', password='clave-de-prueba-123', is_staff=True
        )
        response = self.client_for(staff).delete(self.detail_url(self.comment_a))
        self.assertEqual(response.status_code, 403)

    def test_put_and_missing_comment(self):
        put = self.client_a.put(self.detail_url(self.comment_a), {'text': 'x'}, format='json')
        self.assertEqual(put.status_code, 405)
        missing = self.client_a.get(reverse('community:comment-detail', args=[999999]))
        self.assertEqual(missing.status_code, 404)


class UnpublishedTopicTests(CommunityTestCase):
    def test_cannot_list_or_comment_on_unpublished_topic(self):
        self.assertEqual(self.client_a.get(self.list_url(self.draft)).status_code, 404)
        self.assertEqual(self.post_comment(self.client_a, topic=self.draft).status_code, 404)
        self.assertFalse(Comment.objects.exists())

    def test_comments_disappear_when_topic_is_unpublished(self):
        comment = Comment.objects.create(topic=self.topic, author=self.user_a, text='Texto.')
        type(self.topic).objects.filter(pk=self.topic.pk).update(
            publication_status=PublicationStatus.DRAFT
        )
        self.assertEqual(self.client_a.get(self.list_url()).status_code, 404)
        self.assertEqual(
            self.client_a.patch(self.detail_url(comment), {'text': 'x'}, format='json').status_code,
            404,
        )


class CommentAdminTests(CommunityTestCase):
    def setUp(self):
        super().setUp()
        admin_user = get_user_model().objects.create_superuser(
            username='admin_prueba', password='clave-de-prueba-123'
        )
        self.admin_client = APIClient()
        self.admin_client.force_login(admin_user)
        self.comment = Comment.objects.create(topic=self.topic, author=self.user_a, text='Texto.')

    def test_moderator_can_list_and_delete_but_not_add(self):
        changelist = self.admin_client.get(reverse('admin:community_comment_changelist'))
        self.assertEqual(changelist.status_code, 200)
        self.assertContains(changelist, 'Texto.')

        add = self.admin_client.get(reverse('admin:community_comment_add'))
        self.assertEqual(add.status_code, 403)

        delete = self.admin_client.post(
            reverse('admin:community_comment_delete', args=[self.comment.pk]), {'post': 'yes'}
        )
        self.assertEqual(delete.status_code, 302)
        self.assertFalse(Comment.objects.exists())
