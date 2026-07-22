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
    path('post/<int:pk>/delete/', views.post_delete, name='post_delete'),
    path('post/<int:pk>/edit/', views.post_edit, name='post_edit'),

    # 추가된 댓글 수정 및 삭제 URL 패턴
    path('comment/<int:comment_id>/edit/', views.comment_edit, name='comment_edit'),
    path('comment/<int:comment_id>/delete/', views.comment_delete, name='comment_delete'),
]