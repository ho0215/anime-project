from django.urls import path
from . import views

app_name = 'deal'

urlpatterns = [
    path('', views.deal_board, name = 'deal_board'),
]