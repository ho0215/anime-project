from django.db import models
from django.contrib.auth.models import User

class CreativeWork(models.Model):
    CATEGORY_CHOICES = [
        ('cosplay', '코스프레'),
        ('illustration', '일러스트'),
        ('novel', '소설'),
    ]

    # 어떤 원작(애니메이션/게임) 기반의 2차 창작인지 기록 (예: 귀멸의 칼날, 리그오브레전드 등)
    target_program = models.CharField(max_length=100, verbose_name="원작 작품명", help_text="예: 귀멸의 칼날, 롤 등")
    
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, verbose_name="분야")
    title = models.CharField(max_length=200, verbose_name="창작물 제목")
    content = models.TextField(verbose_name="내용 / 소설 본문")
    
    # 코스프레, 일러스트는 필수, 소설은 선택이 가능하게 설정
    image = models.ImageField(upload_to='works_images/', null=True, blank=True, verbose_name="창작물 이미지")
    
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='creative_works', verbose_name="크리에이터")
    
    # 통계 및 상호작용 기능 (댓글 대체용 기능들)
    views = models.PositiveIntegerField(default=0, verbose_name="조회수")
    likes = models.ManyToManyField(User, related_name='liked_works', blank=True, verbose_name="좋아요(추천)")
    bookmarks = models.ManyToManyField(User, related_name='bookmarked_works', blank=True, verbose_name="북마크(보관)")
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="등록일")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="수정일")

    def __str__(self):
        return f"[{self.get_category_display()}] {self.target_program} - {self.title}"

    # 소설 분야 글자 수 체크를 위한 편리한 기능
    @property
    def content_length(self):
        return len(self.content)