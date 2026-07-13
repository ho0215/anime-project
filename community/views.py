from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect, get_object_or_404
from .models import Post


# Create your views here.
def board_list(request):
    board_type = request.GET.get('board_type', 'all')
    
    if board_type == 'all':
        posts = Post.objects.exclude(board_type='notice').order_by('-created_at')
    else:
        posts = Post.objects.filter(board_type=board_type).order_by('-created_at')

    # 공지사항은 항상 상단에 별도로 보여줌
    notices = Post.objects.filter(board_type='notice').order_by('-created_at')[:3]

    return render(request, 'community/list.html', {
        'posts': posts,
        'notices': notices,
        'current_type': board_type,
    })


def post_detail(request, pk):
    post = get_object_or_404(Post, pk=pk)
    post.view_count += 1
    post.save()
    return render(request, 'community/detail.html', {'post': post})


@login_required
def post_create(request):
    if request.method == 'POST':
        board_type = request.POST['board_type']

        # 공지사항은 관리자만 작성 가능
        if board_type == 'notice' and not request.user.is_staff:
            return redirect('board_list')

        Post.objects.create(
            board_type=board_type,
            title=request.POST['title'],
            content=request.POST['content'],
            author=request.user,
            image=request.FILES.get('image'),
        )
        return redirect('board_list')

    return render(request, 'community/post_form.html')