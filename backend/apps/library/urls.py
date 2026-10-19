from django.urls import path

from .views import AreaListView, TopicDetailView, TopicListView

app_name = 'library'

urlpatterns = [
    path('areas/', AreaListView.as_view(), name='area-list'),
    path('topics/', TopicListView.as_view(), name='topic-list'),
    path('topics/<int:pk>/', TopicDetailView.as_view(), name='topic-detail'),
]
