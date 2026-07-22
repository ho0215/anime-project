from django.db import models

# 1. Anime가 무조건 위에 있어야 합니다.
class Anime(models.Model):
    api_id = models.IntegerField(unique=True)
    title = models.CharField(max_length=200)
    genre = models.CharField(max_length=100)
    synopsis = models.TextField()
    image_url = models.URLField()
    score = models.FloatField()
    original_title = models.CharField(max_length=200, null=True, blank=True)
    first_air_date = models.CharField(max_length=50, null=True, blank=True)
    backdrop_url = models.URLField(null=True, blank=True)

    def __str__(self):
        return self.title


# 2. 그 아래에 Review가 있어야 Anime를 알아볼 수 있습니다.
class Review(models.Model):
    anime = models.ForeignKey(Anime, on_delete=models.CASCADE, related_name='reviews')
    score = models.IntegerField(default=10)
    content = models.CharField(max_length=200)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.anime.title} - {self.score}점"