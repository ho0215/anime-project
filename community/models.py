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
    like_count = models.IntegerField(default=0)
    
    def __str__(self):
        return self.title
    
class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)