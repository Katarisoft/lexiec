"""Autenticación por correo electrónico.

Las cuentas de la app guardan el correo normalizado también como `username`,
de modo que la unicidad la garantiza la restricción existente de Django.
"""

from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend


def normalize_email(email):
    return (email or '').strip().lower()


class EmailBackend(ModelBackend):
    def authenticate(self, request, email=None, password=None, **kwargs):
        if email is None or password is None:
            return None
        user_model = get_user_model()
        try:
            user = user_model._default_manager.get(username=normalize_email(email))
        except user_model.DoesNotExist:
            # Igualar el coste del hash para no revelar si el correo existe.
            user_model().set_password(password)
            return None
        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None
