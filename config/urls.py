# config/urls.py

from django.contrib import admin
from django.urls import path, include # include 추가

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('anime.urls')), 
    path('deal/', include('deal.urls')),
    path('accounts/', include('accounts.urls')),
    path('works/', include('works.urls')),
]