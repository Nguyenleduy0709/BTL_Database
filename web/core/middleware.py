from .auth import get_actor
from .db import execute


class AppUserMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if "previous_sql" in request.session:
            del request.session["previous_sql"]
        user_id = request.session.get("uid")
        request.actor = get_actor(user_id, request.session.get("password_stamp")) if user_id else None
        if user_id and not request.actor:
            request.session.flush()
        if request.actor:
            execute("SET @app_user_id = %s", [request.actor["ma_nguoi_dung"]])
        return self.get_response(request)
