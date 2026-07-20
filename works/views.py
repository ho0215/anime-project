from django.db import models
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.http import HttpResponseRedirect
from django.urls import reverse
from .models import CreativeWork, WorkImage
from django.core.exceptions import PermissionDenied
import re

def clean_content(text):
    """줄 앞뒤 공백 제거 + 연속된 빈 줄은 최대 1줄로 정리"""
    if not text:
        return text
    lines = [line.strip() for line in text.splitlines()]
    text = '\n'.join(lines)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()

# 1. 메인 갤러리 / 게시판 목록 (필터 및 정렬 기능 고도화)
def work_list(request):
    category = request.GET.get('category', 'all')
    sort = request.GET.get('sort', 'latest') # latest: 최신순, popular: 조회수순, likes: 추천순
    search_query = request.GET.get('search', '') # 원작명 검색용
    
    works = CreativeWork.objects.filter(status='published', is_public=True)

    # 1차 필터링: 카테고리
    if category != 'all':
        works = works.filter(category=category)

    # 2차 필터링: 원작 작품명 검색
    if search_query:
        works = works.filter(target_program__icontains=search_query)

    # 3차 정렬
    if sort == 'popular':
        works = works.order_by('-views', '-created_at')
    elif sort == 'likes':
        works = works.annotate(like_count=models.Count('likes')).order_by('-like_count', '-created_at')
    else:
        works = works.order_by('-created_at')

    context = {
        'works': works,
        'current_category': category,
        'current_sort': sort,
        'search_query': search_query,
    }
    return render(request, 'works/work_list.html', context)

# 2. 상세 페이지 (상세 진입 시 조회수 증가 로직 포함, 댓글 관련 기능은 완전 배제)
def work_detail(request, pk):
    work = get_object_or_404(CreativeWork, pk=pk)
    
    # 조회수 증가 (단순 새로고침 증가 방지를 엄격히 하려면 세션을 써야 하지만 기본 로직 적용)
    work.views += 1
    work.save(update_fields=['views'])
    
    # 현재 유저가 좋아요/북마크를 눌렀는지 여부 체크
    is_liked = False
    is_bookmarked = False
    if request.user.is_authenticated:
        if work.likes.filter(id=request.user.id).exists():
            is_liked = True
        if work.bookmarks.filter(id=request.user.id).exists():
            is_bookmarked = True
            
    is_author = request.user.is_authenticated and request.user == work.author
    context = {
        'work': work,
        'is_liked': is_liked,
        'is_bookmarked': is_bookmarked,
        'is_author': is_author,
    }
    return render(request, 'works/work_detail.html', context)

# 3. 2차 창작물 업로드 (로그인 필수)
@login_required
def work_create(request):
    if request.method == 'POST':
        action = request.POST.get('action', 'publish')
        target_program = request.POST.get('target_program')
        category = request.POST.get('category')
        title = request.POST.get('title')
        content = clean_content(request.POST.get('content'))
        image = request.FILES.get('image')

        # 코스프레/일러스트는 '게시'할 때 사진 필수 (임시저장은 예외)
        if category != 'novel' and action == 'publish' and not image:
            return render(request, 'works/work_form.html', {
                'error': '코스프레/일러스트는 사진을 첨부해야 게시할 수 있어요.',
                'target_program': target_program,
                'category': category,
                'title': title,
                'content': content,
            })

        work = CreativeWork.objects.create(
            target_program=target_program,
            category=category,
            title=title,                                       
            content=content,
            image=image,
            author=request.user,
            status='draft' if action == 'draft' else 'published',
        )
        extra_images = request.FILES.getlist('extra_images')
        for img in extra_images:
            WorkImage.objects.create(work=work, image=img)

        return redirect('works:work_detail', pk=work.pk)

    return render(request, 'works/work_form.html')

# 4. [기능] 좋아요 토글 (댓글 대신 리액션할 수 있는 시스템)
@login_required
def work_like(request, pk):
    work = get_object_or_404(CreativeWork, pk=pk)
    if work.likes.filter(id=request.user.id).exists():
        work.likes.remove(request.user)
    else:
        work.likes.add(request.user)
    return HttpResponseRedirect(reverse('works:work_detail', args=[pk]))

# 5. [기능] 북마크 토글 (마음에 드는 창작물 저장)
@login_required
def work_bookmark(request, pk):
    work = get_object_or_404(CreativeWork, pk=pk)
    if work.bookmarks.filter(id=request.user.id).exists():
        work.bookmarks.remove(request.user)
    else:
        work.bookmarks.add(request.user)
    return HttpResponseRedirect(reverse('works:work_detail', args=[pk]))

# 6. [기능] 게시글 수정 (작성자 본인만 가능)
@login_required
def work_update(request, pk):
    work = get_object_or_404(CreativeWork, pk=pk)

    if request.user != work.author:
        raise PermissionDenied("본인이 작성한 글만 수정할 수 있습니다.")

    if request.method == 'POST':
        action = request.POST.get('action', 'publish')
        category = request.POST.get('category')
        image = request.FILES.get('image')

        # 코스프레/일러스트는 '게시'할 때 사진 필수 (새 이미지도 없고 기존 이미지도 없으면 막음)
        if category != 'novel' and action == 'publish' and not image and not work.image:
            return render(request, 'works/work_form.html', {
                'work': work,
                'error': '코스프레/일러스트는 사진을 첨부해야 게시할 수 있어요.',
            })

        work.target_program = request.POST.get('target_program')
        work.category = category
        work.title = request.POST.get('title')
        work.content = clean_content(request.POST.get('content'))
        work.status = 'draft' if action == 'draft' else 'published'

        if image:
            work.image = image
        work.save()

        extra_images = request.FILES.getlist('extra_images')
        for img in extra_images:
            WorkImage.objects.create(work=work, image=img)

        return redirect('works:work_detail', pk=work.pk)

    return render(request, 'works/work_form.html', {'work': work})


# 7. [기능] 게시글 삭제 (작성자 본인만 가능, 삭제 전 확인 페이지 표시)
@login_required
def work_delete(request, pk):
    work = get_object_or_404(CreativeWork, pk=pk)

    if request.user != work.author:
        raise PermissionDenied("본인이 작성한 글만 삭제할 수 있습니다.")

    if request.method == 'POST':
        work.delete()
        return redirect('works:work_list')

    return render(request, 'works/work_confirm_delete.html', {'work': work})

# 8. [기능] 임시저장 목록 (나의 활동 - 임시저장)
@login_required
def my_drafts(request):
    drafts = CreativeWork.objects.filter(author=request.user, status='draft').order_by('-updated_at')
    return render(request, 'works/my_drafts.html', {'drafts': drafts})


# 9. [기능] 내 게시글 보관함 (게시했다가 나만 보기로 전환한 글)
@login_required
def my_archive(request):
    archived = CreativeWork.objects.filter(author=request.user, status='published', is_public=False).order_by('-updated_at')
    return render(request, 'works/my_archive.html', {'archived': archived})


# 10. [기능] 관심목록 (내가 북마크한 다른 회원의 글)
@login_required
def my_interests(request):
    interests = request.user.bookmarked_works.all().order_by('-created_at')
    return render(request, 'works/my_interests.html', {'interests': interests})


# 11. [기능] 공개 / 나만보기 전환 (작성자 본인만 가능)
@login_required
def work_toggle_visibility(request, pk):
    work = get_object_or_404(CreativeWork, pk=pk)

    if request.user != work.author:
        raise PermissionDenied("본인이 작성한 글만 전환할 수 있습니다.")

    work.is_public = not work.is_public
    work.save(update_fields=['is_public'])
    return redirect('works:work_detail', pk=work.pk)
