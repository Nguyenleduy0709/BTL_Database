from pathlib import Path
import os
from secrets import token_urlsafe

from django.core.exceptions import ImproperlyConfigured
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parents[1]
LOCAL_DIR = BASE_DIR.parent / ".local"
load_dotenv(BASE_DIR.parent / ".env")

DEBUG = os.getenv("DJANGO_DEBUG", "1") == "1"
SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")
if not SECRET_KEY:
    if not DEBUG:
        raise ImproperlyConfigured("Cần cấu hình DJANGO_SECRET_KEY khi chạy ngoài chế độ phát triển.")
    key_path = LOCAL_DIR / "django_secret_key"
    key_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with key_path.open("x", encoding="ascii") as key_file:
            key_file.write(token_urlsafe(48))
    except FileExistsError:
        pass
    SECRET_KEY = key_path.read_text(encoding="ascii").strip()

ALLOWED_HOSTS = os.getenv("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

INSTALLED_APPS = ["django.contrib.messages", "django.contrib.staticfiles"]
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "core.middleware.AppUserMiddleware",
]
SESSION_ENGINE = "django.contrib.sessions.backends.signed_cookies"
MESSAGE_STORAGE = "django.contrib.messages.storage.cookie.CookieStorage"
SESSION_COOKIE_AGE = 60 * 60 * 8
SESSION_COOKIE_SECURE = CSRF_COOKIE_SECURE = os.getenv("DJANGO_SECURE_COOKIES", "0") == "1"

EMAIL_HOST = os.getenv("SMTP_HOST", "").strip()
EMAIL_USE_SSL = os.getenv("SMTP_USE_SSL", "0") == "1"
EMAIL_USE_TLS = os.getenv("SMTP_USE_TLS", "0" if EMAIL_USE_SSL else "1") == "1"
if EMAIL_USE_TLS and EMAIL_USE_SSL:
    raise ImproperlyConfigured("Chọn SMTP_USE_TLS hoặc SMTP_USE_SSL.")
EMAIL_PORT = int(os.getenv("SMTP_PORT") or (465 if EMAIL_USE_SSL else 587 if EMAIL_USE_TLS else 25))
EMAIL_HOST_USER = os.getenv("SMTP_USER", "")
EMAIL_HOST_PASSWORD = os.getenv("SMTP_PASSWORD", "")
EMAIL_TIMEOUT = 8
DEFAULT_FROM_EMAIL = os.getenv("SMTP_FROM") or EMAIL_HOST_USER or "CodeLab <no-reply@localhost>"
EMAIL_BACKEND = (
    "django.core.mail.backends.filebased.EmailBackend" if DEBUG and not EMAIL_HOST
    else "django.core.mail.backends.smtp.EmailBackend"
)
EMAIL_FILE_PATH = LOCAL_DIR / "mail"

TEMPLATES = [{
    "BACKEND": "django.template.backends.django.DjangoTemplates",
    "DIRS": [BASE_DIR / "templates"],
    "OPTIONS": {"context_processors": [
        "django.template.context_processors.request",
        "django.contrib.messages.context_processors.messages",
    ]},
}]

DB = {
    "ENGINE": "django.db.backends.mysql",
    "NAME": os.getenv("DB_NAME", "btlcsdl"),
    "HOST": os.getenv("DB_HOST", "127.0.0.1"),
    "PORT": os.getenv("DB_PORT", "33317"),
    "OPTIONS": {"charset": "utf8mb4", "init_command": "SET SESSION time_zone = '+07:00'"},
}
DATABASES = {
    "default": {**DB, "USER": os.getenv("DB_USER", "app_web"),
                "PASSWORD": os.getenv("DB_PASSWORD", "")},
    "readonly": {**DB, "USER": os.getenv("DB_READ_USER", "app_readonly"),
                 "PASSWORD": os.getenv("DB_READ_PASSWORD", "")},
}

TIME_ZONE = "Asia/Ho_Chi_Minh"
USE_TZ = False
LANGUAGE_CODE = "vi"
STATIC_URL = "/static/"
STATICFILES_DIRS = [BASE_DIR / "static"]
