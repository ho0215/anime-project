from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.contrib import messages
from django.core.exceptions import PermissionDenied
from django.urls import reverse
from django.utils import timezone
from datetime import timedelta
from django.db.models import Q, Max, F
from .models import Goods, ChatRoom, Message, Wishlist, GoodsReport, UserReport
from django.http import JsonResponse
from django.views.decorators.http import require_POST

def deal_board(request):
    category_slug = request.GET.get('category')
    search_query = request.GET.get('q', '').strip()
    available_only = request.GET.get('available_only') == '1'

    # 기본 쿼리셋 선언
    goods_list = Goods.objects.all()

    # 1. 카테고리 필터링
    if category_slug:
        goods_list = goods_list.filter(category=category_slug)

    # 2. 검색어 필터링
    if search_query:
        goods_list = goods_list.filter(
            Q(title__icontains=search_query) |
            Q(description__icontains=search_query) |
            Q(anime_title__icontains=search_query) 
        )

    # 2-1. 판매완료 상품 제외 (판매중만 보기 체크 시)
    if available_only:
        goods_list = goods_list.filter(status__in=['sale', 'reserved'])

    # 3. 최신순 정렬
    goods_list = goods_list.order_by('-created_at')
        
    # 4. 시간 표시 가공
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
        'search_query': search_query,
        'available_only': available_only
    })


@login_required(login_url='accounts:login')
def deal_add(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        category = request.POST.get('category')
        
        anime_title = request.POST.get('anime_title') or request.POST.get('tag')
        if not anime_title:
            anime_title = "기타 장르"
            
        price = request.POST.get('price', 0)
        description = request.POST.get('description') or request.POST.get('content')
        
        shipping_list = request.POST.getlist('shipping') or request.POST.getlist('delivery')
        shipping_methods = ", ".join(shipping_list) if shipping_list else "협의 가능"
        
        # 🔥 수정된 부분: HTML의 name="image"와 이름 일치시키기!
        uploaded_files = request.FILES.getlist('image')
        main_image = uploaded_files[0] if uploaded_files else None

        # DB 저장
        Goods.objects.create(
            seller=request.user,
            title=title,
            category=category,
            anime_title=anime_title,
            price=int(price) if price else 0,
            shipping_methods=shipping_methods,
            description=description if description else "내용 없음",
            image=main_image,
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


# 2. 판매글 수정 페이지 뷰
@login_required(login_url='accounts:login')
def deal_edit(request, goods_id):
    goods = get_object_or_404(Goods, id=goods_id)

    if goods.seller != request.user:
        raise PermissionDenied

    if request.method == 'POST':
        goods.title = request.POST.get('title')
        goods.category = request.POST.get('category')
        goods.anime_title = request.POST.get('anime_title') or request.POST.get('tag')
        goods.price = request.POST.get('price', 0)
        goods.shipping_methods = request.POST.get('delivery')
        goods.description = request.POST.get('content')
        goods.status = request.POST.get('status') 

        # 🔥 수정된 부분: 여기도 'image'로 일치시키기
        if request.FILES.get('image'):
            goods.image = request.FILES.get('image')

        goods.save()
        
        return redirect('deal:deal_detail', goods_id=goods.id)

    return render(request, 'deal/deal_edit.html', {
        'goods': goods
    })


# 3. 판매글 삭제 처리 뷰
@login_required(login_url='accounts:login')
def deal_delete(request, goods_id):
    if request.method == 'POST':
        goods = get_object_or_404(Goods, id=goods_id)

        if goods.seller != request.user:
            raise PermissionDenied

        goods.delete()
        
        return redirect('deal:deal_board')
    
    return redirect('deal:deal_detail', goods_id=goods_id)


@login_required(login_url='accounts:login')
def deal_chat_start(request, goods_id):
    """'채팅 문의하기' 클릭 시 방을 조회하거나 생성하고 이동시키는 뷰"""
    goods = get_object_or_404(Goods, id=goods_id)
    buyer = request.user
    seller = goods.seller

    if buyer == seller:
        return redirect('deal:deal_detail', goods_id=goods.id)

    if goods.status == 'sold':
        return redirect('deal:deal_detail', goods_id=goods.id)

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
    rooms = ChatRoom.objects.filter(
        (Q(buyer=request.user) & Q(buyer_left=False)) |
        (Q(seller=request.user) & Q(seller_left=False))
    ).annotate(
        latest_message_time=Max('messages__timestamp')
    ).order_by('-latest_message_time', '-created_at')

    # 중복으로 들어있던 코드를 깔끔하게 1번만 실행되도록 정리했습니다.
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
        
    if room.buyer_left and room.seller_left:
        room.delete()
    else:
        room.save()
        
    return redirect('deal:deal_chat_list')


@login_required
@require_POST
def change_goods_status_ajax(request, goods_id):
    goods = get_object_or_404(Goods, id=goods_id)
    
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


@login_required(login_url='accounts:login')
def deal_goods_report(request, goods_id):
    """상품(굿즈) 신고 폼 표시 및 접수 처리"""
    goods = get_object_or_404(Goods, id=goods_id)

    # 본인 상품은 신고 불가
    if goods.seller == request.user:
        messages.error(request, '본인이 등록한 상품은 신고할 수 없습니다.')
        return redirect('deal:deal_detail', goods_id=goods.id)

    # 이미 신고한 상품이면 재신고 불가
    if GoodsReport.objects.filter(reporter=request.user, goods=goods).exists():
        messages.error(request, '이미 신고한 상품입니다.')
        return redirect('deal:deal_detail', goods_id=goods.id)

    if request.method == 'POST':
        reason = request.POST.get('reason')
        if reason not in dict(GoodsReport.REASON_CHOICES):
            messages.error(request, '신고 사유를 선택해 주세요.')
            return redirect('deal:deal_goods_report', goods_id=goods.id)

        GoodsReport.objects.create(
            reporter=request.user,
            goods=goods,
            reason=reason,
            detail=request.POST.get('detail', ''),
        )
        messages.success(request, '신고가 접수되었습니다.')
        return redirect('deal:deal_detail', goods_id=goods.id)

    return render(request, 'deal/goods_report_form.html', {
        'goods': goods,
        'reason_choices': GoodsReport.REASON_CHOICES,
    })


@login_required(login_url='accounts:login')
def deal_user_report(request, username):
    """유저(프로필 단위) 신고 폼 표시 및 접수 처리"""
    reported_user = get_object_or_404(User, username=username)
    next_url = request.POST.get('next') or request.GET.get('next') or reverse('deal:deal_board')

    # 본인 신고 불가
    if reported_user == request.user:
        messages.error(request, '본인을 신고할 수 없습니다.')
        return redirect(next_url)

    # 이미 신고한 유저면 재신고 불가
    if UserReport.objects.filter(reporter=request.user, reported_user=reported_user).exists():
        messages.error(request, '이미 신고한 유저입니다.')
        return redirect(next_url)

    if request.method == 'POST':
        reason = request.POST.get('reason')
        if reason not in dict(UserReport.REASON_CHOICES):
            messages.error(request, '신고 사유를 선택해 주세요.')
            return redirect(f"{reverse('deal:deal_user_report', kwargs={'username': reported_user.username})}?next={next_url}")

        UserReport.objects.create(
            reporter=request.user,
            reported_user=reported_user,
            reason=reason,
            detail=request.POST.get('detail', ''),
        )
        messages.success(request, '신고가 접수되었습니다.')
        return redirect(next_url)

    return render(request, 'deal/user_report_form.html', {
        'reported_user': reported_user,
        'next_url': next_url,
        'reason_choices': UserReport.REASON_CHOICES,
    })


@login_required(login_url='accounts:login')
def deal_my_reports(request):
    """내가 제출한 신고 내역(상품/유저) 확인"""
    goods_reports = GoodsReport.objects.filter(reporter=request.user).select_related('goods')
    user_reports = UserReport.objects.filter(reporter=request.user).select_related('reported_user')

    return render(request, 'deal/my_reports.html', {
        'goods_reports': goods_reports,
        'user_reports': user_reports,
    })


@login_required(login_url='accounts:login')
def deal_report_list(request):
    """관리자용 전체 신고(상품/유저) 목록"""
    if not request.user.is_staff:
        raise PermissionDenied

    status_filter = request.GET.get('status', 'all')

    goods_reports = GoodsReport.objects.select_related('goods', 'reporter').order_by('-created_at')
    user_reports = UserReport.objects.select_related('reported_user', 'reporter').order_by('-created_at')

    if status_filter != 'all':
        goods_reports = goods_reports.filter(status=status_filter)
        user_reports = user_reports.filter(status=status_filter)

    return render(request, 'deal/report_list.html', {
        'goods_reports': goods_reports,
        'user_reports': user_reports,
        'status_filter': status_filter,
        'status_choices': GoodsReport.STATUS_CHOICES,
    })


@login_required
@require_POST
def update_report_status_ajax(request, report_type, report_id):
    if not request.user.is_staff:
        return JsonResponse({'status': 'error', 'message': '권한이 없습니다.'}, status=403)

    if report_type == 'goods':
        report = get_object_or_404(GoodsReport, id=report_id)
    elif report_type == 'user':
        report = get_object_or_404(UserReport, id=report_id)
    else:
        return JsonResponse({'status': 'error', 'message': '잘못된 요청입니다.'}, status=400)

    new_status = request.POST.get('status')
    if new_status not in dict(GoodsReport.STATUS_CHOICES):
        return JsonResponse({'status': 'error', 'message': '잘못된 상태 값입니다.'}, status=400)

    if new_status == 'rejected' and not request.POST.get('admin_note', '').strip():
        return JsonResponse({'status': 'error', 'message': '반려 사유를 입력해 주세요.'}, status=400)

    report.status = new_status
    report.admin_note = request.POST.get('admin_note', '').strip()
    report.save()
    return JsonResponse({'status': 'success', 'current_status': new_status})