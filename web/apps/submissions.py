import json
import random

from django import forms
from django.contrib import messages
from django.core.exceptions import PermissionDenied
from django.db import DatabaseError
from django.shortcuts import redirect, render
from django.views.decorators.http import require_GET, require_http_methods

from core.auth import ADMIN, STUDENT, TEACHER, can_teach, require_teaching, role_required
from core.db import call_proc, execute, fetch_all
from core.errors import database_message
from .ui import area, form_page, link, options, page, percent, require_row, select, status, table


def result_grid(title, records):
    return table(title, {
        "Lần nộp": lambda r: link(f"#{r['ma_lan_nop']}", "submission", r["ma_lan_nop"]),
        "Ngôn ngữ": "ngon_ngu", "Thời điểm nộp": "thoi_diem_nop",
        "Trạng thái": lambda r: status(r["trang_thai_cham"]),
        "Điểm": lambda r: percent(r["diem"]) if r["diem"] is not None else "—",
    }, records)


@role_required(STUDENT)
@require_http_methods(["GET", "POST"])
def submit(request, assignment_id):
    uid = request.actor["ma_nguoi_dung"]
    item = require_row("""
        SELECT g.*, b.de_bai, NOW(3) < g.han_nop AND l.trang_thai IN ('MO_DANG_KY','DANG_HOC') AS mo_nop,
               d.trang_thai,
               (SELECT COUNT(*) FROM LanNop ln WHERE ln.ma_giao = g.ma_giao AND ln.ma_hoc_vien = d.ma_hoc_vien) AS da_nop
        FROM v_giao_bai g JOIN BaiTap b USING (ma_bai_tap) JOIN LopHoc l USING (ma_lop)
        JOIN DangKyLop d ON d.ma_lop = g.ma_lop AND d.ma_hoc_vien = %s
        WHERE g.ma_giao = %s AND g.thoi_diem_giao <= NOW() AND d.trang_thai <> 'DA_HUY'
    """, [uid, assignment_id])
    languages = options(fetch_all("""
        SELECT n.ma_ngon_ngu, CONCAT(n.ten, ' ', n.phien_ban) AS nhan
        FROM BaiTapNgonNgu b JOIN NgonNguLapTrinh n USING (ma_ngon_ngu)
        WHERE b.ma_bai_tap = %s ORDER BY n.ten
    """, [item["ma_bai_tap"]]), "ma_ngon_ngu", "nhan")
    examples = fetch_all("""
        SELECT thu_tu, mo_ta, du_lieu_vao, ket_qua_mong_doi FROM TestCase
        WHERE ma_bai_tap = %s AND la_test_mau ORDER BY thu_tu
    """, [item["ma_bai_tap"]])
    history = fetch_all("""
        SELECT ln.ma_lan_nop, ln.thoi_diem_nop, ln.trang_thai_cham, d.diem, CONCAT(n.ten, ' ', n.phien_ban) AS ngon_ngu
        FROM LanNop ln JOIN NgonNguLapTrinh n USING (ma_ngon_ngu) LEFT JOIN v_diem_lan_nop d USING (ma_lan_nop)
        WHERE ln.ma_giao = %s AND ln.ma_hoc_vien = %s ORDER BY ln.thoi_diem_nop DESC, ln.ma_lan_nop DESC
    """, [assignment_id, uid])
    form = forms.Form(request.POST if request.method == "POST" else None)
    form.fields["language"] = select("Ngôn ngữ", languages)
    form.fields["code"] = area("Mã nguồn", 65000, css_class="code-input", strip=False)
    can_submit = item["mo_nop"] and item["trang_thai"] == "DANG_HOC" and (
        item["so_lan_nop_toi_da"] is None or item["da_nop"] < item["so_lan_nop_toi_da"])
    if form.is_bound and form.is_valid():
        try:
            new_id = call_proc("sp_nop_bai", [assignment_id, uid, form.cleaned_data["language"], form.cleaned_data["code"]], out=True)
        except DatabaseError as error:
            form.add_error(None, database_message(error))
        else:
            messages.success(request, "Đã nộp bài. Lần nộp đang chờ giảng viên chấm.")
            return redirect("submission", submission_id=new_id)
    return render(request, "submit.html", {
        "title": item["tieu_de"], "section": "classes", "assignment": item, "examples": examples, "form": form,
        "can_submit": can_submit, "grid": result_grid("Lịch sử nộp bài", history),
    })


@role_required(ADMIN, TEACHER)
@require_GET
def queue(request):
    uid = request.actor["ma_nguoi_dung"]
    rows = fetch_all("""
        SELECT ln.ma_lan_nop, ln.thoi_diem_nop, d.ho_ten, g.tieu_de, g.ma_lop_code
        FROM LanNop ln JOIN v_giao_bai g USING (ma_giao) JOIN NguoiDung d ON d.ma_nguoi_dung = ln.ma_hoc_vien
        WHERE ln.trang_thai_cham = 'CHO_CHAM' AND (%s OR EXISTS (
            SELECT 1 FROM PhanCongGiangDay p WHERE p.ma_lop = g.ma_lop AND p.ma_giang_vien = %s
        )) ORDER BY ln.thoi_diem_nop, ln.ma_lan_nop LIMIT 100
    """, [ADMIN in request.actor["roles"], uid])
    grid = table("Lần nộp đang chờ", {
        "Lần nộp": lambda r: link(f"#{r['ma_lan_nop']}", "submission", r["ma_lan_nop"]),
        "Học viên": "ho_ten", "Lớp": "ma_lop_code", "Bài tập": "tieu_de", "Thời điểm": "thoi_diem_nop",
    }, rows, "Chưa có bài chờ chấm.")
    return page(request, "Chờ chấm", "queue", tables=[grid])


def submission_row(submission_id):
    return require_row("""
        SELECT ln.*, g.ma_lop, g.ma_bai_tap, g.ma_lop_code, g.tieu_de, n.ho_ten,
               d.diem, d.so_test_dung, d.tong_test, CONCAT(l.ten, ' ', l.phien_ban) AS ngon_ngu
        FROM LanNop ln JOIN v_giao_bai g USING (ma_giao) JOIN NguoiDung n ON n.ma_nguoi_dung = ln.ma_hoc_vien
        JOIN NgonNguLapTrinh l USING (ma_ngon_ngu) LEFT JOIN v_diem_lan_nop d USING (ma_lan_nop)
        WHERE ln.ma_lan_nop = %s
    """, [submission_id])


@role_required()
@require_GET
def submission(request, submission_id):
    row = submission_row(submission_id)
    teacher = can_teach(request, row["ma_lop"])
    staff = ADMIN in request.actor["roles"] or teacher
    if not staff and row["ma_hoc_vien"] != request.actor["ma_nguoi_dung"]:
        raise PermissionDenied
    outcomes = fetch_all("""
        SELECT t.thu_tu, t.mo_ta, q.ma_loai, q.thoi_gian_chay_ms, q.bo_nho_kb, t.la_test_mau
        FROM KetQuaTest q JOIN TestCase t USING (ma_test) WHERE q.ma_lan_nop = %s ORDER BY t.thu_tu
    """, [submission_id])
    reviews = fetch_all("""
        SELECT x.noi_dung, x.dong_code, x.thoi_diem, n.ho_ten FROM NhanXetLanNop x
        JOIN NguoiDung n ON n.ma_nguoi_dung = x.ma_giang_vien
        WHERE x.ma_lan_nop = %s ORDER BY x.thoi_diem, x.ma_nhan_xet
    """, [submission_id])
    grid = table("Kết quả từng test", {
        "Test": "thu_tu", "Mô tả": lambda r: r["mo_ta"] if staff or r["la_test_mau"] else "Test ẩn",
        "Kết quả": lambda r: status(r["ma_loai"]), "Thời gian (ms)": "thoi_gian_chay_ms", "Bộ nhớ (KB)": "bo_nho_kb",
    }, outcomes, "Lần nộp chưa có kết quả test.")
    return render(request, "submission.html", {
        "title": f"Lần nộp #{submission_id}", "section": "queue" if staff else "classes",
        "submission": row, "outcome": status(row["trang_thai_cham"]),
        "score": percent(row["diem"]) if row["diem"] is not None else "—",
        "can_grade": staff and row["trang_thai_cham"] == "CHO_CHAM", "can_comment": teacher,
        "reviews": reviews, "grid": grid,
        "back": link("Thống kê bài giao", "assignment_report", row["ma_giao"]) if staff else link("Về bài thực hành", "submit", row["ma_giao"]),
    })


@role_required(ADMIN, TEACHER)
@require_http_methods(["GET", "POST"])
def grade(request, submission_id):
    row = submission_row(submission_id)
    require_teaching(request, row["ma_lop"])
    tests = fetch_all("""
        SELECT ma_test, thu_tu, mo_ta, du_lieu_vao, ket_qua_mong_doi
        FROM TestCase WHERE ma_bai_tap = %s ORDER BY thu_tu
    """, [row["ma_bai_tap"]])
    definitions = fetch_all("SELECT ma_loai, ten FROM LoaiKetQua ORDER BY la_dung DESC, ma_loai")
    choices = [(item["ma_loai"], f"{item['ma_loai']} · {item['ten']}") for item in definitions]
    form = forms.Form(request.POST if request.method == "POST" else None)
    for test in tests:
        form.fields[f"test_{test['ma_test']}"] = forms.ChoiceField(
            label=f"Test {test['thu_tu']} · {test['mo_ta']}", choices=choices)
    mode = request.POST.get("mode", "manual")
    if form.is_bound and (mode in {"random", "compile"} or form.is_valid()):
        try:
            if mode == "compile":
                call_proc("sp_loi_bien_dich", [submission_id])
            else:
                codes = random.choices([value for value, _ in choices], k=len(tests)) if mode == "random" else list(form.cleaned_data.values())
                payload = [{"ma_test": test["ma_test"], "ma_loai": code} for test, code in zip(tests, codes)]
                call_proc("sp_ghi_ket_qua_cham", [submission_id, json.dumps(payload)])
        except DatabaseError as error:
            form.add_error(None, database_message(error))
        else:
            messages.success(request, "Đã lưu kết quả chấm.")
            return redirect("submission", submission_id=submission_id)
    return render(request, "grade.html", {
        "title": f"Chấm giả lập · #{submission_id}", "section": "queue", "form": form, "submission": row,
        "can_grade": row["trang_thai_cham"] == "CHO_CHAM",
        "grid": table("Bộ test", {"Test": "thu_tu", "Mô tả": "mo_ta", "Dữ liệu vào": "du_lieu_vao", "Đáp án": "ket_qua_mong_doi"}, tests),
    })


@role_required(TEACHER)
@require_http_methods(["GET", "POST"])
def comment(request, submission_id):
    row = submission_row(submission_id)
    if not can_teach(request, row["ma_lop"]):
        raise PermissionDenied
    fields = {"line": forms.IntegerField(label="Dòng mã nguồn (tùy chọn)", min_value=1, max_value=1000000, required=False),
              "comment": area("Nhận xét", 10000)}

    def save(data):
        execute("""
            INSERT INTO NhanXetLanNop(ma_lan_nop, ma_giang_vien, dong_code, noi_dung) VALUES (%s, %s, %s, %s)
        """, [submission_id, request.actor["ma_nguoi_dung"], data["line"], data["comment"]])

    return form_page(request, f"Nhận xét · Lần nộp #{submission_id}", "queue", fields, save,
                     link("Về lần nộp", "submission", submission_id))
