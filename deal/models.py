from django.db import models
from django.contrib.auth.models import User # 장고 기본 유저 모델 활용

class Goods(models.Model):
    # 카테고리 정의
    CATEGORY_CHOICES = [ 
        ('acrylic', '아크릴 스탠드/키링'),
        ('badge', '캔뱃지/핀버튼'),
        ('figure', '피규어/넨도로이드'),
        ('plush', '인형/누이구루미'),
        ('paper', '지류(파샤/포카/특전)'),
        ('etc', '기타'),
    ]

    # 거래 상태 정의
    STATUS_CHOICES = [
        ('sale', '판매중'),
        ('reserved', '예약중'),
        ('sold', '판매완료'),
    ]

    # 모델 필드 구성
    seller = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="판매자")
    title = models.CharField(max_length=200, verbose_name="제목")
    anime_title = models.CharField(max_length=100, verbose_name="작품명(태그)")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='etc', verbose_name="굿즈 종류")
    price = models.IntegerField(default=0, verbose_name="가격")
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='sale', verbose_name="거래 상태")
    
    # 배송 방법 (복수 선택을 쉽게 처리하기 위해 우선 텍스트나 간단한 문자열로 저장)
    shipping_methods = models.CharField(max_length=200, verbose_name="배송 방법", help_text="ex: GS반택, 준등기")
    
    # 대표 이미지 (Pillow 라이브러리 필요)
    # 만약 이미지 필드 에러 나면 우선 지우고 주석 해제해서 문자열(URL) 필드로 임시 대체 가능합니다.
    image = models.ImageField(upload_to='goods_images/', blank=True, null=True, verbose_name="굿즈 사진")
    
    description = models.TextField(verbose_name="상세 설명")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="등록일")
    view_count = models.PositiveIntegerField(default=0, verbose_name="조회수")

    def __str__(self):
        return f"[{self.get_status_display()}] {self.title} - {self.price}원"
    
# deal/models.py

class ChatRoom(models.Model):
    goods = models.ForeignKey(Goods, on_delete=models.CASCADE, related_name='chat_rooms', verbose_name="관련 굿즈")
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='buyer_rooms', verbose_name="구매자")
    seller = models.ForeignKey(User, on_delete=models.CASCADE, related_name='seller_rooms', verbose_name="판매자")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="방 생성일")

    # 🛠️ 추가: 각각의 참여자가 마지막으로 대화창을 본 시간 기록
    buyer_last_viewed = models.DateTimeField(auto_now_add=True, verbose_name="구매자 최종 확인 시각")
    seller_last_viewed = models.DateTimeField(auto_now_add=True, verbose_name="판매자 최종 확인 시각")
    
    buyer_left = models.BooleanField(default=False, verbose_name="구매자 나감 여부")
    seller_left = models.BooleanField(default=False, verbose_name="판매자 나감 여부")

    class Meta:
        unique_together = ('goods', 'buyer', 'seller')

    def __str__(self):
        return f"[{self.goods.title}] {self.buyer.username}님과 {self.seller.username}님의 채팅방"


class Message(models.Model):
    # 이 메시지가 속한 채팅방
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='messages', verbose_name="채팅방")
    # 메시지를 보낸 사람 (buyer 혹은 seller 둘 중 한 명)
    sender = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="발신자")
    # 대화 내용
    content = models.TextField(verbose_name="내용")
    timestamp = models.DateTimeField(auto_now_add=True, verbose_name="전송 시각")

    class Meta:
        ordering = ['timestamp'] # 채팅 내역은 무조건 보낸 순서대로 정렬

    def __str__(self):
        return f"{self.sender.username}: {self.content[:20]}"


class Wishlist(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='wishlists', verbose_name="유저")
    goods = models.ForeignKey(Goods, on_delete=models.CASCADE, related_name='wishlisted_by', verbose_name="찜한 굿즈")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="찜한 시각")

    class Meta:
        unique_together = ('user', 'goods')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username}님이 찜한 {self.goods.title}"