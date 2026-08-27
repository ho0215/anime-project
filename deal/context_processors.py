from django.db.models import Q

from .models import ChatRoom


def deal_unread_count(request):
    """거래 채팅 안 읽은 메시지 총합 — base.html 네비게이션 배지 초기값용.

    실패해도 페이지 전체(글쓰기 포함)가 500 나지 않도록 방어한다.
    """
    try:
        if not getattr(request, "user", None) or not request.user.is_authenticated:
            return {}

        rooms = ChatRoom.objects.filter(
            (Q(buyer=request.user) & Q(buyer_left=False)) |
            (Q(seller=request.user) & Q(seller_left=False))
        )

        total = 0
        for room in rooms:
            last_viewed = (
                room.buyer_last_viewed
                if request.user == room.buyer
                else room.seller_last_viewed
            )
            if last_viewed is None:
                continue
            total += (
                room.messages.filter(timestamp__gt=last_viewed)
                .exclude(sender=request.user)
                .count()
            )

        return {"deal_unread_count": total}
    except Exception:
        return {"deal_unread_count": 0}
