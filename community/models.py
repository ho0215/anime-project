from django.db import models
from django.contrib.auth.models import User

# Create your models here.
class Post(models.Model):
    BOARD_CHOICES = [
        ('notice', '공지사항'),
        ('question', '질문'),
        ('free', '자유'),
        ('share', '공유'),
    ]
    board_type =models.CharField(max_length=10, choices=BOARD_CHOICES)
    title = models.CharField(max_length=200)
    content = models.TextField()
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