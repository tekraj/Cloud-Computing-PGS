from django.contrib import admin

# Register your models here.

from .models import Page, Post
admin.site.register(Page)
admin.site.register(Post)