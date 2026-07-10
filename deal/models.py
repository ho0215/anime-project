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

    def __str__(self):
        return f"[{self.get_status_display()}] {self.title} - {self.price}원"