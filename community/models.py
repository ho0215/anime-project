from django.db import models
from django.contrib.auth.models import User
from ckeditor.fields import RichTextField

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
    # [수정] 기존 IntegerField 대신 ManyToManyField를 사용하여 추천한 유저들을 저장합니다.
    likes = models.ManyToManyField(User, related_name='like_posts', blank=True)
    
    def __str__(self):
        return self.title
        
    # [추가] 총 추천수(좋아요 수)를 템플릿이나 뷰에서 쉽게 가져오기 위한 함수입니다.
    def total_likes(self):
        return self.likes.count()
    
class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)