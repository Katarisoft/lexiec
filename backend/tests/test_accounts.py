"""Pruebas de registro, login JWT, perfil, renovación y logout."""

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken

PASSWORD = 'Clave-de-prueba-2026'


def create_account(email, password=PASSWORD):
    return get_user_model().objects.create_user(username=email, email=email, password=password)


class AuthApiTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

    def login(self, email, password=PASSWORD):
        return self.client.post(
            reverse('accounts:token'), {'email': email, 'password': password}, format='json'
        )

    def tokens_for(self, email, password=PASSWORD):
        response = self.login(email, password)
        self.assertEqual(response.status_code, 200, response.content)
        return response.data

    def authenticate(self, access):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')


class RegisterTests(AuthApiTestCase):
    url = reverse('accounts:register')

    def test_registers_account_with_normalized_email(self):
        response = self.client.post(
            self.url, {'email': '  Persona.A@Ejemplo.Invalid ', 'password': PASSWORD}, format='json'
        )
        self.assertEqual(response.status_code, 201, response.content)
        self.assertEqual(set(response.data), {'id', 'email', 'date_joined'})
        self.assertEqual(response.data['email'], 'persona.a@ejemplo.invalid')

        user = get_user_model().objects.get(pk=response.data['id'])
        self.assertEqual(user.username, 'persona.a@ejemplo.invalid')
        self.assertFalse(user.is_staff)
        self.assertTrue(user.check_password(PASSWORD))

    def test_response_never_exposes_password_or_hash(self):
        response = self.client.post(
            self.url, {'email': 'persona.a@ejemplo.invalid', 'password': PASSWORD}, format='json'
        )
        body = response.content.decode()
        self.assertNotIn(PASSWORD, body)
        self.assertNotIn('pbkdf2', body)
        self.assertNotIn('password', response.data)

    def test_rejects_duplicate_email_case_insensitive(self):
        create_account('persona.a@ejemplo.invalid')
        response = self.client.post(
            self.url, {'email': 'PERSONA.A@ejemplo.invalid', 'password': PASSWORD}, format='json'
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn('email', response.data)
        self.assertEqual(get_user_model().objects.count(), 1)

    def test_rejects_weak_passwords_with_django_validators(self):
        for weak in ('12345678', 'corta1', 'password123', 'persona.a@ejemplo.invalid'):
            with self.subTest(password=weak):
                response = self.client.post(
                    self.url, {'email': 'persona.a@ejemplo.invalid', 'password': weak}, format='json'
                )
                self.assertEqual(response.status_code, 400)
                self.assertIn('password', response.data)
        self.assertFalse(get_user_model().objects.exists())

    def test_rejects_invalid_or_missing_fields(self):
        for payload in ({'email': 'no-es-correo', 'password': PASSWORD}, {'password': PASSWORD}, {}):
            with self.subTest(payload=payload):
                response = self.client.post(self.url, payload, format='json')
                self.assertEqual(response.status_code, 400)

    def test_registration_ignores_privilege_fields(self):
        response = self.client.post(
            self.url,
            {
                'email': 'persona.a@ejemplo.invalid',
                'password': PASSWORD,
                'is_staff': True,
                'is_superuser': True,
            },
            format='json',
        )
        self.assertEqual(response.status_code, 201)
        user = get_user_model().objects.get()
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)


class LoginTests(AuthApiTestCase):
    def setUp(self):
        super().setUp()
        create_account('persona.a@ejemplo.invalid')

    def test_login_returns_access_and_refresh(self):
        response = self.login('Persona.A@ejemplo.invalid')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(set(response.data), {'access', 'refresh'})

    def test_login_rejects_wrong_password_and_unknown_email(self):
        for email, password in (
            ('persona.a@ejemplo.invalid', 'Otra-clave-2026'),
            ('nadie@ejemplo.invalid', PASSWORD),
        ):
            with self.subTest(email=email):
                response = self.login(email, password)
                self.assertEqual(response.status_code, 401)
                self.assertNotIn('access', response.data)

    def test_login_rejects_inactive_account(self):
        get_user_model().objects.filter(username='persona.a@ejemplo.invalid').update(is_active=False)
        self.assertEqual(self.login('persona.a@ejemplo.invalid').status_code, 401)

    def test_admin_username_login_still_works(self):
        get_user_model().objects.create_superuser(username='admin_prueba', password=PASSWORD)
        self.assertTrue(self.client.login(username='admin_prueba', password=PASSWORD))


class ProtectedEndpointTests(AuthApiTestCase):
    def setUp(self):
        super().setUp()
        create_account('persona.a@ejemplo.invalid')

    def test_me_requires_credentials(self):
        response = self.client.get(reverse('accounts:me'))
        self.assertEqual(response.status_code, 401)

    def test_me_rejects_invalid_and_expired_tokens(self):
        self.authenticate('token-invalido')
        self.assertEqual(self.client.get(reverse('accounts:me')).status_code, 401)

        user = get_user_model().objects.get()
        expired = AccessToken.for_user(user)
        expired.set_exp(lifetime=-timedelta(seconds=1))
        self.authenticate(str(expired))
        self.assertEqual(self.client.get(reverse('accounts:me')).status_code, 401)

    def test_me_rejects_refresh_token_used_as_access(self):
        tokens = self.tokens_for('persona.a@ejemplo.invalid')
        self.authenticate(tokens['refresh'])
        self.assertEqual(self.client.get(reverse('accounts:me')).status_code, 401)

    def test_me_returns_only_public_profile(self):
        tokens = self.tokens_for('persona.a@ejemplo.invalid')
        self.authenticate(tokens['access'])
        response = self.client.get(reverse('accounts:me'))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(set(response.data), {'id', 'email', 'date_joined'})
        self.assertEqual(response.data['email'], 'persona.a@ejemplo.invalid')


class RefreshAndLogoutTests(AuthApiTestCase):
    def setUp(self):
        super().setUp()
        create_account('persona.a@ejemplo.invalid')
        create_account('persona.b@ejemplo.invalid')

    def refresh(self, token):
        return self.client.post(reverse('accounts:token-refresh'), {'refresh': token}, format='json')

    def logout(self, refresh):
        return self.client.post(reverse('accounts:logout'), {'refresh': refresh}, format='json')

    def test_refresh_rotates_and_blacklists_previous_token(self):
        tokens = self.tokens_for('persona.a@ejemplo.invalid')
        response = self.refresh(tokens['refresh'])
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)
        self.assertNotEqual(response.data['refresh'], tokens['refresh'])

        self.assertEqual(self.refresh(tokens['refresh']).status_code, 401)

    def test_logout_requires_authentication(self):
        tokens = self.tokens_for('persona.a@ejemplo.invalid')
        self.assertEqual(self.logout(tokens['refresh']).status_code, 401)

    def test_refresh_is_rejected_after_logout(self):
        tokens = self.tokens_for('persona.a@ejemplo.invalid')
        self.authenticate(tokens['access'])
        self.assertEqual(self.logout(tokens['refresh']).status_code, 204)

        self.client.credentials()
        self.assertEqual(self.refresh(tokens['refresh']).status_code, 401)

    def test_access_token_remains_valid_until_expiry_after_logout(self):
        """Limitación documentada: el logout no revoca el access ya emitido."""
        tokens = self.tokens_for('persona.a@ejemplo.invalid')
        self.authenticate(tokens['access'])
        self.logout(tokens['refresh'])
        self.assertEqual(self.client.get(reverse('accounts:me')).status_code, 200)

    def test_user_cannot_logout_another_users_session(self):
        tokens_a = self.tokens_for('persona.a@ejemplo.invalid')
        tokens_b = self.tokens_for('persona.b@ejemplo.invalid')

        self.authenticate(tokens_b['access'])
        response = self.logout(tokens_a['refresh'])
        self.assertEqual(response.status_code, 400)

        self.client.credentials()
        self.assertEqual(self.refresh(tokens_a['refresh']).status_code, 200)

    def test_logout_rejects_invalid_or_missing_refresh(self):
        tokens = self.tokens_for('persona.a@ejemplo.invalid')
        self.authenticate(tokens['access'])
        self.assertEqual(self.logout('no-es-un-token').status_code, 400)
        self.assertEqual(
            self.client.post(reverse('accounts:logout'), {}, format='json').status_code, 400
        )

    def test_logout_twice_is_rejected(self):
        tokens = self.tokens_for('persona.a@ejemplo.invalid')
        self.authenticate(tokens['access'])
        self.assertEqual(self.logout(tokens['refresh']).status_code, 204)
        self.assertEqual(self.logout(tokens['refresh']).status_code, 400)
