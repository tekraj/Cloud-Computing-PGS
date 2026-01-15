from cms.models import Page
def nav_items(request):
    return {
        'nav_items': Page.objects.all().order_by('created_at')
    }

