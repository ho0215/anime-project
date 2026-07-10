from django.db import models

class Anime(models.Model):
    api_id = models.IntegerField(unique=True)
    title = models.CharField(max_length=200)
    genre = models.CharField(max_length=100)
    synopsis = models.TextField()
    image_url = models.URLField()
    score = models.FloatField()

    def __str__(self):
        return self.title