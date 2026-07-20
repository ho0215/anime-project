from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.contrib import messages
from .models import Goods

# Create your views here.

def deal_board(request):
    category_slug = request.GET.get('category')
    search_query = request.GET.get('q', '').strip() # 🛠️ 검색어 가져오기 (공백 제거)
    available_only = request.GET.get('available_only') == '1'

    # 기본 쿼리셋 선언
    goods_list = Goods.objects.all()

    # 1. 카테고리 필터링 (기존 로직 유지)
    if category_slug:
        goods_list = goods_list.filter(category=category_slug)

    # 2. 🛠️ 검색어 필터링 추가 (제목 또는 내용에 키워드가 포함된 경우)
    if search_query:
        goods_list = goods_list.filter(
            Q(title__icontains=search_query) |
            Q(description__icontains=search_query) |
            Q(anime_title__icontains=search_query) # 🛠️ 태그(#귀멸의칼날 등) 검색 조건 추가!
        )

    # 2-1. 판매완료 상품 제외 (판매중만 보기 체크 시)
    if available_only:
        goods_list = goods_list.filter(status__in=['sale', 'reserved'])

    # 3. 최신순 정렬
    goods_list = goods_list.order_by('-created_at')
        
    # 4. 시간 표시 가공 (기존 로직 유지)
    now = timezone.now()
    for goods in goods_list:
        diff = now - goods.created_at
        if diff.days >= 1:
            goods.time_display = f"{diff.days}일 전"
        elif diff.total_seconds() >= 3600:
            hours = int(diff.total_seconds() // 3600)
            goods.time_display = f"{hours}시간 전"
        elif diff.total_seconds() >= 60:
            minutes = int(diff.total_seconds() // 60)
            goods.time_display = f"{minutes}분 전"
        else:
            goods.time_display = "방금 전"
        
    return render(request, 'deal/deal_board.html', {
        'goods_list': goods_list,
        'current_category': category_slug,
        'search_query': search_query, # 🛠️ 템플릿에 검색어 유지용으로 전달
        'available_only': available_only
    })

@login_required(login_url='accounts:login')
@login_required(login_url='accounts:login')
def deal_add(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        category = request.POST.get('category')
        
        # 'anime_title'로 받아보고, 없으면 'tag'로 받아옵니다.
        anime_title = request.POST.get('anime_title') or request.POST.get('tag')
        if not anime_title:
            anime_title = "기타 장르"
            
        price = request.POST.get('price', 0)
        description = request.POST.get('description') or request.POST.get('content')
        
        shipping_list = request.POST.getlist('shipping') or request.POST.getlist('delivery')
        shipping_methods = ", ".join(shipping_list) if shipping_list else "협의 가능"
        
        # 🛠️ 고친 부분: 텍스트가 아닌 실제 업로드된 파일 객체를 request.FILES에서 가져옵니다.
        uploaded_files = request.FILES.getlist('images')
        main_image = uploaded_files[0] if uploaded_files else None

        # DB 저장 (ImageField 매칭)
        Goods.objects.create(
            seller=request.user,
            title=title,
            category=category,
            anime_title=anime_title,
            price=int(price) if price else 0,
            shipping_methods=shipping_methods,
            description=description if description else "내용 없음",
            image=main_image, # 🛠️ 고친 부분: 파일 객체를 그대로 필드에 주입
            status='sale'
        )

        return redirect('deal:deal_board')

    return render(request, 'deal/deal_add.html')