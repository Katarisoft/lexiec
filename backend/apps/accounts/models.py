from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models

DISPLAY_NAME_MAX_LENGTH = 40


def validate_display_name(value):
    # Evita publicar un correo como alias por descuido.
    if '@' in value:
        raise ValidationError('El alias no puede contener «@».')


class Profile(models.Model):
    """Datos públicos opcionales de una cuenta."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        verbose_name='cuenta',
        on_delete=models.CASCADE,
        related_name='profile',
    )
    display_name = models.CharField(
        'alias público',
        max_length=DISPLAY_NAME_MAX_LENGTH,
        blank=True,
        validators=[validate_display_name],
    )

    class Meta:
        verbose_name = 'perfil'
        verbose_name_plural = 'perfiles'

    def __str__(self):
        return public_name(self.user)


def public_name(user):
    """Nombre visible para otras cuentas; nunca el correo."""
    profile = getattr(user, 'profile', None)
    if profile is not None and profile.display_name:
        return profile.display_name
    return f'Usuario {user.pk}'
