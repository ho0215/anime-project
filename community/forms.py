# forms.py
from django import forms
from .models import Post

class PostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['content']  # ckeditor가 적용된 content 필드만 폼으로 관리합니다.