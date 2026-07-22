import requests
from django.core.management.base import BaseCommand
from anime.models import Anime

class Command(BaseCommand):
    help = '유명한 일본 애니메이션 데이터를 더 풍성하게 가져옵니다.'

    def handle(self, *args, **options):
        api_key = 'fcf1e4d2533332357dde303d1d8fcf50'
        
        self.stdout.write("기존 데이터 초기화 중...")
        Anime.objects.all().delete()

        for page in range(1, 6):
            url = f"https://api.themoviedb.org/3/discover/tv?api_key={api_key}&with_genres=16&with_original_language=ja&language=ko-KR&page={page}&sort_by=popularity.desc&include_adult=false&vote_count.gte=100"
            
            response = requests.get(url)
            if response.status_code == 200:
                data = response.json().get('results', [])
                
                for item in data:
                    if not item.get('name') or not item.get('overview'):
                        continue
                        
                    image_path = item.get('poster_path')
                    image_url = f"https://image.tmdb.org/t/p/w500{image_path}" if image_path else "https://via.placeholder.com/500x750?text=No+Image"
                    
                    # 🔥 가로형 배경 이미지 주소 만들기 (고화질 original 사이즈)
                    backdrop_path = item.get('backdrop_path')
                    backdrop_url = f"https://image.tmdb.org/t/p/original{backdrop_path}" if backdrop_path else ""

                    # DB 저장 시 추가 필드 포함
                    Anime.objects.update_or_create(
                        api_id=item['id'],
                        defaults={
                            'title': item['name'],
                            'original_title': item.get('original_name', ''), # 원작 제목
                            'first_air_date': item.get('first_air_date', ''), # 첫 방영일
                            'backdrop_url': backdrop_url, # 배경 이미지
                            'genre': '애니메이션',
                            'synopsis': item['overview'],
                            'image_url': image_url,
                            'score': item.get('vote_average', 0.0),
                        }
                    )
                self.stdout.write(f"{page}페이지 수집 완료!")
        
        self.stdout.write(self.style.SUCCESS("풍성한 데이터 수집 완료!"))