import requests
from django.core.management.base import BaseCommand
from anime.models import Anime

class Command(BaseCommand):
    help = '외부 API에서 데이터를 가져옵니다.'

    def handle(self, *args, **options):
        self.stdout.write("데이터 가져오기 시작...")
        # (여기에 API 호출 로직을 넣으세요)
        self.stdout.write("작업 완료!")