# config/urls.py

from django.contrib import admin
from django.urls import path, include # include 추가
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('anime.urls')), 
    path('deal/', include('deal.urls')),
    path('accounts/', include('accounts.urls')),
    path('works/', include('works.urls')),
    path('community/', include('community.urls')),
]
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)