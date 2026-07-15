from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    # ws://서버주소/ws/deal/chat/방번호/ 구조로 접속 요청을 받음
    re_path(r'ws/deal/chat/(?P<room_id>\d+)/$', consumers.ChatConsumer.as_asgi()),
    re_path(r'ws/deal/chats/$', consumers.ChatListConsumer.as_asgi()),
]