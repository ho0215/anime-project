from django.urls import path
from . import views

app_name = 'anime'
urlpatterns = [
    path('list/', views.anime_list, name='anime_list'),
    path('', views.home, name='home'),
]