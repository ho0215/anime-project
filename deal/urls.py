from django.urls import path
from . import views

app_name = 'deal'

urlpatterns = [
    path('', views.deal_board, name = 'deal_board'),
    path('add/', views.deal_add, name = 'deal_add'),
    path('<int:goods_id>/', views.deal_detail, name='deal_detail'),
    path('<int:goods_id>/edit/', views.deal_edit, name='deal_edit'),
    path('<int:goods_id>/delete/', views.deal_delete, name='deal_delete'),
    path('<int:goods_id>/bump/', views.deal_bump, name='deal_bump'),
    path('<int:goods_id>/chat/start/', views.deal_chat_start, name='deal_chat_start'),
    path('chat/<int:room_id>/', views.deal_chat_room, name='deal_chat_room'),
    path('chats/', views.deal_chat_list, name='deal_chat_list'),
    path('chat/<int:room_id>/leave/', views.deal_chat_leave, name='deal_chat_leave'),
    path('goods/<int:goods_id>/status-ajax/', views.change_goods_status_ajax, name='change_goods_status_ajax'),
]