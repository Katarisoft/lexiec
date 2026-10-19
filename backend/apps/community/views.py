from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated

from apps.library.models import TopicCard

from .models import Comment
from .permissions import IsAuthorOrReadOnly
from .serializers import CommentSerializer


class CommentPagination(PageNumberPagination):
    page_size = 20


def comments_with_author():
    return Comment.objects.select_related('author', 'author__profile')


class TopicCommentListCreateView(generics.ListCreateAPIView):
    """Comentarios de una ficha publicada, del más reciente al más antiguo."""

    serializer_class = CommentSerializer
    pagination_class = CommentPagination
    permission_classes = [IsAuthenticated]

    def get_topic(self):
        # Una ficha no publicada no existe para la API (404).
        return get_object_or_404(TopicCard.objects.published(), pk=self.kwargs['topic_id'])

    def get_queryset(self):
        return comments_with_author().filter(topic=self.get_topic())

    def perform_create(self, serializer):
        serializer.save(topic=self.get_topic(), author=self.request.user)


class CommentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Edición y borrado por el autor; permiso comprobado por objeto."""

    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated, IsAuthorOrReadOnly]
    http_method_names = ['get', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        return comments_with_author().filter(topic__in=TopicCard.objects.published())
