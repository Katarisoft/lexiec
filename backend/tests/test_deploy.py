"""Salud del servicio y configuración de despliegue (E20)."""

import os
import subprocess
import sys
from unittest import mock

from django.conf import settings
from django.db import DatabaseError
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient


class HealthTests(TestCase):
    def test_health_is_public_and_minimal(self):
        response = APIClient().get(reverse('health'))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {'status': 'ok'})

    def test_health_reports_unavailable_without_details(self):
        with mock.patch('config.health.connection') as fake:
            fake.cursor.side_effect = DatabaseError('detalle interno de la base')
            response = APIClient().get(reverse('health'))
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()['error']['code'], 'service_unavailable')
        self.assertNotIn('detalle interno', response.content.decode())


class ProductionSettingsTests(TestCase):
    """Importa settings en un proceso aislado con variables de producción."""

    def production_settings(self, **extra):
        env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith(('DJANGO_', 'POSTGRES_'))
        }
        env.update(
            DJANGO_ENV_FILE='/nonexistent-lexiec-env',
            DJANGO_DEBUG='0',
            DJANGO_SECRET_KEY='clave-solo-para-esta-prueba-' + 'x' * 40,
            DJANGO_ALLOWED_HOSTS='api.ejemplo.invalid',
            DJANGO_CSRF_TRUSTED_ORIGINS='https://api.ejemplo.invalid',
            **extra,
        )
        code = (
            'import json, config.settings as s; print(json.dumps({'
            '"debug": s.DEBUG, "hosts": s.ALLOWED_HOSTS, "csrf": s.CSRF_TRUSTED_ORIGINS,'
            '"proxy": getattr(s, "SECURE_PROXY_SSL_HEADER", None),'
            '"secure_cookies": getattr(s, "SESSION_COOKIE_SECURE", False),'
            '"static": s.STORAGES["staticfiles"]["BACKEND"]}))'
        )
        result = subprocess.run(
            [sys.executable, '-c', code],
            cwd=settings.BASE_DIR,
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        import json

        return json.loads(result.stdout)

    def test_production_values_and_https_proxy_only_when_enabled(self):
        plain = self.production_settings()
        self.assertFalse(plain['debug'])
        self.assertEqual(plain['hosts'], ['api.ejemplo.invalid'])
        self.assertEqual(plain['csrf'], ['https://api.ejemplo.invalid'])
        self.assertIsNone(plain['proxy'])
        self.assertFalse(plain['secure_cookies'])
        self.assertIn('CompressedManifest', plain['static'])

        behind = self.production_settings(DJANGO_BEHIND_HTTPS_PROXY='1')
        self.assertEqual(behind['proxy'], ['HTTP_X_FORWARDED_PROTO', 'https'])
        self.assertTrue(behind['secure_cookies'])
