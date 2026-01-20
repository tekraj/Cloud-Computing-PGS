from django.http import HttpResponse

class HealthCheckMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # If the path is exactly /health/, return 200 OK immediately
        # This bypasses ALLOWED_HOSTS and the entire database/auth stack
        if request.path == '/health/':
            return HttpResponse("ok")
        
        return self.get_response(request)