from django.contrib import admin

# Register your models here.
# deal/admin.py
from django.contrib import admin
from .models import Goods

@admin.register(Goods)
class GoodsAdmin(admin.ModelAdmin):
    # 1. 어드민 글 목록 화면에 보여줄 필드들
    list_display = ('id', 'title', 'anime_title', 'category', 'price', 'status', 'seller', 'created_at')
    
    # 2. 클릭해서 상세 페이지로 들어갈 수 있는 필드 지정
    list_display_links = ('id', 'title')
    
    # 3. 우측에 필터 박스 생성 (카테고리별, 거래 상태별로 필터링 가능)
    list_filter = ('category', 'status', 'created_at')
    
    # 4. 검색창 제공 (제목, 작품명, 판매자 계정명으로 검색 가능)
    search_fields = ('title', 'anime_title', 'seller__username')
    
    # 5. 목록 화면에서 바로 수정 가능하게 만들 필드 (선택 사항)
    list_editable = ('status', 'price')