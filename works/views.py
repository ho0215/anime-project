from django.db import models
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.http import HttpResponseRedirect
from django.urls import reverse
from .models import CreativeWork, WorkImage
from django.core.exceptions import PermissionDenied

# 1. 메인 갤러리 / 게시판 목록 (필터 및 정렬 기능 고도화)
def work_list(request):
    category = request.GET.get('category', 'all')
    sort = request.GET.get('sort', 'latest') # latest: 최신순, popular: 조회수순, likes: 추천순
    search_query = request.GET.get('search', '') # 원작명 검색용

    # 1차 필터링: 카테고리
    if category != 'all':
        works = CreativeWork.objects.filter(category=category)
    else:
        works = CreativeWork.objects.all()

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

    context = {
        'work': work,
        'is_liked': is_liked,
        'is_bookmarked': is_bookmarked,
    }
    return render(request, 'works/work_detail.html', context)

# 3. 2차 창작물 업로드 (로그인 필수)
@login_required
def work_create(request):
    if request.method == 'POST':
        target_program = request.POST.get('target_program')
        category = request.POST.get('category')
        title = request.POST.get('title')
        content = request.POST.get('content')
        image = request.FILES.get('image')

        work = CreativeWork.objects.create(
            target_program=target_program,
            category=category,
            title=title,
            content=content,
            image=image,
            author=request.user
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
        work.target_program = request.POST.get('target_program')
        work.category = request.POST.get('category')
        work.title = request.POST.get('title')
        work.content = request.POST.get('content')

        image = request.FILES.get('image')
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