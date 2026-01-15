from django.shortcuts import render

from cms.models import Page

def home(request):
    pages = Page.objects.all()
    return render(request, "home.html", {"pages": pages})
