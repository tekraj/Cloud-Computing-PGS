from django.conf import settings
from cms.models import Page
def nav_items(request):
    server_number = settings.SERVER_NUMBER
    return {
        'nav_items': Page.objects.all().order_by('created_at'),
        'server_number': server_number
    }

