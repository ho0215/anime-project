# config/urls.py

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse

def health_check(request):
    return HttpResponse("OK", status=200)

urlpatterns = [
    path('health/', health_check),   # 👈 ALB 헬스체크 전용 경로
    path('admin/', admin.site.urls),
    path('', include('anime.urls')), # 👈 메인 홈페이지 정상 연결
    path('deal/', include('deal.urls')),
    path('accounts/', include('accounts.urls')),
    path('works/', include('works.urls')),
    path('community/', include('community.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
