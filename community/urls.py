from django.urls import path
from . import views

urlpatterns = [
    path('', views.board_list, name='board_list'),
    path('post/<int:pk>/', views.post_detail, name='post_detail'),
    path('post/create/', views.post_create, name='post_create'),
]
