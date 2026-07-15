from django import forms
from .models import CreativeWork


class CreativeWorkForm(forms.ModelForm):
    class Meta:
        model = CreativeWork
        fields = [
            'target_program',
            'category',
            'title',
            'content',
            'image',
        ]