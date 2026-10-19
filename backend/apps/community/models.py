"""Comentarios públicos de la comunidad sobre las fichas.

Los comentarios son opiniones de usuarios: nunca son fuente normativa ni
alimentan al asistente.
"""

from django.conf import settings
from django.db import models

from apps.library.models import TopicCard

COMMENT_MAX_LENGTH = 1000


class Comment(models.Model):
    topic = models.ForeignKey(
        TopicCard,
        verbose_name='ficha',
        on_delete=models.CASCADE,
        related_name='comments',
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        verbose_name='autor',
        on_delete=models.CASCADE,
        related_name='comments',
    )
    text = models.TextField('texto', max_length=COMMENT_MAX_LENGTH)
    created_at = models.DateTimeField('creado', auto_now_add=True)
    updated_at = models.DateTimeField('actualizado', auto_now=True)

    class Meta:
        ordering = ['-created_at', '-id']
        verbose_name = 'comentario'
        verbose_name_plural = 'comentarios'
        indexes = [
            models.Index(fields=['topic', '-created_at'], name='comment_topic_created_idx'),
        ]

    def __str__(self):
        return f'Comentario {self.pk} en {self.topic}'
