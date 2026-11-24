from django import forms
from django.shortcuts import render
from django.views.decorators.http import require_GET, require_http_methods

from core.auth import ADMIN, STUDENT, role_required
from core.db import call_proc, execute, fetch_all
from .ui import area, form_page, link, page, percent, require_row, table


def owned_registration(request, registration_id):
    return require_row("""
        SELECT d.*, l.ma_code, l.trang_thai AS trang_thai_lop FROM DangKyLop d JOIN LopHoc l USING (ma_lop)
        WHERE d.ma_dang_ky = %s AND d.ma_hoc_vien = %s AND d.trang_thai <> 'DA_HUY'
    """, [registration_id, request.actor["ma_nguoi_dung"]])


@role_required(STUDENT)
@require_GET
def my_progress(request):
    uid = request.actor["ma_nguoi_dung"]
    records = fetch_all("""
        SELECT p.*, l.ma_code, l.ten_khoa_hoc, l.trang_thai, lt.tien_do AS ly_thuyet, c.ty_le, d.trang_thai AS trang_thai_dk,
               cc.so_hieu, cc.xep_loai, cc.ngay_cap, dg.so_sao
        FROM v_tien_do_thuc_hanh p JOIN v_lop_hoc l USING (ma_lop)
        JOIN DangKyLop d USING (ma_dang_ky)
        LEFT JOIN v_tien_do_ly_thuyet lt USING (ma_dang_ky)
        LEFT JOIN v_chuyen_can c USING (ma_dang_ky)
        LEFT JOIN ChungChi cc USING (ma_dang_ky)
        LEFT JOIN DanhGiaLopHoc dg USING (ma_dang_ky)
        WHERE p.ma_hoc_vien = %s ORDER BY l.ma_code
    """, [uid])
    for row in records:
        row["practice"] = percent(row["tien_do"])
        row["theory"] = percent(row["ly_thuyet"])
        row["attendance"] = percent(row["ty_le"])
        row["can_review"] = row["so_sao"] is None and (row["trang_thai"] == "KET_THUC" or row["trang_thai_dk"] == "HOAN_THANH")
    return render(request, "progress.html", {"title": "Tiến độ của tôi", "section": "progress", "records": records})


@role_required(STUDENT)
@require_http_methods(["GET", "POST"])
def review(request, registration_id):
    registration = owned_registration(request, registration_id)
    fields = {"rating": forms.IntegerField(label="Số sao (1–5)", min_value=1, max_value=5),
              "comment": area("Nhận xét", required=False)}

    def save(data):
        execute("INSERT INTO DanhGiaLopHoc(ma_dang_ky, so_sao, nhan_xet) VALUES (%s, %s, %s)",
                [registration_id, data["rating"], data["comment"]])

    return form_page(request, f"Đánh giá · {registration['ma_code']}", "progress", fields, save,
                     link("Tiến độ của tôi", "progress"))


@role_required(ADMIN)
@require_GET
def certificates(request):
    rows = fetch_all("""
        SELECT d.ma_dang_ky, l.ma_code, n.ho_ten, c.so_hieu, p.tien_do, a.ty_le
        FROM DangKyLop d JOIN LopHoc l USING (ma_lop)
        JOIN NguoiDung n ON n.ma_nguoi_dung = d.ma_hoc_vien
        LEFT JOIN ChungChi c USING (ma_dang_ky)
        LEFT JOIN v_tien_do_thuc_hanh p USING (ma_dang_ky) LEFT JOIN v_chuyen_can a USING (ma_dang_ky)
        WHERE d.trang_thai <> 'DA_HUY' AND n.trang_thai = 'HOAT_DONG'
        ORDER BY d.ma_lop, n.ho_ten LIMIT 150
    """)
    grid = table("Chứng chỉ theo lớp", {
        "Lớp": "ma_code", "Học viên": "ho_ten",
        "Thực hành": lambda r: percent(r["tien_do"]), "Chuyên cần": lambda r: percent(r["ty_le"]),
        "Chứng chỉ": lambda r: r["so_hieu"] or link("Kiểm tra và cấp", "certificate", r["ma_dang_ky"]),
    }, rows)
    return page(request, "Chứng chỉ", "certificates", tables=[grid])


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def certificate(request, registration_id):
    row = require_row("""
        SELECT n.ho_ten FROM DangKyLop d JOIN NguoiDung n ON n.ma_nguoi_dung = d.ma_hoc_vien
        WHERE d.ma_dang_ky = %s AND d.trang_thai <> 'DA_HUY'
    """, [registration_id])

    def save(data):
        call_proc("sp_cap_chung_chi", [registration_id])

    return form_page(request, f"Cấp chứng chỉ · {row['ho_ten']}", "certificates", {}, save,
                     link("Chứng chỉ", "certificates"),
                     description="MySQL kiểm tra tiến độ thực hành 100% và chuyên cần từ 80%.", submit="Kiểm tra và cấp")


@role_required(ADMIN)
@require_GET
def audit(request):
    rows = fetch_all("""
        SELECT j.ma_nhat_ky, j.ten_bang, j.hanh_dong, j.khoa_ban_ghi, j.du_lieu_cu, j.du_lieu_moi,
               j.thoi_diem, n.ho_ten FROM NhatKyHeThong j
        LEFT JOIN NguoiDung n ON n.ma_nguoi_dung = j.ma_nguoi_thuc_hien
        WHERE j.ten_bang IN ('DangKyLop', 'GiaoBai')
        ORDER BY j.ma_nhat_ky DESC LIMIT 100
    """)
    return page(request, "Nhật ký hệ thống", "audit", tables=[table("100 bản ghi gần nhất", {
        "Mã": "ma_nhat_ky", "Bảng": "ten_bang", "Thao tác": "hanh_dong", "Bản ghi": "khoa_ban_ghi",
        "Người thực hiện": "ho_ten", "Thời điểm": "thoi_diem", "Dữ liệu cũ": "du_lieu_cu", "Dữ liệu mới": "du_lieu_moi",
    }, rows)])
