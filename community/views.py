from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect, get_object_or_404
from .models import Post
from .forms import PostForm  # 1번에서 만든 폼 임포트

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
    # 기존 detail.html 가이드 변수명(views)에 맞춰 view_count 대신 views 사용
    # 만약 DB 모델명이 view_count라면 post.view_count += 1 로 유지하셔도 됩니다.
    if hasattr(post, 'views'):
        post.views += 1
    else:
        post.view_count += 1 
    post.save()
    return render(request, 'community/detail.html', {'post': post})


@login_required
def post_create(request):
    if request.method == 'POST':
        board_type = request.POST.get('board_type')

        # 공지사항은 관리자만 작성 가능
        if board_type == 'notice' and not request.user.is_staff:
            return redirect('community:board_list')

        # 에디터 데이터를 포함한 전체 Post 생성
        Post.objects.create(
            board_type=board_type,
            title=request.POST.get('title'),
            content=request.POST.get('content'),  # CKEditor 내부 HTML 내용이 이쪽으로 들어옵니다.
            author=request.user,
            image=request.FILES.get('image'),
        )
        return redirect('community:board_list')

    # GET 요청일 때 에디터가 포함된 폼을 템플릿으로 넘겨줍니다.
    form = PostForm()
    return render(request, 'community/post_form.html', {'form': form})