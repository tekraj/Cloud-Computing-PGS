from django.shortcuts import render

from cms.models import Page
from catalog.models import Product

def home(request):
    pages = Page.objects.all()
    return render(request, "home.html", {"pages": pages})

def product_list(request):
    products = Product.objects.all()
    return render(request, "product-list.html", {"products": products})

def product_detail(request, product_id):
    product = Product.objects.get(id=product_id)
    return render(request, "product.html", {"product": product})

def about(request):
    return render(request, "about.html")

def contact(request):
    return render(request, "contact.html")

def testimonials(request):
    return render(request, "testimonials.html")