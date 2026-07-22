from django.urls import path
from . import views

app_name = 'works'

urlpatterns = [
    path('', views.work_list, name='work_list'),
    path('<int:pk>/', views.work_detail, name='work_detail'),
    path('create/', views.work_create, name='work_create'),
    path('<int:pk>/edit/', views.work_update, name='work_update'),
    path('<int:pk>/delete/', views.work_delete, name='work_delete'),
    path('<int:pk>/like/', views.work_like, name='work_like'),
    path('<int:pk>/bookmark/', views.work_bookmark, name='work_bookmark'),
    path('my/drafts/', views.my_drafts, name='my_drafts'),
    path('my/archive/', views.my_archive, name='my_archive'),
    path('my/interests/', views.my_interests, name='my_interests'),
    path('<int:pk>/toggle-visibility/', views.work_toggle_visibility, name='work_toggle_visibility'),
]