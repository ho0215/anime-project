from django.shortcuts import render

def home(request):
    # templates 폴더 안에 있는 home.html을 렌더링해서 보여줍니다.
    return render(request, 'home.html')