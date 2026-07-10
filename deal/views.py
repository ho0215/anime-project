from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from .models import Goods

def deal_board(request):
    category_slug = request.GET.get('category')
    
    if category_slug:
        # 최신순(-created_at) 정렬 조건 추가
        goods_list = Goods.objects.filter(category=category_slug).order_by('-created_at')
    else:
        goods_list = Goods.objects.all().order_by('-created_at')
        
    return render(request, 'deal/deal_board.html', {
        'goods_list': goods_list,
        'current_category': category_slug
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