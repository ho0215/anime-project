# config/urls.py

from django.contrib import admin
from django.urls import path, include # include 추가

urlpatterns = [
    path('admin/', admin.site.urls),
    # 기본 주소로 들어오는 모든 요청을 anime 앱의 urls.py로 토스합니다.
    path('', include('anime.urls')), 
]