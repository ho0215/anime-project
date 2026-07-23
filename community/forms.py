from django import forms
from .models import Post, Comment
from ckeditor.widgets import CKEditorWidget  # 💡 CKEditor 위젯 불러오기

class PostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['content']
        # 💡 content 필드에 CKEditor 위젯을 강제로 명시하여 연결합니다.
        widgets = {
            'content': CKEditorWidget(),
        }
        
class CommentForm(forms.ModelForm):
    class Meta:
        model = Comment
        fields = ['content']
        widgets = {
            'content': forms.Textarea(attrs={'rows': 3, 'placeholder': '댓글을 남겨보세요.'}),
        }