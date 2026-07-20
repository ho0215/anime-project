from django.db import models

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