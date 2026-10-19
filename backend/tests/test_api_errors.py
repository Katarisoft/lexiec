"""Contrato común de errores: 400, 401, 403, 404, 405, 415, 422, 429 y 500."""

from unittest import mock

from django.core.cache import cache
from django.test import TestCase, override_settings
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework.throttling import ScopedRateThrottle

from .test_accounts import PASSWORD, create_account


class ErrorContractTestCase(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

    def assert_error(self, response, status, code):
        self.assertEqual(response.status_code, status, response.content)
        self.assertEqual(response['Content-Type'], 'application/json')
        body = response.json()
        self.assertEqual(set(body), {'error'})
        self.assertEqual(body['error']['code'], code)
        self.assertTrue(body['error']['message'])
        content = response.content.decode()
        self.assertNotIn('Traceback', content)
        self.assertNotIn('SECRET_KEY', content)
        return body['error']


class ErrorFormatTests(ErrorContractTestCase):
    def test_400_validation_error_has_field_details(self):
        error = self.assert_error(
            self.client.post(reverse('accounts:register'), {'email': 'x'}, format='json'),
            400,
            'validation_error',
        )
        self.assertIn('email', error['details'])
        self.assertIn('password', error['details'])

    def test_400_malformed_json(self):
        response = self.client.post(
            reverse('accounts:register'), data='{"email":', content_type='application/json'
        )
        self.assert_error(response, 400, 'parse_error')

    def test_401_without_credentials(self):
        self.assert_error(self.client.get(reverse('accounts:me')), 401, 'not_authenticated')

    def test_401_invalid_token(self):
        self.client.credentials(HTTP_AUTHORIZATION='Bearer token-invalido')
        error = self.assert_error(self.client.get(reverse('accounts:me')), 401, 'token_not_valid')
        self.assertNotIn('details', error)

    def test_401_wrong_credentials(self):
        create_account('persona.a@ejemplo.invalid')
        response = self.client.post(
            reverse('accounts:token'),
            {'email': 'persona.a@ejemplo.invalid', 'password': 'incorrecta-2026'},
            format='json',
        )
        self.assert_error(response, 401, 'no_active_account')

    def test_400_invalid_refresh_on_logout(self):
        create_account('persona.a@ejemplo.invalid')
        tokens = self.client.post(
            reverse('accounts:token'),
            {'email': 'persona.a@ejemplo.invalid', 'password': PASSWORD},
            format='json',
        ).data
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        response = self.client.post(reverse('accounts:logout'), {'refresh': 'x'}, format='json')
        self.assert_error(response, 400, 'invalid_refresh_token')

    def test_404_unknown_api_route_is_json(self):
        self.assert_error(self.client.get('/api/v1/no-existe/'), 404, 'not_found')

    def test_405_method_not_allowed(self):
        create_account('persona.a@ejemplo.invalid')
        tokens = self.client.post(
            reverse('accounts:token'),
            {'email': 'persona.a@ejemplo.invalid', 'password': PASSWORD},
            format='json',
        ).data
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        self.assert_error(self.client.delete(reverse('accounts:me')), 405, 'method_not_allowed')

    def test_415_only_json_is_accepted(self):
        response = self.client.post(
            reverse('accounts:register'),
            {'email': 'persona.a@ejemplo.invalid', 'password': PASSWORD},
        )
        self.assert_error(response, 415, 'unsupported_media_type')


class ThrottlingTests(ErrorContractTestCase):
    rates = {'login': '2/min', 'register': '1/hour'}

    def test_429_after_too_many_login_attempts(self):
        with mock.patch.object(ScopedRateThrottle, 'THROTTLE_RATES', self.rates):
            payload = {'email': 'nadie@ejemplo.invalid', 'password': 'incorrecta-2026'}
            for _ in range(2):
                response = self.client.post(reverse('accounts:token'), payload, format='json')
                self.assertEqual(response.status_code, 401)
            response = self.client.post(reverse('accounts:token'), payload, format='json')

        error = self.assert_error(response, 429, 'throttled')
        self.assertGreater(error['details']['retry_after_seconds'], 0)
        self.assertIn('Retry-After', response)

    def test_429_after_too_many_registrations(self):
        with mock.patch.object(ScopedRateThrottle, 'THROTTLE_RATES', self.rates):
            first = self.client.post(
                reverse('accounts:register'),
                {'email': 'persona.a@ejemplo.invalid', 'password': PASSWORD},
                format='json',
            )
            self.assertEqual(first.status_code, 201)
            second = self.client.post(
                reverse('accounts:register'),
                {'email': 'persona.b@ejemplo.invalid', 'password': PASSWORD},
                format='json',
            )
        self.assert_error(second, 429, 'throttled')


@override_settings(ROOT_URLCONF='tests.error_urls')
class ForbiddenAndServerErrorTests(ErrorContractTestCase):
    def test_403_permission_denied(self):
        user = create_account('persona.a@ejemplo.invalid')
        self.client.force_authenticate(user)
        self.assert_error(self.client.get('/api/v1/test/admin-only/'), 403, 'permission_denied')

    def test_500_is_json_without_internal_details(self):
        client = APIClient(raise_request_exception=False)
        response = client.get('/api/v1/test/broken/')
        error = self.assert_error(response, 500, 'server_error')
        self.assertNotIn('detalle interno', response.content.decode())
        self.assertNotIn('details', error)
