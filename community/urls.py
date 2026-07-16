# urls.py
from django.urls import path
from . import views

app_name = "community"

urlpatterns = [
    # 1. 게시판 목록화면
    path('', views.board_list, name='board_list'),
    
    # 2. 글쓰기 화면 (에디터 포함)
    path('create/', views.post_create, name='post_create'),
    
    # 3. 글 상세보기 화면 (pk 번호 기반)
    path('<int:pk>/', views.post_detail, name='post_detail'),
    
    path('<int:pk>/like/', views.post_like, name='post_like'),
]