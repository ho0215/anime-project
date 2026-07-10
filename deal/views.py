from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
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

@login_required(login_url='accounts:login')
def deal_add(request):
    if request.method == 'POST':
        # POST 요청으로 들어온 데이터 가져오기
        title = request.POST.get('title')
        category = request.POST.get('category')
        tag = request.POST.get('tag')
        price = request.POST.get('price')
        delivery = request.POST.get('delivery')
        content = request.POST.get('content')
        
        # 파일 데이터(이미지) 가져오기
        # HTML에서 multiple 속성을 썼으므로 getlist로 가져옵니다.
        # 만약 단일 이미지라면 request.FILES.get('images')를 사용합니다.
        images = request.FILES.getlist('images')
        main_image = images[0] if images else None

        # 데이터베이스에 새 상품 저장
        goods = Goods.objects.create(
            user=request.user,  # 작성자 연동 (모델에 외래키가 있을 경우)
            title=title,
            category=category,
            tag=tag,
            price=price,
            delivery=delivery,
            content=content,
            image=main_image,   # 대표 이미지 저장
            status='sale'       # 기본 상태는 '판매중'으로 설정
        )
        
        # 다중 이미지 저장을 위한 별도 테이블(예: GoodsImage)이 있다면 여기서 처리합니다.
        # for img in images:
        #     GoodsImage.objects.create(goods=goods, image=img)

        # 등록 완료 후 게시판 목록(deal_board)으로 이동
        return redirect('deal:deal_board')

    # GET 요청일 때는 작성 페이지 폼을 보여줌
    return render(request, 'deal/deal_add.html')