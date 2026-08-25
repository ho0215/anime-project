"""
ASGI config for config project.

Exposes the ASGI callable as module-level ``application``.
Import order matters: set DJANGO_SETTINGS_MODULE and initialize Django
before importing apps that touch models/settings (Channels consumers).
"""

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

# Initialize Django before importing routing / consumers.
django_asgi_app = get_asgi_application()

from channels.auth import AuthMiddlewareStack  # noqa: E402
from channels.routing import ProtocolTypeRouter, URLRouter  # noqa: E402

import deal.routing  # noqa: E402

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,
        "websocket": AuthMiddlewareStack(
            URLRouter(deal.routing.websocket_urlpatterns)
        ),
    }
)
