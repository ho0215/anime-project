from django.urls import path
from . import views

app_name = 'works'

urlpatterns = [
    path('', views.work_list, name='work_list'),
    path('<int:pk>/', views.work_detail, name='work_detail'),
    path('create/', views.work_create, name='work_create'),
    path('<int:pk>/like/', views.work_like, name='work_like'),
    path('<int:pk>/bookmark/', views.work_bookmark, name='work_bookmark'),
]