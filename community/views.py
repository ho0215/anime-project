from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.shortcuts import render, redirect, get_object_or_404
from django.db.models import Count, Q, Case, When, Value, IntegerField
from django.core.paginator import Paginator
from django.core.exceptions import PermissionDenied
from django.utils import timezone  # 💡 추가: 실시간 기준 계산을 위해 임포트
from datetime import timedelta     # 💡 추가: 24시간 범위 계산을 위해 임포트
from django.http import JsonResponse # 💡 추가: 새로고침 없는 AJAX(Fetch) 통신을 위한 임포트
from django.template.loader import render_to_string # 💡 추가: HTML 조각 렌더링을 위해 임포트
from .models import Post, Comment
from .forms import PostForm  # 1번에서 만든 폼 임포트
from .forms import CommentForm

def board_list(request):
    board_type = request.GET.get('board_type', 'all')
    
    # [유저가 선택한 per_page 값을 가져옴 (기본값은 '15')]
    per_page = request.GET.get('per_page', '15')
    try:
        per_page = int(per_page)
    except ValueError:
        per_page = 15  # 잘못된 값이 들어오면 기본값 15로 처리
    
    # [URL 검색어 가져오기 (없으면 빈 문자열)]
    search_query = request.GET.get('q', '')
    
    # 💡 [DB 최적화 핵심] 
    # annotate 안에서 좋아요 개수(like_count) 뿐만 아니라 
    # 댓글 개수(comment_count)도 DB 단계에서 한꺼번에 미리 계산해옵니다.
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
                 .order_by('priority', '-created_at')) # 공지사항 우선 정렬 후, 최신순 정렬
    else:
        posts = (Post.objects.filter(board_type=board_type)
                 .annotate(
                     like_count=Count('likes', distinct=True),
                     comment_count=Count('comments', distinct=True)
                 )
                 .order_by('-created_at'))
        
    # [검색어가 입력되었다면 전체 글 또는 카테고리 내에서 Q 객체로 필터링]
    if search_query:
        posts = posts.filter(
            Q(title__icontains=search_query) |          # 제목 검색
            Q(content__icontains=search_query) |        # 내용 검색
            Q(author__username__icontains=search_query) # 작성자 이름 검색
        )
        
    # [장고 Paginator를 이용한 페이징 처리]
    paginator = Paginator(posts, per_page)
    page_number = request.GET.get('page', '1')
    page_obj = paginator.get_page(page_number)

    # 공지사항 목록에도 좋아요 개수와 댓글 수를 똑같이 계산해서 넘깁니다.
    notices = (Post.objects.filter(board_type='notice')
                .annotate(
                    like_count=Count('likes', distinct=True),
                    comment_count=Count('comments', distinct=True)
                )
                .order_by('-created_at')[:3])

    # ----------------------------------------------------
    # 💡 [여기서부터 사이드바용 데이터 추가 영역]
    # ----------------------------------------------------
    # 최근 24시간 기준 시간 설정
    time_threshold = timezone.now() - timedelta(hours=24)
    
    # 1. 실시간 베스트: 최근 24시간 내 글 중 조회수(view_count) 순 정렬 (5개)
    realtime_best = (Post.objects.filter(created_at__gte=time_threshold)
                     .annotate(comment_count=Count('comments', distinct=True))
                     .order_by('-view_count')[:5])
    
    # 2. 지금 핫한 토론: 최근 24시간 내 댓글이 많이 달린 글 순 정렬 (5개)
    hot_discussion = (Post.objects.filter(created_at__gte=time_threshold)
                      .annotate(comment_count=Count('comments', distinct=True))
                      .order_by('-comment_count')[:5])
    
    # 3. 답변을 기다려요: 카테고리가 '질문'(혹은 qna)이면서 댓글이 0개인 최신글 (5개)
    waiting_questions = (Post.objects.filter(board_type='질문')
                         .annotate(comment_count=Count('comments', distinct=True))
                         .filter(comment_count=0)
                         .order_by('-created_at')[:5])
    # ----------------------------------------------------

    return render(request, 'community/list.html', {
        'posts': page_obj,          # 기존 쿼리셋 대신 페이징 객체(page_obj)를 넘겨줍니다.
        'notices': notices,
        'current_type': board_type,
        'per_page': per_page,       # 템플릿에서 현재 몇 개씩 보기인지 유지하기 위해 전달
        'search_query': search_query, # 템플릿 검색창에 검색어를 유지하기 위해 전달
        
        # 💡 [컨텍스트에 사이드바 데이터 추가]
        'realtime_best': realtime_best,
        'hot_discussion': hot_discussion,
        'waiting_questions': waiting_questions,
    })
    
    
def post_detail(request, pk):
    post = get_object_or_404(Post, pk=pk)
    
    # 💡 비동기(Fetch) 댓글 등록 요청일 경우 조회수를 증가시키지 않음
    if request.method == 'GET':
        post.view_count += 1 
        post.save()

    # 대댓글이 아닌 원댓글만 1차로 가져오기
    comments = post.comments.filter(parent_comment__isnull=True)
    
    if request.method == 'POST':
        is_ajax = request.headers.get('x-requested-with') == 'XMLHttpRequest' or 'application/json' in request.headers.get('Accept', '')
        
        # 1. 로그인 인증 확인
        if not request.user.is_authenticated:
            if is_ajax:
                return JsonResponse({'error': 'unauthenticated'}, status=401)
            return redirect('login') 
            
        # 2. 💡 [핵심 수정] 검증 에러를 유발하는 Form을 사용하지 않고 POST 데이터를 직접 수집
        content = request.POST.get('content', '').strip()
        parent_id = request.POST.get('parent_id')
        
        if not content:
            if is_ajax:
                return JsonResponse({'status': 'fail', 'message': '내용을 입력해주세요.'}, status=400)
            return redirect('community:post_detail', pk=post.id)
            
        # 3. 모델에 직접 값 대입 후 저장
        comment = Comment()
        comment.post = post
        comment.author = request.user
        comment.content = content
        
        if parent_id:
            parent_comment = get_object_or_404(Comment, pk=parent_id)
            comment.parent_comment = parent_comment
            
        comment.save()
        
        # 4. 비동기 요청 분기 처리
        if is_ajax:
            # 렌더링 시 request 객체를 전달하여 템플릿 내 권한 분기({% if request.user == ... %}) 정상 동작 보장
            comment_html = render_to_string('community/comment_item.html', {
                'comment': comment, 
                'user': request.user,
                'request': request
            })
            return JsonResponse({
                'status': 'success',
                'comment_html': comment_html,
                'total_comments': post.comments.count()
            })
            
        return redirect('community:post_detail', pk=post.id)
    else:
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

        # 공지사항은 관리자만 작성 가능
        if board_type == 'notice' and not request.user.is_staff:
            messages.error(request, '공지 사항은 관리자만 작성할 수 있습니다. 카테고리를 다시 선택해 주세요.')
            return redirect('community:post_create')

        # 에디터 데이터를 포함한 전체 Post 생성
        Post.objects.create(
            board_type=board_type,
            title=request.POST.get('title'),
            content=request.POST.get('content'),  # CKEditor 내부 HTML 내용이 이쪽으로 들어옵니다.
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
        liked = False
    else:
        post.likes.add(request.user)
        liked = True
        
    return JsonResponse({
        'liked': liked,
        'like_count': post.likes.count()
    })


@login_required
def post_delete(request, pk):
    """게시글 삭제 기능"""
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
    """댓글 수정 기능"""
    comment = get_object_or_404(Comment, id=comment_id)
    
    if comment.author != request.user:
        raise PermissionDenied
        
    if request.method == 'POST':
        content = request.POST.get('content')
        if content:
            comment.content = content
            comment.is_updated = True 
            comment.save()
            
            # 💡 비동기(AJAX) 요청일 경우 JSON 응답 반환
            if request.headers.get('x-requested-with') == 'XMLHttpRequest':
                return JsonResponse({
                    'status': 'success',
                    'content': comment.content
                })
                
            messages.success(request, '댓글이 수정되었습니다.')
            
    return redirect('community:post_detail', pk=comment.post.pk)


@login_required(login_url='accounts:login')
def comment_delete(request, comment_id):
    """댓글 삭제 기능"""
    comment = get_object_or_404(Comment, id=comment_id)
    post = comment.post
    
    if comment.author != request.user and not request.user.is_superuser and not request.user.is_staff:
        raise PermissionDenied
        
    comment.delete()
    
    # 💡 비동기(AJAX) 요청일 경우 새로고침 대신 남은 전체 댓글 수 JSON 반환
    if request.headers.get('x-requested-with') == 'XMLHttpRequest':
        return JsonResponse({
            'status': 'success',
            'total_comments': post.comments.count()
        })
        
    messages.success(request, '댓글이 삭제되었습니다.')
    return redirect('community:post_detail', pk=post.pk)