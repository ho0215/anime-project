# deal/consumers.py
import json  # 🛠️ 누락 방지 핵심 임포트
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from .models import ChatRoom, Message
from django.contrib.auth import get_user_model

User = get_user_model()

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'deal_chat_{self.room_id}'

        user = self.scope['user']
        is_member = await self.check_room_member(self.room_id, user)
        
        if not user.is_authenticated or not is_member:
            await self.close()
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            message_content = data.get('message', '').strip()
            
            if not message_content:
                return

            sender = self.scope['user']
            if not sender.is_authenticated:
                return

            # DB 저장
            await self.save_message(self.room_id, sender, message_content)

            # 1. 채팅방 내부 인원들에게 대화 내용 뿌리기
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': message_content,
                    'sender_username': sender.username,
                    'sender_id': sender.id,
                }
            )

            # 2. 대화 상대방의 '채팅 목록창' 실시간 동기화 신호 발송
            room_users = await self.get_room_users(self.room_id)
            for user_id in room_users:
                if user_id != sender.id:
                    await self.channel_layer.group_send(
                        f'user_{user_id}',
                        {
                            'type': 'chat_update',
                            'room_id': self.room_id,
                            'message': message_content,
                            'sender_username': sender.username
                        }
                    )
        except Exception as e:
            print(f"ChatConsumer receive 에러: {e}")

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            'message': event['message'],
            'sender_username': event['sender_username'],
            'sender_id': event['sender_id']
        }))

    @database_sync_to_async
    def save_message(self, room_id, sender, content):
        try:
            room = ChatRoom.objects.get(id=room_id)
            message = Message.objects.create(room=room, sender=sender, content=content)
            
            now = timezone.now()
            if sender == room.buyer:
                room.buyer_last_viewed = now
            else:
                room.seller_last_viewed = now
            room.save()
            return message
        except Exception as e:
            print(f"save_message 에러: {e}")

    @database_sync_to_async
    def check_room_member(self, room_id, user):
        try:
            room = ChatRoom.objects.get(id=room_id)
            return user == room.buyer or user == room.seller
        except:
            return False

    @database_sync_to_async
    def get_room_users(self, room_id):
        try:
            room = ChatRoom.objects.get(id=room_id)
            return [room.buyer.id, room.seller.id]
        except:
            return []


# 🛠️ 채팅 목록 제어용 컨슈머 (안전 예외 처리 추가)
class ChatListConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        if not self.user.is_authenticated:
            await self.close()
            return

        self.user_group_name = f'user_{self.user.id}'
        await self.channel_layer.group_add(
            self.user_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'user_group_name'):
            await self.channel_layer.group_discard(
                self.user_group_name,
                self.channel_name
            )

    async def chat_update(self, event):
        try:
            await self.send(text_data=json.dumps({
                'room_id': event['room_id'],
                'message': event['message'],
                'sender_username': event['sender_username']
            }))
        except Exception as e:
            print(f"ChatListConsumer 갱신 에러: {e}")