from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.shortcuts import render, redirect, get_object_or_404
from django.db.models import Count, Q, Case, When, Value, IntegerField
from django.core.paginator import Paginator
from django.core.exceptions import PermissionDenied
from django.utils import timezone
from datetime import timedelta
from .models import Post, Comment
from .forms import PostForm
from .forms import CommentForm

def board_list(request):
    board_type = request.GET.get('board_type', 'all')
    
    per_page = request.GET.get('per_page', '15')
    try:
        per_page = int(per_page)
    except ValueError:
        per_page = 15
    
    search_query = request.GET.get('q', '')
    
    if board_type == 'all':
        posts = (Post.objects.all()
                 .annotate(
                     like_count=Count('likes', distinct=True),
                     comment_count=Count('comments', distinct=True),
                     priority=Case(
                         When(board_type='notice', then=Value(0)),
                         default=Value(1),
                         output_field=IntegerField(),
                     )
                 )
                 .order_by('priority', '-created_at'))
    else:
        posts = (Post.objects.filter(board_type=board_type)
                 .annotate(
                     like_count=Count('likes', distinct=True),
                     comment_count=Count('comments', distinct=True)
                 )
                 .order_by('-created_at'))
        
    if search_query:
        posts = posts.filter(
            Q(title__icontains=search_query) |         
            Q(content__icontains=search_query) |       
            Q(author__username__icontains=search_query) 
        )
        
    paginator = Paginator(posts, per_page)
    page_number = request.GET.get('page', '1')
    page_obj = paginator.get_page(page_number)

    notices = (Post.objects.filter(board_type='notice')
                .annotate(
                    like_count=Count('likes', distinct=True),
                    comment_count=Count('comments', distinct=True)
                )
                .order_by('-created_at')[:3])

    time_threshold = timezone.now() - timedelta(hours=24)
    
    realtime_best = (Post.objects.filter(created_at__gte=time_threshold)
                     .annotate(comment_count=Count('comments', distinct=True))
                     .order_by('-view_count')[:5])
    
    hot_discussion = (Post.objects.filter(created_at__gte=time_threshold)
                      .annotate(comment_count=Count('comments', distinct=True))
                      .order_by('-comment_count')[:5])
    
    waiting_questions = (Post.objects.filter(board_type='qna')
                         .annotate(comment_count=Count('comments', distinct=True))
                         .filter(comment_count=0)
                         .order_by('-created_at')[:5])

    return render(request, 'community/list.html', {
        'posts': page_obj,
        'notices': notices,
        'current_type': board_type,
        'per_page': per_page,
        'search_query': search_query,
        'realtime_best': realtime_best,
        'hot_discussion': hot_discussion,
        'waiting_questions': waiting_questions,
    })
    
    
def post_detail(request, pk):
    post = get_object_or_404(Post, pk=pk)
    
    if request.method == 'POST':
        if not request.user.is_authenticated:
            return redirect('accounts:login') 
            
        comment_form = CommentForm(request.POST)
        if comment_form.is_valid():
            comment = comment_form.save(commit=False)
            comment.post = post
            comment.author = request.user
            
            parent_id = request.POST.get('parent_id')
            if parent_id:
                parent_comment = get_object_or_404(Comment, pk=parent_id)
                comment.parent_comment = parent_comment
                
            comment.save()
            
            comments = post.comments.filter(parent_comment__isnull=True)
            return render(request, 'community/detail.html', {
                'post': post,
                'comments': comments,
                'comment_form': CommentForm(),
            })
    
    if not request.headers.get('x-requested-with') == 'XMLHttpRequest':
        post.view_count += 1 
        post.save()

    comments = post.comments.filter(parent_comment__isnull=True)
    comment_form = CommentForm()
        
    context = {
        'post': post,
        'comments': comments,
        'comment_form': comment_form,
    }
    return render(request, 'community/detail.html', context)


@login_required
def post_create(request):
    if request.method == 'POST':
        board_type = request.POST.get('board_type')

        if board_type == 'notice' and not request.user.is_staff:
            messages.error(request, '공지 사항은 관리자만 작성할 수 있습니다. 카테고리를 다시 선택해 주세요.')
            return redirect('community:post_create')

        Post.objects.create(
            board_type=board_type,
            title=request.POST.get('title'),
            content=request.POST.get('content'), 
            author=request.user,
            image=request.FILES.get('image'),
        )
        return redirect('community:board_list')

    form = PostForm()
    return render(request, 'community/post_form.html', {'form': form})


@login_required
def post_like(request, pk):
    post = get_object_or_404(Post, pk=pk)
    
    if post.likes.filter(id=request.user.id).exists():
        post.likes.remove(request.user)
    else:
        post.likes.add(request.user)
        
    if request.headers.get('x-requested-with') == 'XMLHttpRequest' or request.accepts('text/html'):
        comments = post.comments.filter(parent_comment__isnull=True)
        comment_form = CommentForm()
        return render(request, 'community/detail.html', {'post': post, 'comments': comments, 'comment_form': comment_form})
        
    return redirect('community:post_detail', pk=post.pk)


@login_required
def post_delete(request, pk):
    post = get_object_or_404(Post, pk=pk)
    
    if request.user != post.author:
        messages.error(request, '본인이 작성한 글만 삭제할 수 있습니다.')
        return redirect('community:post_detail', pk=post.pk)
        
    post.delete()
    messages.success(request, '게시글이 성공적으로 삭제되었습니다.')
    return redirect('community:board_list')


@login_required
def post_edit(request, pk):
    """게시글 수정 기능"""
    post = get_object_or_404(Post, pk=pk)
    
    if request.user != post.author:
        messages.error(request, '본인이 작성한 글만 수정할 수 있습니다.')
        return redirect('community:post_detail', pk=post.pk)
        
    if request.method == 'POST':
        post.board_type = request.POST.get('board_type')
        post.title = request.POST.get('title')
        post.content = request.POST.get('content')
        
        if request.FILES.get('image'):
            post.image = request.FILES.get('image')
            
        if request.POST.get('clear_image') == 'true':
            if post.image:
                post.image.delete(save=False) 
            post.image = None

        post.save() 
        messages.success(request, '게시글이 성공적으로 수정되었습니다.')
        return redirect('community:post_detail', pk=post.pk)
        
    else:
        form = PostForm(instance=post)
        
    return render(request, 'community/post_form.html', {
        'form': form, 
        'post': post,  
        'is_edit': True
    })


@login_required(login_url='accounts:login')
def comment_edit(request, comment_id):
    comment = get_object_or_404(Comment, id=comment_id)
    
    if comment.author != request.user:
        raise PermissionDenied
        
    if request.method == 'POST':
        content = request.POST.get('content')
        if content:
            comment.content = content
            comment.is_updated = True 
            comment.save()
            messages.success(request, '댓글이 수정되었습니다.')
            
    post = comment.post
    comments = post.comments.filter(parent_comment__isnull=True)
    return render(request, 'community/detail.html', {
        'post': post,
        'comments': comments,
        'comment_form': CommentForm(),
    })


@login_required(login_url='accounts:login')
def comment_delete(request, comment_id):
    comment = get_object_or_404(Comment, id=comment_id)
    post = comment.post
    
    if comment.author != request.user and not request.user.is_superuser and not request.user.is_staff:
        raise PermissionDenied
        
    comment.delete()
    messages.success(request, '댓글이 삭제되었습니다.')
    
    comments = post.comments.filter(parent_comment__isnull=True)
    return render(request, 'community/detail.html', {
        'post': post,
        'comments': comments,
        'comment_form': CommentForm(),
    })