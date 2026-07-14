from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Goods
from django.core.exceptions import PermissionDenied
from django.utils import timezone
from datetime import timedelta
from django.db.models import Q, Max, F
from .models import Goods, ChatRoom, Message, Wishlist
from django.http import JsonResponse
from django.views.decorators.http import require_POST

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

@login_required(login_url='accounts:login')
def deal_bump(request, goods_id):
    if request.method == 'POST':
        goods = get_object_or_404(Goods, id=goods_id)
        
        # 본인 글이 아니면 거부
        if goods.seller != request.user:
            raise PermissionDenied
            
        # created_at 시간을 현재 시간으로 갱신하여 맨 위로 올림
        goods.created_at = timezone.now()
        goods.save()
        
        return redirect('deal:deal_detail', goods_id=goods.id)
        
    return redirect('deal:deal_detail', goods_id=goods_id)

# 1. 판매글 상세 페이지 뷰
def deal_detail(request, goods_id):
    # goods_id에 해당하는 글을 가져오고, 없으면 404 에러를 띄웁니다.
    goods = get_object_or_404(Goods, id=goods_id)
    Goods.objects.filter(id=goods.id).update(view_count=F('view_count') + 1)
    goods.refresh_from_db(fields=['view_count'])

    is_wishlisted = False
    if request.user.is_authenticated:
        is_wishlisted = Wishlist.objects.filter(user=request.user, goods=goods).exists()
    wishlist_count = Wishlist.objects.filter(goods=goods).count()

    return render(request, 'deal/deal_detail.html', {
        'goods': goods,
        'is_wishlisted': is_wishlisted,
        'wishlist_count': wishlist_count
    })

# 2. 판매글 수정 페이지 뷰 (GET: 수정 폼 띄우기, POST: 수정 내용 DB 반영)
@login_required(login_url='accounts:login')
def deal_edit(request, goods_id):
    goods = get_object_or_404(Goods, id=goods_id)

    # 작성자 본인이 아니면 수정을 거부합니다.
    if goods.seller != request.user:
        raise PermissionDenied

    if request.method == 'POST':
        # POST로 넘어온 데이터로 기존 goods 객체의 필드를 업데이트합니다.
        goods.title = request.POST.get('title')
        goods.category = request.POST.get('category')
        goods.anime_title = request.POST.get('anime_title') or request.POST.get('tag')
        goods.price = request.POST.get('price', 0)
        goods.shipping_methods = request.POST.get('delivery')
        goods.description = request.POST.get('content')
        goods.status = request.POST.get('status') # 수정 페이지에 상태 변경 기능 필요

        # 새로운 이미지가 업로드된 경우에만 교체합니다.
        if request.FILES.get('images'):
            goods.image = request.FILES.get('images')

        # 변경사항을 DB에 저장합니다. (이미지 Field가 ImageField이므로 Pillow가 자동 처리)
        goods.save()
        
        return redirect('deal:deal_detail', goods_id=goods.id)

    # GET 요청 시: 기존 데이터가 채워진 수정 폼 페이지를 렌더링합니다.
    # deal_add.html과 유사한 형태의 deal_edit.html이 필요합니다.
    return render(request, 'deal/deal_edit.html', {
        'goods': goods
    })

# 3. 판매글 삭제 처리 뷰
@login_required(login_url='accounts:login')
def deal_delete(request, goods_id):
    if request.method == 'POST':
        goods = get_object_or_404(Goods, id=goods_id)

        # 작성자 본인이 아니면 삭제를 거부합니다.
        if goods.seller != request.user:
            raise PermissionDenied

        # 글 삭제 (연관된 ImageField 파일은 장고가 자동 삭제하지 않으므로, 필요시 직접 삭제 로직 추가 필요)
        goods.delete()
        
        return redirect('deal:deal_board')
    
    return redirect('deal:deal_detail', goods_id=goods_id)

@login_required(login_url='accounts:login')
def deal_chat_start(request, goods_id):
    """'채팅 문의하기' 클릭 시 방을 조회하거나 생성하고 이동시키는 뷰"""
    goods = get_object_or_404(Goods, id=goods_id)
    buyer = request.user
    seller = goods.seller

    # 본인 상품에 본인이 채팅하는 것 방지
    if buyer == seller:
        return redirect('deal:deal_detail', goods_id=goods.id)

    # 판매완료된 상품은 채팅 문의 불가
    if goods.status == 'sold':
        return redirect('deal:deal_detail', goods_id=goods.id)

    # 기존에 두 사람 사이에 이 상품으로 개설된 방이 있는지 조회, 없으면 생성
    room, created = ChatRoom.objects.get_or_create(
        goods=goods,
        buyer=buyer,
        seller=seller
    )
    return redirect('deal:deal_chat_room', room_id=room.id)


@login_required(login_url='accounts:login')
def deal_chat_room(request, room_id):
    """실제 채팅방 화면을 띄우고 이전 대화 내역을 넘겨주는 뷰"""
    room = get_object_or_404(ChatRoom, id=room_id)

    if request.user != room.buyer and request.user != room.seller:
        return redirect('deal:deal_board')

    # 🛠️ 추가: 방 입장 시 본인의 최종 확인 시간 갱신
    now = timezone.now()
    if request.user == room.buyer:
        room.buyer_last_viewed = now
    else:
        room.seller_last_viewed = now
    room.save()

    messages = room.messages.all()
    return render(request, 'deal/chat_room.html', {'room': room, 'chat_messages': messages})


@login_required(login_url='accounts:login')
def deal_chat_list(request):
    """내가 참여 중이고, 나가지 않은 1:1 채팅방 목록 조회"""
    # 🛠️ 내가 구매자이면서 안 나갔거나, 판매자이면서 안 나간 방만 필터링
    rooms = ChatRoom.objects.filter(
        (Q(buyer=request.user) & Q(buyer_left=False)) |
        (Q(seller=request.user) & Q(seller_left=False))
    ).annotate(
        latest_message_time=Max('messages__timestamp')
    ).order_by('-latest_message_time', '-created_at')

    for room in rooms:
        if request.user == room.buyer:
            room.unread_count = room.messages.filter(timestamp__gt=room.buyer_last_viewed).exclude(sender=request.user).count()
        else:
            room.unread_count = room.messages.filter(timestamp__gt=room.seller_last_viewed).exclude(sender=request.user).count()

    return render(request, 'deal/chat_list.html', {'rooms': rooms})

    # 2. 안 읽은 메시지 개수 카운트 로직 (기존 유지)
    for room in rooms:
        if request.user == room.buyer:
            room.unread_count = room.messages.filter(timestamp__gt=room.buyer_last_viewed).exclude(sender=request.user).count()
        else:
            room.unread_count = room.messages.filter(timestamp__gt=room.seller_last_viewed).exclude(sender=request.user).count()

    return render(request, 'deal/chat_list.html', {'rooms': rooms})

@login_required(login_url='accounts:login')
def deal_chat_leave(request, room_id):
    """채팅방 나가기 처리 함수"""
    room = get_object_or_404(ChatRoom, id=room_id)
    
    if request.user == room.buyer:
        room.buyer_left = True
    elif request.user == room.seller:
        room.seller_left = True
    else:
        return redirect('deal:deal_chat_list')
        
    # 둘 다 나갔다면 DB에서 안전하게 영구 삭제 (메시지도 종속 삭제됨)
    if room.buyer_left and room.seller_left:
        room.delete()
    else:
        room.save()
        
    return redirect('deal:deal_chat_list')

@login_required
@require_POST
def change_goods_status_ajax(request, goods_id):
    goods = get_object_or_404(Goods, id=goods_id)
    
    # 판매자 본인인지 검증 원칙
    if goods.seller != request.user:
        return JsonResponse({'status': 'error', 'message': '권한이 없습니다.'}, status=403)
        
    status = request.POST.get('status')
    if status in ['sale', 'reserved', 'sold']:
        goods.status = status
        goods.save()
        return JsonResponse({'status': 'success', 'current_status': status})

    return JsonResponse({'status': 'error', 'message': '잘못된 상태 값입니다.'}, status=400)

@login_required
@require_POST
def toggle_wishlist(request, goods_id):
    goods = get_object_or_404(Goods, id=goods_id)

    wishlist_item = Wishlist.objects.filter(user=request.user, goods=goods).first()
    if wishlist_item:
        wishlist_item.delete()
        wishlisted = False
    else:
        Wishlist.objects.create(user=request.user, goods=goods)
        wishlisted = True

    wishlist_count = Wishlist.objects.filter(goods=goods).count()
    return JsonResponse({'status': 'success', 'wishlisted': wishlisted, 'wishlist_count': wishlist_count})

@login_required(login_url='accounts:login')
def deal_wishlist(request):
    wishlist_items = Wishlist.objects.filter(user=request.user).select_related('goods')
    return render(request, 'deal/deal_wishlist.html', {
        'wishlist_items': wishlist_items
    })