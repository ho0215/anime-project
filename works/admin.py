from django.contrib import admin

# Register your models here.

from .models import CreativeWork, WorkImage

admin.site.register(CreativeWork)
admin.site.register(WorkImage)
