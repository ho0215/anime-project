from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.shortcuts import render, redirect, get_object_or_404
from django.db.models import Count, Q
from django.core.paginator import Paginator
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
        posts = (Post.objects.exclude(board_type='notice')
                 .annotate(
                     like_count=Count('likes', distinct=True),
                     comment_count=Count('comments', distinct=True) # 👈 댓글 수 추가!
                 )
                 .order_by('-created_at'))
    else:
        posts = (Post.objects.filter(board_type=board_type)
                 .annotate(
                     like_count=Count('likes', distinct=True),
                     comment_count=Count('comments', distinct=True) # 👈 댓글 수 추가!
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
                   comment_count=Count('comments', distinct=True) # 👈 공지사항 댓글 수 추가!
               )
               .order_by('-created_at')[:3])

    return render(request, 'community/list.html', {
        'posts': page_obj,          # 기존 쿼리셋 대신 페이징 객체(page_obj)를 넘겨줍니다.
        'notices': notices,
        'current_type': board_type,
        'per_page': per_page,       # 템플릿에서 현재 몇 개씩 보기인지 유지하기 위해 전달
        'search_query': search_query, # 템플릿 검색창에 검색어를 유지하기 위해 전달
    })
    
    
def post_detail(request, pk):
    post = get_object_or_404(Post, pk=pk)
    
    # 조회수 증가
    post.view_count += 1 
    post.save()

    # 💡 [위치 수정] 이전 return문 때문에 막혔던 로직들을 위로 올렸습니다.
    # 대댓글이 아닌 원댓글만 1차로 가져오기
    comments = post.comments.filter(parent_comment__isnull=True)
    
    if request.method == 'POST':
        # 로그인한 사용자만 댓글 작성 가능하도록 안전장치 추가 (필요시 사용)
        if not request.user.is_authenticated:
            return redirect('login') # 혹은 로그인 페이지 url
            
        comment_form = CommentForm(request.POST)
        if comment_form.is_valid(): # 👈 오타 수정 (is_vaild -> is_valid)
            comment = comment_form.save(commit=False)
            comment.post = post
            comment.author = request.user
            
            # 대댓글인 경우 처리 (Form hidden input 등으로 parent_id를 넘겨받음)
            parent_id = request.POST.get('parent_id')
            if parent_id:
                parent_comment = get_object_or_404(Comment, pk=parent_id)
                comment.parent_comment = parent_comment
                
            comment.save()
            # 👈 리다이렉트 경로를 네임스페이스 규칙('community:post_detail')에 맞게 변경
            return redirect('community:post_detail', pk=post.id)
    else:
        comment_form = CommentForm()
        
    context = {
        'post': post,
        'comments': comments,
        'comment_form': comment_form,
    }
    # 👈 템플릿 경로를 다른 뷰들과 일관되게 'community/detail.html'로 통일했습니다.
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

    # GET 요청일 때 에디터가 포함된 폼을 템플릿으로 넘겨줍니다.
    form = PostForm()
    return render(request, 'community/post_form.html', {'form': form})


# 추천(좋아요) 비즈니스 로직 뷰
@login_required
def post_like(request, pk):
    post = get_object_or_404(Post, pk=pk)
    
    # 이미 로그인한 유저가 추천을 눌렀다면 관계 삭제(추천 취소), 안 눌렀다면 추가
    if post.likes.filter(id=request.user.id).exists():
        post.likes.remove(request.user)
    else:
        post.likes.add(request.user)
        
    # 추천을 완료한 후 다시 해당 게시글 상세 페이지(detail)로 이동합니다.
    return redirect('community:post_detail', pk=post.pk)