from django.shortcuts import render
from django.views.decorators.http import require_GET

from core.auth import ADMIN, STUDENT, TEACHER, role_required
from core.db import fetch_all, fetch_one
from .ui import link, percent, status, table


@role_required()
@require_GET
def dashboard(request):
    uid = request.actor["ma_nguoi_dung"]
    roles = request.actor["roles"]
    student = ADMIN not in roles and TEACHER not in roles and STUDENT in roles
    if student:
        progress = fetch_all("""
            SELECT l.ma_code, l.ma_lop, l.ten_khoa_hoc, p.tien_do, p.so_da_dat, p.tong_bat_buoc
            FROM v_tien_do_thuc_hanh p JOIN v_lop_hoc l USING (ma_lop)
            WHERE p.ma_hoc_vien = %s ORDER BY l.ma_code
        """, [uid])
        metrics = [("Lớp đã đăng ký", len(progress), "DS"), ("Bài bắt buộc đã đạt", sum(row["so_da_dat"] for row in progress), "OK"),
                   ("Bài bắt buộc được giao", sum(row["tong_bat_buoc"] for row in progress), "BT")]
        grid = table("Lớp của bạn", {
            "Lớp": lambda row: link(row["ma_code"], "class_detail", row["ma_lop"]),
            "Khóa học": "ten_khoa_hoc", "Tiến độ thực hành": lambda row: percent(row["tien_do"]),
        }, progress)
        return render(request, "dashboard.html", {
            "title": "Tổng quan", "section": "dashboard", "student": True, "metrics": metrics, "grid": grid,
        })

    if ADMIN in roles:
        overview = fetch_one("SELECT * FROM v_tong_quan")
        metrics = [("Lớp đang hoạt động", overview["so_lop"], "LH"), ("Học viên ghi danh", overview["so_hoc_vien"], "HV"),
                   ("Lượt nộp", overview["so_lan_nop"], "LN"), ("Lượt chờ chấm", overview["cho_cham"], "CC")]
        activity_scope, parameters = "", []
        groups = fetch_all("SELECT * FROM v_lop_hoc ORDER BY ma_lop LIMIT 8")
    else:
        groups = fetch_all("""
            SELECT l.* FROM v_lop_hoc l JOIN PhanCongGiangDay p USING (ma_lop)
            WHERE p.ma_giang_vien = %s ORDER BY l.ma_lop
        """, [uid])
        counts = fetch_one("""
            SELECT COUNT(DISTINCT n.ma_lan_nop) AS so_lan, COUNT(DISTINCT n.ma_hoc_vien) AS so_nguoi,
                   COUNT(DISTINCT CASE WHEN n.trang_thai_cham = 'CHO_CHAM' THEN n.ma_lan_nop END) AS cho_cham
            FROM PhanCongGiangDay p JOIN GiaoBai g USING (ma_lop) LEFT JOIN LanNop n USING (ma_giao)
            WHERE p.ma_giang_vien = %s
        """, [uid])
        metrics = [("Lớp được phân công", len(groups), "LH"), ("Học viên đã nộp", counts["so_nguoi"], "HV"),
                   ("Lượt nộp", counts["so_lan"], "LN"), ("Lượt chờ chấm", counts["cho_cham"], "CC")]
        activity_scope = "JOIN PhanCongGiangDay p ON p.ma_lop = g.ma_lop AND p.ma_giang_vien = %s"
        parameters = [uid]

    activity = fetch_all(f"""
        WITH RECURSIVE ngay(d) AS (
            SELECT CURRENT_DATE - INTERVAL 6 DAY UNION ALL SELECT d + INTERVAL 1 DAY FROM ngay WHERE d < CURRENT_DATE
        ), phat_sinh AS (
            SELECT DATE(n.thoi_diem_nop) AS d, COUNT(*) AS so_luot FROM LanNop n
            JOIN GiaoBai g USING (ma_giao) {activity_scope}
            WHERE n.thoi_diem_nop >= CURRENT_DATE - INTERVAL 6 DAY GROUP BY DATE(n.thoi_diem_nop)
        )
        SELECT CONCAT(LPAD(DAY(ngay.d), 2, '0'), '/', LPAD(MONTH(ngay.d), 2, '0')) AS ngay, COALESCE(p.so_luot, 0) AS luot
        FROM ngay LEFT JOIN phat_sinh p USING (d) ORDER BY ngay.d
    """, parameters or None)
    grid = table("Lớp học", {
        "Mã lớp": lambda row: link(row["ma_code"], "class_detail", row["ma_lop"]),
        "Khóa học": "ten_khoa_hoc", "Giảng viên chính": "giang_vien_chinh",
        "Sĩ số": lambda row: f"{row['si_so_hien_tai']} / {row['si_so_toi_da']}",
        "Trạng thái": lambda row: status(row["trang_thai"]),
    }, groups)
    return render(request, "dashboard.html", {
        "title": "Tổng quan", "section": "dashboard", "metrics": metrics, "grid": grid,
        "activity": activity, "activity_total": sum(row["luot"] for row in activity),
    })
