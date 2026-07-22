from django.urls import path
from . import views

app_name = 'anime'
urlpatterns = [
    path('list/', views.anime_list, name='anime_list'),
    path('<int:pk>/', views.anime_detail, name='anime_detail'), # 🔥 상세 페이지 경로 추가
    path('<int:pk>/review/<int:review_pk>/delete/', views.review_delete, name='review_delete'),
    path('', views.home, name='home'),
    path('api/chatbot/', views.chatbot_api, name='chatbot_api'),
]