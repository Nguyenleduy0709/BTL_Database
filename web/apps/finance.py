from django import forms
from django.shortcuts import render
from django.views.decorators.http import require_GET, require_http_methods

from core.auth import ADMIN, STUDENT, role_required
from core.db import call_proc, execute, fetch_all
from .ui import area, enum, form_page, link, money, page, percent, require_row, table, text


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
               f.con_no, cc.so_hieu, cc.xep_loai, cc.ngay_cap, dg.so_sao
        FROM v_tien_do_thuc_hanh p JOIN v_lop_hoc l USING (ma_lop)
        JOIN DangKyLop d USING (ma_dang_ky)
        LEFT JOIN v_tien_do_ly_thuyet lt USING (ma_dang_ky)
        LEFT JOIN v_chuyen_can c USING (ma_dang_ky)
        LEFT JOIN v_cong_no_hoc_phi f USING (ma_dang_ky)
        LEFT JOIN ChungChi cc USING (ma_dang_ky)
        LEFT JOIN DanhGiaLopHoc dg USING (ma_dang_ky)
        WHERE p.ma_hoc_vien = %s ORDER BY l.ma_code
    """, [uid])
    for row in records:
        row["practice"] = percent(row["tien_do"])
        row["theory"] = percent(row["ly_thuyet"])
        row["attendance"] = percent(row["ty_le"])
        row["debt"] = money(row["con_no"])
        row["can_review"] = row["so_sao"] is None and (row["trang_thai"] == "KET_THUC" or row["trang_thai_dk"] == "HOAN_THANH")
    return render(request, "progress.html", {"title": "Tiến độ của tôi", "section": "progress", "records": records})


@role_required(STUDENT)
@require_http_methods(["GET", "POST"])
def payment(request, registration_id):
    registration = owned_registration(request, registration_id)
    fields = {
        "amount": forms.DecimalField(label="Số tiền (₫)", min_value=1, max_digits=12, decimal_places=0),
        "method": enum("Phương thức", ["TIEN_MAT", "CHUYEN_KHOAN"], {"TIEN_MAT": "Tiền mặt", "CHUYEN_KHOAN": "Chuyển khoản"}),
        "reference": text("Mã giao dịch (nếu có)", 64, required=False),
    }
    rows = fetch_all("""
        SELECT so_tien, phuong_thuc, ma_giao_dich, thoi_diem FROM ThanhToan
        WHERE ma_dang_ky = %s ORDER BY thoi_diem DESC, ma_thanh_toan DESC
    """, [registration_id])

    def save(data):
        call_proc("sp_thanh_toan", [registration_id, data["amount"], data["method"], data["reference"] or None])

    return form_page(request, f"Thanh toán · {registration['ma_code']}", "progress", fields, save,
                     link("Tiến độ của tôi", "progress"), description="Ghi nhận giao dịch học phí giả lập.",
                     tables=[table("Lịch sử thanh toán", {"Số tiền": lambda r: money(r["so_tien"]),
                                   "Phương thức": lambda r: "Tiền mặt" if r["phuong_thuc"] == "TIEN_MAT" else "Chuyển khoản",
                                   "Mã giao dịch": "ma_giao_dich", "Thời điểm": "thoi_diem"}, rows)])


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
def finance(request):
    rows = fetch_all("""
        SELECT f.*, c.so_hieu, p.tien_do, a.ty_le
        FROM v_cong_no_hoc_phi f LEFT JOIN ChungChi c USING (ma_dang_ky)
        LEFT JOIN v_tien_do_thuc_hanh p USING (ma_dang_ky) LEFT JOIN v_chuyen_can a USING (ma_dang_ky)
        JOIN NguoiDung n ON n.ma_nguoi_dung = f.ma_hoc_vien
        WHERE n.trang_thai = 'HOAT_DONG' ORDER BY f.ma_lop, f.ho_ten LIMIT 150
    """)
    grid = table("Học phí và chứng chỉ", {
        "Lớp": "ma_code", "Học viên": "ho_ten", "Học phí": lambda r: money(r["hoc_phi"]),
        "Đã đóng": lambda r: money(r["da_thanh_toan"]), "Còn nợ": lambda r: money(r["con_no"]),
        "Thực hành": lambda r: percent(r["tien_do"]), "Chuyên cần": lambda r: percent(r["ty_le"]),
        "Chứng chỉ": lambda r: r["so_hieu"] or link("Kiểm tra và cấp", "certificate", r["ma_dang_ky"]),
    }, rows)
    return page(request, "Học phí và chứng chỉ", "finance", tables=[grid])


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def certificate(request, registration_id):
    row = require_row("SELECT * FROM v_cong_no_hoc_phi WHERE ma_dang_ky = %s", [registration_id])

    def save(data):
        call_proc("sp_cap_chung_chi", [registration_id])

    return form_page(request, f"Cấp chứng chỉ · {row['ho_ten']}", "finance", {}, save,
                     link("Học phí và chứng chỉ", "finance"),
                     description="MySQL kiểm tra tiến độ thực hành 100% và chuyên cần từ 80%.", submit="Kiểm tra và cấp")


@role_required(ADMIN)
@require_GET
def audit(request):
    rows = fetch_all("""
        SELECT j.ma_nhat_ky, j.ten_bang, j.hanh_dong, j.khoa_ban_ghi, j.du_lieu_cu, j.du_lieu_moi,
               j.thoi_diem, n.ho_ten FROM NhatKyHeThong j
        LEFT JOIN NguoiDung n ON n.ma_nguoi_dung = j.ma_nguoi_thuc_hien
        ORDER BY j.ma_nhat_ky DESC LIMIT 100
    """)
    return page(request, "Nhật ký hệ thống", "audit", tables=[table("100 bản ghi gần nhất", {
        "Mã": "ma_nhat_ky", "Bảng": "ten_bang", "Thao tác": "hanh_dong", "Bản ghi": "khoa_ban_ghi",
        "Người thực hiện": "ho_ten", "Thời điểm": "thoi_diem", "Dữ liệu cũ": "du_lieu_cu", "Dữ liệu mới": "du_lieu_moi",
    }, rows)])
