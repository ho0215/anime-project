from django.db.models import Q

from .models import ChatRoom


def deal_unread_count(request):
    """거래 채팅 안 읽은 메시지 총합 — base.html 네비게이션 배지 초기값용."""
    if not request.user.is_authenticated:
        return {}

    rooms = ChatRoom.objects.filter(
        (Q(buyer=request.user) & Q(buyer_left=False)) |
        (Q(seller=request.user) & Q(seller_left=False))
    )

    total = 0
    for room in rooms:
        last_viewed = room.buyer_last_viewed if request.user == room.buyer else room.seller_last_viewed
        total += room.messages.filter(timestamp__gt=last_viewed).exclude(sender=request.user).count()

    return {'deal_unread_count': total}
