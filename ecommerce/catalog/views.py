from django.shortcuts import render
from django.shortcuts import redirect
from .models import Product


def create_product(request):
    if request.method == 'POST':
        name = request.POST.get('name')
        description = request.POST.get('description')
        price = request.POST.get('price')
        stock = request.POST.get('stock')
        category_id = request.POST.get('category')
        img = request.FILES.get('image')
        
        product = Product.objects.create(
            name=name,
            description=description,
            price=price,
            stock=stock,
            category_id=category_id,
            image=img
        )
        product.save()
        return redirect('success')