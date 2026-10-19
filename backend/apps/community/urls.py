from django.urls import path

from .views import CommentDetailView, TopicCommentListCreateView

app_name = 'community'

urlpatterns = [
    path(
        'topics/<int:topic_id>/comments/',
        TopicCommentListCreateView.as_view(),
        name='topic-comments',
    ),
    path('comments/<int:pk>/', CommentDetailView.as_view(), name='comment-detail'),
]
