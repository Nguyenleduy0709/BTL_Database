from functools import wraps

from django.core.exceptions import PermissionDenied
from django.shortcuts import redirect
from django.utils.crypto import constant_time_compare, salted_hmac

from .db import fetch_one

ADMIN = "ADMIN"
TEACHER = "GIANG_VIEN"
STUDENT = "HOC_VIEN"


def password_stamp(password_hash):
    return salted_hmac("codelab.password", password_hash, algorithm="sha256").hexdigest()


def get_actor(user_id, session_stamp):
    if not session_stamp:
        return None
    actor = fetch_one("""
        SELECT n.ma_nguoi_dung, n.ten_dang_nhap, n.ho_ten, n.mat_khau_hash,
               GROUP_CONCAT(v.ten_vai_tro ORDER BY v.ma_vai_tro) AS vai_tro
        FROM NguoiDung n LEFT JOIN NguoiDungVaiTro nv USING (ma_nguoi_dung)
        LEFT JOIN VaiTro v USING (ma_vai_tro)
        WHERE n.ma_nguoi_dung = %s AND n.trang_thai = 'HOAT_DONG'
        GROUP BY n.ma_nguoi_dung
    """, [user_id])
    if not actor or not constant_time_compare(
        session_stamp, password_stamp(actor.pop("mat_khau_hash")),
    ):
        return None
    roles = actor.pop("vai_tro")
    actor["roles"] = roles.split(",") if roles else []
    return actor


def role_required(*roles):
    def decorate(view):
        @wraps(view)
        def wrapped(request, *args, **kwargs):
            if not request.actor:
                return redirect("login")
            if roles and not set(roles).intersection(request.actor["roles"]):
                raise PermissionDenied
            return view(request, *args, **kwargs)
        return wrapped
    return decorate


def can_teach(request, class_id):
    return TEACHER in request.actor["roles"] and bool(fetch_one("""
        SELECT 1 FROM PhanCongGiangDay WHERE ma_lop = %s AND ma_giang_vien = %s
    """, [class_id, request.actor["ma_nguoi_dung"]]))


def require_teaching(request, class_id):
    if ADMIN not in request.actor["roles"] and not can_teach(request, class_id):
        raise PermissionDenied
