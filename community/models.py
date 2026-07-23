from django.db import models
from django.contrib.auth.models import User
from ckeditor.fields import RichTextField
from django.utils import timezone  # [추가] 장고의 시간대 도구 불러오기
from datetime import timedelta     # [추가] 시간 차이 계산용 도구 불러오기

# Create your models here.
class Post(models.Model):
    # 변수명을 BOARD_CHOICES로 맞추고 공지 사항을 추가했습니다.
    BOARD_CHOICES = [
        ('notice', '공지 사항'),
        ('qna', '질문 답변'),
        ('free', '자유 게시판'),
        ('info', '정보 공유'),
    ]
    
    board_type = models.CharField(max_length=10, choices=BOARD_CHOICES)
    title = models.CharField(max_length=200)
    content = RichTextField()
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    image = models.ImageField(upload_to='community/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    view_count = models.IntegerField(default=0)
    
    # [수정] 기존 IntegerField 대신 ManyToManyField를 사용하여 추천한 유저들을 저장합니다.
    # 한 유저가 여러 글에 추천할 수 있고, 한 게시글에 여러 유저가 추천할 수 있습니다.
    likes = models.ManyToManyField(User, related_name='like_posts', blank=True)
    
    def __str__(self):
        return self.title
        
    # [추가] 총 추천수(좋아요 수)를 템플릿이나 뷰에서 쉽게 가져오기 위한 함수입니다.
    def total_likes(self):
        return self.likes.count()
    
    # ⭐ [추가] 등록일 기준 24시간 이내의 글인지 판별하는 함수
    @property
    def is_new(self):
        # (현재 시간 - 게시글 등록 시간)이 24시간보다 적으면 True를 반환합니다.
        return timezone.now() - self.created_at < timedelta(hours=24)
    
class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # 💡 [추가] 댓글이 수정되었는지 여부를 체크하는 필드 ('수정됨' 표시에 사용)
    is_updated = models.BooleanField(default=False)
    
    # ★ 5. 대댓글 구현을 위한 핵심 필드 (자기 자신을 참조)
    # null=True, blank=True 여야 '원댓글'이 존재할 수 있습니다.
    parent_comment = models.ForeignKey(
        'self', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='replies'
    )

    class Meta:
        ordering = ['created_at'] # 작성 순서대로 정렬

    def __str__(self):
        return f'{self.author.username} - {self.content[:20]}'  