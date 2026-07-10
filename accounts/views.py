from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth import login

# 기본 메인 페이지
def home(request):
    return render(request, 'anime/home.html')

# 회원가입
def signup(request):
    if request.method == 'POST':
        form = UserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user) # 가입 성공 시 자동 로그인
            return redirect('home')
    else:
        form = UserCreationForm()
    return render(request, 'accounts/signup.html', {'form': form})

# 회원탈퇴
def delete_account(request):
    if request.method == 'POST':
        if request.user.is_authenticated:
            request.user.delete()
            return redirect('home')
    return redirect('home')