from django.urls import path
from . import views

app_name = 'anime'
urlpatterns = [
    path('list/', views.anime_list, name='anime_list'),
    path('<int:pk>/', views.anime_detail, name='anime_detail'), # 🔥 상세 페이지 경로 추가
    path('', views.home, name='home'),
]