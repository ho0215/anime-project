import requests
from django.shortcuts import render, get_object_or_404, redirect
from django.core.paginator import Paginator
from django.db.models import Q
from .models import Anime, Review # 🔥 중복된 import 한 줄로 깔끔하게 정리

def anime_list(request):
    query = request.GET.get('q', '').strip()
    
    # ⚠️ 여기에 본인의 TMDB API KEY를 꼭 넣어주세요!
    API_KEY = 'fcf1e4d2533332357dde303d1d8fcf50'

    if query:
        # 1. 사용자가 검색하면 TMDB 검색 API를 먼저 호출합니다.
        url = f"https://api.themoviedb.org/3/search/tv?api_key={API_KEY}&query={query}&language=ko-KR&include_adult=false"
        
        try:
            response = requests.get(url)
            if response.status_code == 200:
                data = response.json().get('results', [])
                
                for item in data:
                    # TMDB에서 애니메이션 장르 ID는 '16'입니다. 애니메이션이 아닌 것은 제외합니다.
                    if 16 not in item.get('genre_ids', []):
                        continue
                        
                    # 이름이나 줄거리가 없으면 제외
                    if not item.get('name') or not item.get('overview'):
                        continue

                    image_path = item.get('poster_path')
                    image_url = f"https://image.tmdb.org/t/p/w500{image_path}" if image_path else "https://via.placeholder.com/500x750?text=No+Image"

                    # 2. 가져온 데이터를 우리 DB에 실시간으로 저장(또는 업데이트)합니다.
                    Anime.objects.update_or_create(
                        api_id=item['id'],
                        defaults={
                            'title': item['name'],
                            'genre': '애니메이션',
                            'synopsis': item['overview'],
                            'image_url': image_url,
                            'score': item.get('vote_average', 0.0),
                        }
                    )
        except Exception as e:
            print(f"API 호출 에러: {e}")

        # 3. API 통신이 끝난 후, 우리 DB에서 검색어를 포함한 결과를 가져와 화면에 뿌려줍니다.
        anime_list = Anime.objects.filter(
            Q(title__icontains=query) | Q(synopsis__icontains=query)
        ).order_by('-score')

    else:
        # 검색어가 없을 때는 기존처럼 DB에 저장된 전체 목록을 보여줍니다.
        anime_list = Anime.objects.all().order_by('-score')

    # 페이지네이션 (16개씩)
    paginator = Paginator(anime_list, 16)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    return render(request, 'anime/anime_list.html', {
        'page_obj': page_obj,
        'query': query,
    })

def home(request):
    # 1. 역대 최고 평점 명작 (평점이 높은 순서대로 10개)
    top_rated = Anime.objects.all().order_by('-score')[:10]
    
    # 2. 액션 & 판타지 몰아보기 (줄거리에 특정 단어가 포함된 것만 필터링)
    action_fantasy = Anime.objects.filter(
        Q(synopsis__icontains='액션') | Q(synopsis__icontains='판타지') | 
        Q(synopsis__icontains='마법') | Q(synopsis__icontains='전투')
    ).order_by('-score')[:10]
    
    # 3. 설레는 로맨스 & 청춘 (줄거리에 특정 단어가 포함된 것만 필터링)
    romance = Anime.objects.filter(
        Q(synopsis__icontains='사랑') | Q(synopsis__icontains='로맨스') | 
        Q(synopsis__icontains='학교') | Q(synopsis__icontains='청춘')
    ).order_by('-score')[:10]

    # 4. 오늘의 추천 애니 (랜덤으로 10개 섞어서 가져오기)
    random_picks = Anime.objects.all().order_by('?')[:10]

    # 🔥 home.html에서 main.html로 수정 완료
    return render(request, 'anime/main.html', {
        'top_rated': top_rated,
        'action_fantasy': action_fantasy,
        'romance': romance,
        'random_picks': random_picks,
    })

def anime_detail(request, pk):
    anime = get_object_or_404(Anime, pk=pk)
    
    if request.method == 'POST':
        score = request.POST.get('score')
        content = request.POST.get('content')
        if score and content:
            # DB에 리뷰 저장
            Review.objects.create(anime=anime, score=int(score), content=content)
            # 저장 후 새로고침 방지를 위해 상세페이지로 다시 리다이렉트
            return redirect('anime:anime_detail', pk=pk)

    # TMDB API로 해당 애니메이션의 예고편(유튜브) 영상 정보만 실시간으로 가져옵니다.
    API_KEY = 'fcf1e4d2533332357dde303d1d8fcf50'
    youtube_id = None
    
    try:
        # 1. 한국어 예고편이 있는지 먼저 검색
        video_url = f"https://api.themoviedb.org/3/tv/{anime.api_id}/videos?api_key={API_KEY}&language=ko-KR"
        response = requests.get(video_url).json()
        results = response.get('results', [])
        
        # 2. 한국어 영상이 없으면 다국어(주로 일본어/영어) 예고편으로 대체
        if not results:
            video_url_en = f"https://api.themoviedb.org/3/tv/{anime.api_id}/videos?api_key={API_KEY}"
            response_en = requests.get(video_url_en).json()
            results = response_en.get('results', [])
        
        # 3. 유튜브 영상 키 추출 (Trailer(예고편)를 가장 우선순위로 찾음)
        for video in results:
            if video.get('site') == 'YouTube':
                youtube_id = video.get('key')
                if video.get('type') == 'Trailer':
                    break
    except Exception as e:
        print("영상 가져오기 실패:", e)

    reviews = anime.reviews.all().order_by('-created_at')

    return render(request, 'anime/anime_detail.html', {
        'anime': anime,
        'youtube_id': youtube_id, # 🔥 쉼표(,) 추가 완료!
        'reviews': reviews,
    })
    
def review_delete(request, pk, review_pk):
    review = get_object_or_404(Review, pk=review_pk)
    # 현재 로그인한 사용자가 관리자(superuser)일 때만 삭제 실행
    if request.user.is_superuser:
        review.delete()
    return redirect('anime:anime_detail', pk=pk)