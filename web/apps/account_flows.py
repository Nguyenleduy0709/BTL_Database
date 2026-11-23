from django.contrib import messages
from django.db import DatabaseError
from django.shortcuts import redirect, render
from django.views.decorators.cache import never_cache
from django.views.decorators.debug import sensitive_post_parameters
from django.views.decorators.http import require_http_methods, require_POST

from core.email_otp import REGISTER, RESET, RESEND_SECONDS, VALID_SECONDS, issue_code, verify_and_save
from core.errors import database_message
from .account_forms import EmailForm, RegisterForm, VerifyPasswordForm


def session_key(purpose):
    return f"email_otp_{purpose}"


def send_code(request, purpose, email):
    request_id = issue_code(purpose, email, request.META.get("REMOTE_ADDR", "unknown"))
    if request_id is None:
        messages.warning(request, "Bạn đã yêu cầu mã gần đây hoặc vượt giới hạn. Hãy thử lại sau.")
        return False
    request.session[session_key(purpose)] = {"id": request_id, "email": email}
    messages.info(request, "Nếu email đủ điều kiện, CodeLab sẽ gửi mã xác thực. Hãy kiểm tra hộp thư và mục thư rác.")
    return True


@never_cache
@require_http_methods(["GET", "POST"])
def start(request, purpose):
    if request.actor:
        return redirect("dashboard")
    form = EmailForm(request.POST if request.method == "POST" else None)
    if form.is_valid() and send_code(request, purpose, form.cleaned_data["email"]):
        return redirect("register_verify" if purpose == REGISTER else "reset_verify")
    return render(request, "account_flow.html", {
        "title": "Đăng ký học viên" if purpose == REGISTER else "Quên mật khẩu",
        "description": "Nhập email để nhận mã xác thực.",
        "form": form, "submit": "Gửi mã OTP",
    })


@never_cache
@require_POST
def resend(request, purpose):
    if request.actor:
        return redirect("dashboard")
    pending = request.session.get(session_key(purpose))
    if not pending:
        return redirect("register_account" if purpose == REGISTER else "reset_password")
    send_code(request, purpose, pending["email"])
    return redirect("register_verify" if purpose == REGISTER else "reset_verify")


@never_cache
@sensitive_post_parameters("code", "password", "password_confirmation")
@require_http_methods(["GET", "POST"])
def verify(request, purpose):
    if request.actor:
        return redirect("dashboard")
    registering = purpose == REGISTER
    start_route = "register_account" if registering else "reset_password"
    pending = request.session.get(session_key(purpose))
    if not pending:
        return redirect(start_route)
    form_class = RegisterForm if registering else VerifyPasswordForm
    form = form_class(request.POST if request.method == "POST" else None)
    if form.is_valid():
        try:
            saved = verify_and_save(
                purpose, pending["id"], form.cleaned_data["code"],
                request.META.get("REMOTE_ADDR", "unknown"), form.cleaned_data,
            )
        except DatabaseError as error:
            text = "Tên đăng nhập hoặc email đã được sử dụng." if error.args and error.args[0] == 1062 else database_message(error)
            form.add_error(None, text)
        else:
            if saved:
                del request.session[session_key(purpose)]
                messages.success(request, "Tạo tài khoản thành công. Bạn có thể đăng nhập."
                                 if registering else "Mật khẩu đã được đặt lại. Hãy đăng nhập bằng mật khẩu mới.")
                return redirect("login")
            form.add_error("code", "Mã không hợp lệ, đã hết hạn hoặc đã vượt giới hạn nhập sai.")
    return render(request, "account_flow.html", {
        "title": "Hoàn tất đăng ký" if registering else "Đặt lại mật khẩu",
        "description": f"Nhập mã gửi đến {pending['email']}. Mã có hiệu lực {VALID_SECONDS // 60} phút.",
        "form": form, "submit": "Tạo tài khoản" if registering else "Đặt lại mật khẩu",
        "resend_route": "register_resend" if registering else "reset_resend",
        "start_route": start_route, "resend_seconds": RESEND_SECONDS,
    })
