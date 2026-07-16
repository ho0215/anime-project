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
    path('<int:goods_id>/wishlist-ajax/', views.toggle_wishlist, name='toggle_wishlist'),
    path('wishlist/', views.deal_wishlist, name='deal_wishlist'),
    path('<int:goods_id>/report/', views.deal_goods_report, name='deal_goods_report'),
    path('report/user/<str:username>/', views.deal_user_report, name='deal_user_report'),
    path('reports/mine/', views.deal_my_reports, name='deal_my_reports'),
    path('reports/', views.deal_report_list, name='deal_report_list'),
    path('reports/<str:report_type>/<int:report_id>/status-ajax/', views.update_report_status_ajax, name='update_report_status_ajax'),
]