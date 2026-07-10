# anime/urls.py

from django.urls import path
from . import views

app_name = 'anime'

urlpatterns = [
    # 기본 주소(예: 127.0.0.1:8000/)로 접속하면 views.home 함수를 실행합니다.
    path('', views.home, name='home'),
]