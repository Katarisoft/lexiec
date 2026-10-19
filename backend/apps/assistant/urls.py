from django.urls import path

from .views import ConsultationDetailView, ConsultationListView

app_name = 'assistant'

urlpatterns = [
    path('consultations/', ConsultationListView.as_view(), name='consultation-list'),
    path('consultations/<int:pk>/', ConsultationDetailView.as_view(), name='consultation-detail'),
]
