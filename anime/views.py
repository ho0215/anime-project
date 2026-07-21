import json
import requests
from django.http import JsonResponse
from django.shortcuts import render, get_object_or_404, redirect
from django.core.paginator import Paginator
from django.db.models import Q, Count, Avg
from google import genai
from .models import Anime, Review

def anime_list(request):
    query = request.GET.get('q', '').strip()
    sort = request.GET.get('sort', 'score')
    
    API_KEY = 'fcf1e4d2533332357dde303d1d8fcf50'

    if query:
        url = f"https://api.themoviedb.org/3/search/tv?api_key={API_KEY}&query={query}&language=ko-KR&include_adult=false"
        try:
            response = requests.get(url)
            if response.status_code == 200:
                data = response.json().get('results', [])
                for item in data:
                    if 16 not in item.get('genre_ids', []):
                        continue
                    if not item.get('name') or not item.get('overview'):
                        continue

                    image_path = item.get('poster_path')
                    image_url = f"https://image.tmdb.org/t/p/w500{image_path}" if image_path else "https://via.placeholder.com/500x750?text=No+Image"

                    Anime.objects.update_or_create(
                        api_id=item['id'],
                        defaults={
                            'title': item['name'],
                            'genre': '애니메이션',
                            'synopsis': item['overview'],
                            'image_url': image_url,
                            'score': item.get('vote_average', 0.0),
                            'first_air_date': item.get('first_air_date', ''), 
                        }
                    )
        except Exception as e:
            print(f"API 호출 에러: {e}")

        base_qs = Anime.objects.filter(Q(title__icontains=query) | Q(synopsis__icontains=query))
    else:
        base_qs = Anime.objects.all()

    if sort == 'popular':
        animes = base_qs.annotate(review_count=Count('reviews')).order_by('-review_count', '-score')
    elif sort == 'date_desc':
        animes = base_qs.order_by('-first_air_date')
    elif sort == 'date_asc':
        animes = base_qs.order_by('first_air_date')
    elif sort == 'score':
        animes = base_qs.order_by('-score', '-first_air_date')
    else:
        animes = base_qs.order_by('-score', '-first_air_date')

    paginator = Paginator(animes, 16)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    return render(request, 'anime/anime_list.html', {
        'page_obj': page_obj,
        'query': query,
        'sort': sort, 
    })

def home(request):
    top_rated = Anime.objects.all().order_by('-score')[:10]
    
    action_fantasy = Anime.objects.filter(
        Q(synopsis__icontains='액션') | Q(synopsis__icontains='판타지') | 
        Q(synopsis__icontains='마법') | Q(synopsis__icontains='전투')
    ).order_by('-score')[:10]
    
    romance = Anime.objects.filter(
        Q(synopsis__icontains='사랑') | Q(synopsis__icontains='로맨스') | 
        Q(synopsis__icontains='학교') | Q(synopsis__icontains='청춘')
    ).order_by('-score')[:10]

    random_picks = Anime.objects.all().order_by('?')[:10]

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
            Review.objects.create(anime=anime, score=int(score), content=content)
            return redirect('anime:anime_detail', pk=pk)

    API_KEY = 'fcf1e4d2533332357dde303d1d8fcf50'
    youtube_id = None
    
    try:
        video_url = f"https://api.themoviedb.org/3/tv/{anime.api_id}/videos?api_key={API_KEY}&language=ko-KR"
        response = requests.get(video_url).json()
        results = response.get('results', [])
        
        if not results:
            video_url_en = f"https://api.themoviedb.org/3/tv/{anime.api_id}/videos?api_key={API_KEY}"
            response_en = requests.get(video_url_en).json()
            results = response_en.get('results', [])
        
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
        'youtube_id': youtube_id,
        'reviews': reviews,
    })
    
def review_delete(request, pk, review_pk):
    review = get_object_or_404(Review, pk=review_pk)
    if request.user.is_superuser:
        review.delete()
    return redirect('anime:anime_detail', pk=pk)

# ----------------------------------------------------
# 🔥 추가된 제미나이 챗봇 API 뷰
# ----------------------------------------------------
def chatbot_api(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_message = data.get('message', '')

            if not user_message:
                return JsonResponse({'error': '메시지가 없습니다.'}, status=400)

            # 서버에 등록된 GEMINI_API_KEY 환경변수를 통해 인증
            client = genai.Client()
            
            # 애니메이션 사이트 콘셉트에 맞춰 프롬프트 살짝 추가 (선택사항)
            system_instruction = """너는 ANIVERSE라는 애니메이션 추천 사이트의 친절한 AI 어시스턴트야.
            사용자가 애니메이션을 물어보면 장점과 단점을 비교해서 설명해줘.
            답변은 항상 존댓말로 하고, 3~4문장으로 간결하게 대답해."""
            full_prompt = f"{system_instruction}\n\n질문: {user_message}"

            response = client.models.generate_content(
                model='gemini-3.5-flash',
                contents=full_prompt,
            )
            
            return JsonResponse({'reply': response.text})

        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
            
    return JsonResponse({'error': '잘못된 요청입니다.'}, status=400)