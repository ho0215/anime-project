from django.shortcuts import render
from .models import Anime

def anime_list(request):
    animes = Anime.objects.all()
    return render(request, 'anime_list.html', {'animes': animes})

def home(request):
    return render(request, 'home.html')