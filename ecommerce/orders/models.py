from django.db import models

# Create your models here.
class ProducOrder(models.Model):
    product_name = models.CharField(max_length=200)
    quantity = models.PositiveIntegerField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    order_date = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=50, choices=[
        ('pending', 'Pending'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('canceled', 'Canceled'),
    ], default='pending')
    def __str__(self):
        return f"Order of {self.product_name} - {self.status}"

    class Meta:
        verbose_name = "Product Order"
        verbose_name_plural = "Product Orders"
        ordering = ["-order_date"]