from django.shortcuts import render
from django.views.decorators.http import require_GET

from core.auth import ADMIN, TEACHER, require_teaching, role_required
from core.db import call_proc, fetch_all, fetch_one
from .ui import link, page, percent, require_row, status, table


@role_required(ADMIN, TEACHER)
@require_GET
def assignment_report(request, assignment_id):
    assignment = require_row("SELECT * FROM v_giao_bai WHERE ma_giao = %s", [assignment_id])
    require_teaching(request, assignment["ma_lop"])
    overview = fetch_one("SELECT * FROM v_thong_ke_bai_giao WHERE ma_giao = %s", [assignment_id])
    students = fetch_all("""
        SELECT s.*, n.ho_ten FROM v_trang_thai_hoc_vien_bai_giao s
        JOIN NguoiDung n ON n.ma_nguoi_dung = s.ma_hoc_vien
        WHERE s.ma_giao = %s ORDER BY s.ma_hoc_vien
    """, [assignment_id])
    errors = fetch_all("""
        SELECT thu_tu, mo_ta, so_nguoi_co_ket_qua, so_nguoi_sai FROM v_loi_lan_gan_nhat
        WHERE ma_giao = %s ORDER BY so_nguoi_sai DESC, thu_tu
    """, [assignment_id])
    metrics = [(label, overview[key], short) for label, key, short in [
        ("Lượt nộp", "tong_luot", "LN"), ("Đã thử", "da_thu", "ĐT"), ("Đạt", "dat", "OK"),
        ("Chưa đạt", "chua_dat", "CĐ"), ("Chưa nộp", "chua_nop", "CN"),
    ]]
    grid = table("Kết quả theo học viên", {
        "Học viên": "ho_ten", "Lượt nộp": "so_lan_nop", "Lượt đã chấm": "so_lan_da_cham",
        "Điểm tốt nhất": lambda row: percent(row["diem_tot_nhat"]) if row["diem_tot_nhat"] is not None else "—",
        "Trạng thái": lambda row: status(row["trang_thai"]),
    }, students)
    return render(request, "assignment.html", {
        "title": assignment["tieu_de"], "assignment": assignment, "section": "classes",
        "metrics": metrics, "grid": grid, "errors": errors, "pending": overview["cho_cham"],
    })


@role_required(ADMIN, TEACHER)
@require_GET
def class_report(request, class_id):
    require_teaching(request, class_id)
    _, rankings, absent, errors = call_proc("sp_bao_cao_lop", [class_id])
    group = require_row("SELECT ma_code FROM LopHoc WHERE ma_lop = %s", [class_id])
    assignments = fetch_all("SELECT ma_giao, ma_bai, phien_ban FROM v_giao_bai WHERE ma_lop = %s ORDER BY ma_giao LIMIT 30", [class_id])
    pivot_columns = {"Học viên": "ho_ten"}
    pivot_select = []
    pivots = [row["ma_giao"] for row in assignments]
    for index, row in enumerate(assignments, 1):
        name = f"cot_{index}"
        pivot_columns[f"{row['ma_bai']} v{row['phien_ban']}"] = name
        pivot_select.append(f"MAX(CASE WHEN s.ma_giao = %s THEN s.diem_tot_nhat END) AS {name}")
    matrix = []
    if pivots:
        matrix = fetch_all(f"""
            SELECT n.ho_ten, {', '.join(pivot_select)}
            FROM DangKyLop d JOIN NguoiDung n ON n.ma_nguoi_dung = d.ma_hoc_vien
            LEFT JOIN v_trang_thai_hoc_vien_bai_giao s USING (ma_dang_ky)
            WHERE d.ma_lop = %s AND d.trang_thai <> 'DA_HUY'
            GROUP BY n.ma_nguoi_dung, n.ho_ten ORDER BY n.ho_ten
        """, [*pivots, class_id])
    grids = [
        table("Bảng điểm theo bài (tối đa 30 bài)", pivot_columns, matrix, "Chưa có bài giao."),
        table("Xếp hạng thực hành", {"Hạng": "xep_hang", "Học viên": "ho_ten", "Bài đạt": "so_da_dat",
                                    "Tiến độ": lambda r: percent(r["tien_do"]), "Điểm TB": "diem_trung_binh"}, rankings),
        table("Học viên chưa nộp", {"Học viên": "ho_ten", "Bài": "tieu_de", "Hạn nộp": "han_nop"}, absent),
        table("Lỗi ở lượt gần nhất", {"Bài": "tieu_de", "Test": "thu_tu", "Mô tả": "mo_ta", "Số người sai": "so_nguoi_sai"}, errors),
    ]
    return page(request, f"Bảng điểm · {group['ma_code']}", "classes",
                actions=[link("Về lớp học", "class_detail", class_id)], tables=grids)
