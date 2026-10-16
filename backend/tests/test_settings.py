"""Pruebas de la configuración base del backend."""

import os
import subprocess
import sys
from unittest import mock

from django.conf import settings
from django.db import connection
from django.test import SimpleTestCase, TestCase

from config.settings import env_bool, env_list


class DatabaseTests(TestCase):
    def test_uses_postgresql_and_responds(self):
        self.assertEqual(connection.vendor, 'postgresql')
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
            self.assertEqual(cursor.fetchone(), (1,))


class EnvHelpersTests(SimpleTestCase):
    def test_env_bool_accepts_true_values(self):
        for value in ('1', 'true', 'TRUE', 'yes', 'on', ' 1 '):
            with mock.patch.dict(os.environ, {'LEXIEC_FLAG': value}):
                self.assertTrue(env_bool('LEXIEC_FLAG'))

    def test_env_bool_rejects_other_values(self):
        for value in ('0', 'false', 'no', 'off', ''):
            with mock.patch.dict(os.environ, {'LEXIEC_FLAG': value}):
                self.assertFalse(env_bool('LEXIEC_FLAG', default=True))

    def test_env_bool_uses_default_when_missing(self):
        with mock.patch.dict(os.environ, clear=False):
            os.environ.pop('LEXIEC_FLAG', None)
            self.assertTrue(env_bool('LEXIEC_FLAG', default=True))
            self.assertFalse(env_bool('LEXIEC_FLAG'))

    def test_env_list_splits_and_trims(self):
        with mock.patch.dict(os.environ, {'LEXIEC_HOSTS': ' a.ec, b.ec ,,'}):
            self.assertEqual(env_list('LEXIEC_HOSTS'), ['a.ec', 'b.ec'])


class SecretKeyStartupTests(SimpleTestCase):
    """Comprueba el arranque de settings en un proceso aislado."""

    def _import_settings(self, **overrides):
        env = {
            key: value
            for key, value in os.environ.items()
            if key not in ('DJANGO_SECRET_KEY', 'DJANGO_DEBUG')
        }
        env.update(overrides)
        return subprocess.run(
            [sys.executable, '-c', 'import config.settings'],
            cwd=settings.BASE_DIR,
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
        )

    def test_fails_without_secret_key_when_debug_is_off(self):
        result = self._import_settings(DJANGO_DEBUG='0')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('ImproperlyConfigured', result.stderr)

    def test_starts_with_secret_key_when_debug_is_off(self):
        result = self._import_settings(
            DJANGO_DEBUG='0', DJANGO_SECRET_KEY='clave-solo-para-esta-prueba'
        )
        self.assertEqual(result.returncode, 0, result.stderr)
