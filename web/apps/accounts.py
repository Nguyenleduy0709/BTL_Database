import bcrypt
from django import forms
from django.contrib import messages
from django.middleware.csrf import rotate_token
from django.shortcuts import redirect, render
from django.utils.http import url_has_allowed_host_and_scheme
from django.views.decorators.debug import sensitive_post_parameters
from django.views.decorators.http import require_http_methods, require_POST

from core.auth import ADMIN, password_stamp, role_required
from core.db import call_proc, execute, fetch_all, fetch_one
from .account_forms import PasswordField
from .ui import form_page, link, options, page, require_row, select, status, table, text

@sensitive_post_parameters("password")
@require_http_methods(["GET", "POST"])
def login(request):
    if request.actor:
        return redirect("dashboard")
    form = forms.Form(request.POST if request.method == "POST" else None)
    form.fields["username"] = forms.CharField(
        label="Tên đăng nhập", max_length=64, widget=forms.TextInput(attrs={"autocomplete": "username"}),
    )
    form.fields["password"] = PasswordField(
        label="Mật khẩu", max_length=72, strip=False, widget=forms.PasswordInput(attrs={"autocomplete": "current-password"}),
    )
    if form.is_bound and form.is_valid():
        user = fetch_one("""
            SELECT ma_nguoi_dung, mat_khau_hash FROM NguoiDung
            WHERE ten_dang_nhap = %s AND trang_thai = 'HOAT_DONG'
        """, [form.cleaned_data["username"]])
        valid = False
        if user:
            try:
                valid = bcrypt.checkpw(form.cleaned_data["password"].encode(), user["mat_khau_hash"].encode("ascii"))
            except ValueError:
                pass
        if valid:
            request.session.cycle_key()
            request.session["uid"] = user["ma_nguoi_dung"]
            request.session["password_stamp"] = password_stamp(user["mat_khau_hash"])
            rotate_token(request)
            destination = request.GET.get("next")
            if url_has_allowed_host_and_scheme(destination, {request.get_host()}, require_https=request.is_secure()):
                return redirect(destination)
            return redirect("dashboard")
        form.add_error(None, "Tên đăng nhập hoặc mật khẩu chưa đúng.")
    return render(request, "login.html", {"title": "Đăng nhập", "form": form})


@require_POST
def logout(request):
    request.session.flush()
    messages.success(request, "Đã đăng xuất.")
    return redirect("login")


@role_required(ADMIN)
def users(request):
    rows = fetch_all("""
        SELECT n.ma_nguoi_dung, n.ten_dang_nhap, n.ho_ten, n.email, n.trang_thai,
               GROUP_CONCAT(v.ten_vai_tro ORDER BY v.ma_vai_tro SEPARATOR ', ') AS vai_tro
        FROM NguoiDung n LEFT JOIN NguoiDungVaiTro nv USING (ma_nguoi_dung)
        LEFT JOIN VaiTro v USING (ma_vai_tro)
        WHERE n.trang_thai = 'HOAT_DONG'
        GROUP BY n.ma_nguoi_dung ORDER BY n.ma_nguoi_dung LIMIT 100
    """)
    grid = table("Tài khoản hoạt động", {
        "Họ tên": "ho_ten", "Tên đăng nhập": "ten_dang_nhap", "Email": "email", "Vai trò": "vai_tro",
        "Trạng thái": lambda r: status(r["trang_thai"]),
        "Thao tác": lambda r: link("Gán vai trò", "grant_role", r["ma_nguoi_dung"]),
    }, rows)
    return page(request, "Người dùng", "users", tables=[grid], actions=[link("Tạo tài khoản", "new_user")])


def roles():
    return options(fetch_all("SELECT ma_vai_tro, mo_ta FROM VaiTro ORDER BY ma_vai_tro"), "ma_vai_tro", "mo_ta")


@role_required(ADMIN)
@sensitive_post_parameters("password")
@require_http_methods(["GET", "POST"])
def new_user(request):
    fields = {
        "username": text("Tên đăng nhập", 64), "email": forms.EmailField(label="Email"),
        "full_name": text("Họ tên", 120), "role": select("Vai trò", roles()),
    }

    fields["password"] = PasswordField(
        label="Mật khẩu", min_length=8, strip=False, widget=forms.PasswordInput(attrs={"autocomplete": "new-password"}),
    )

    def save(data):
        password_hash = bcrypt.hashpw(data["password"].encode(), bcrypt.gensalt()).decode()
        call_proc("sp_tao_nguoi_dung", [data["username"], data["email"], password_hash, data["full_name"], data["role"]])

    return form_page(request, "Tạo tài khoản", "users", fields, save, link("Người dùng", "users"))


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def grant_role(request, user_id):
    user = require_row("SELECT ho_ten FROM NguoiDung WHERE ma_nguoi_dung = %s", [user_id])

    def save(data):
        execute("INSERT INTO NguoiDungVaiTro(ma_nguoi_dung, ma_vai_tro) VALUES (%s, %s)", [user_id, data["role"]])

    return form_page(request, f"Gán vai trò cho {user['ho_ten']}", "users",
                     {"role": select("Vai trò", roles())}, save, link("Người dùng", "users"))
