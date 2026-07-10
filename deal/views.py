from django.shortcuts import render
from .models import Goods

# Create your views here.

def deal_board(request):
    category_slug = request.GET.get('category') # URL에서 ?category= 값 가져오기
    
    if category_slug:
        # DB에서 해당 카테고리 상품만 필터링 (모델명과 필드명은 본인 구조에 맞게)
        goods_list = Goods.objects.filter(category=category_slug)
    else:
        # 조건 없으면 전체 상품
        goods_list = Goods.objects.all()
        
    return render(request, 'deal/deal_board.html', {
        'goods_list': goods_list,
        'current_category': category_slug
    })