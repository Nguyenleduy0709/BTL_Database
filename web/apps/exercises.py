from datetime import datetime, timedelta

from django import forms
from django.core.exceptions import PermissionDenied
from django.views.decorators.http import require_GET, require_http_methods

from core.auth import ADMIN, TEACHER, can_teach, role_required
from core.db import call_proc, execute, fetch_all
from .ui import area, enum, form_page, link, options, page, require_row, select, status, table, text, time_field


def exercise_row(request, exercise_id, editing=False):
    row = require_row("SELECT * FROM BaiTap WHERE ma_bai_tap = %s", [exercise_id])
    if editing and ADMIN not in request.actor["roles"] and row["ma_tac_gia"] != request.actor["ma_nguoi_dung"]:
        raise PermissionDenied
    return row


@role_required(ADMIN, TEACHER)
@require_GET
def exercises(request):
    rows = fetch_all("""
        SELECT b.ma_bai_tap, b.ma_code, b.phien_ban, b.tieu_de, b.muc_do, COUNT(t.ma_test) AS so_test
        FROM BaiTap b LEFT JOIN TestCase t USING (ma_bai_tap)
        GROUP BY b.ma_bai_tap ORDER BY b.ma_code, b.phien_ban DESC
    """)
    grid = table("Ngân hàng bài tập", {
        "Mã đề": "ma_code", "Bài tập": lambda r: link(r["tieu_de"], "exercise_detail", r["ma_bai_tap"]),
        "Phiên bản": "phien_ban", "Độ khó": lambda r: status(r["muc_do"]), "Số test": "so_test",
    }, rows)
    return page(request, "Ngân hàng bài tập", "exercises", tables=[grid], actions=[link("Tạo bài tập", "new_exercise")])


@role_required(ADMIN, TEACHER)
@require_GET
def exercise_detail(request, exercise_id):
    exercise = exercise_row(request, exercise_id)
    can_edit = ADMIN in request.actor["roles"] or exercise["ma_tac_gia"] == request.actor["ma_nguoi_dung"]
    tests = fetch_all("SELECT * FROM TestCase WHERE ma_bai_tap = %s ORDER BY thu_tu", [exercise_id])
    locked = require_row("""
        SELECT EXISTS(SELECT 1 FROM GiaoBai g JOIN LanNop ln USING (ma_giao) WHERE g.ma_bai_tap = %s) AS da_khoa
    """, [exercise_id])["da_khoa"]
    languages = fetch_all("""
        SELECT n.ten, n.phien_ban FROM BaiTapNgonNgu bn JOIN NgonNguLapTrinh n USING (ma_ngon_ngu)
        WHERE bn.ma_bai_tap = %s ORDER BY n.ten
    """, [exercise_id])
    columns = {"Test": "thu_tu", "Mô tả": "mo_ta", "Đầu vào": "du_lieu_vao", "Đáp án": "ket_qua_mong_doi",
               "Trọng số": "trong_so", "Hiển thị": lambda r: "Test mẫu" if r["la_test_mau"] else "Test ẩn"}
    actions = []
    if can_edit:
        actions.append(link("Tạo phiên bản mới", "copy_exercise", exercise_id))
        if not locked:
            actions += [link("Thêm test", "new_test", exercise_id), link("Sửa đề", "edit_exercise", exercise_id)]
            columns.update({"Sửa": lambda r: link("Sửa", "edit_test", exercise_id, r["ma_test"]),
                            "Xóa": lambda r: link("Xóa", "delete_test", exercise_id, r["ma_test"])})
    return page(request, exercise["tieu_de"], "exercises", actions=actions, description=exercise["de_bai"],
                intro=f"{exercise['ma_code']} · Phiên bản {exercise['phien_ban']}",
                notice="Đề và bộ test đã được sử dụng. Tạo phiên bản mới để chỉnh sửa." if locked else "",
                tables=[table("Bộ test", columns, tests), table("Ngôn ngữ được phép", {"Ngôn ngữ": "ten", "Phiên bản": "phien_ban"}, languages)])


@role_required(ADMIN, TEACHER)
@require_http_methods(["GET", "POST"])
def edit_exercise(request, exercise_id=None):
    original = exercise_row(request, exercise_id, editing=True) if exercise_id else None
    fields = {} if original else {"ma_code": text("Mã đề", 30)}
    fields.update({"tieu_de": text("Tiêu đề"), "de_bai": area("Đề bài"),
                   "muc_do": enum("Độ khó", ["DE", "TRUNG_BINH", "KHO"])})
    if not original:
        languages = options(fetch_all("""
            SELECT ma_ngon_ngu, CONCAT(ten, ' ', phien_ban) AS nhan FROM NgonNguLapTrinh ORDER BY ma_ngon_ngu
        """), "ma_ngon_ngu", "nhan")
        topics = options(fetch_all("SELECT ma_chu_de, ten_chu_de FROM ChuDe ORDER BY ten_chu_de"), "ma_chu_de", "ten_chu_de")
        fields.update({"language": select("Ngôn ngữ", languages), "topic": select("Chủ đề", topics, required=False)})

    def save(data):
        if original:
            execute("UPDATE BaiTap SET tieu_de=%s, de_bai=%s, muc_do=%s WHERE ma_bai_tap=%s", [*data.values(), exercise_id])
            new_id = exercise_id
        else:
            new_id = call_proc("sp_tao_bai_tap", [data["ma_code"], data["tieu_de"], data["de_bai"], data["muc_do"],
                                                  request.actor["ma_nguoi_dung"], data["language"], data["topic"]], out=True)
        return link("", "exercise_detail", new_id).url

    return form_page(request, "Sửa bài tập" if original else "Tạo bài tập", "exercises", fields, save,
                     link("Ngân hàng bài tập", "exercises"), initial=original)


@role_required(ADMIN, TEACHER)
@require_http_methods(["GET", "POST"])
def copy_exercise(request, exercise_id):
    exercise = exercise_row(request, exercise_id, editing=True)

    def save(data):
        new_id = call_proc("sp_tao_phien_ban_bai_tap", [exercise_id], out=True)
        return link("", "exercise_detail", new_id).url

    return form_page(request, f"Tạo phiên bản mới · {exercise['ma_code']}", "exercises", {}, save,
                     link("Về bài tập", "exercise_detail", exercise_id),
                     description="MySQL sao chép đề, chủ đề, ngôn ngữ và bộ test sang phiên bản mới.", submit="Tạo phiên bản")


@role_required(ADMIN, TEACHER)
@require_http_methods(["GET", "POST"])
def edit_test(request, exercise_id, test_id=None):
    exercise_row(request, exercise_id, editing=True)
    original = require_row("SELECT * FROM TestCase WHERE ma_bai_tap = %s AND ma_test = %s",
                           [exercise_id, test_id]) if test_id else None
    fields = {
        "thu_tu": forms.IntegerField(label="Thứ tự", min_value=1, max_value=65535),
        "mo_ta": text("Mô tả", 255), "du_lieu_vao": area("Dữ liệu vào", 10000, required=False),
        "ket_qua_mong_doi": area("Kết quả mong đợi", 10000, required=False),
        "trong_so": forms.DecimalField(label="Trọng số", min_value=0.01, max_digits=5, decimal_places=2),
        "la_test_mau": forms.BooleanField(label="Cho học viên xem test mẫu", required=False),
    }

    def save(data):
        if original:
            execute("""
                UPDATE TestCase SET thu_tu=%s, mo_ta=%s, du_lieu_vao=%s, ket_qua_mong_doi=%s, trong_so=%s, la_test_mau=%s
                WHERE ma_bai_tap=%s AND ma_test=%s
            """, [*data.values(), exercise_id, test_id])
        else:
            execute("""
                INSERT INTO TestCase(ma_bai_tap, thu_tu, mo_ta, du_lieu_vao, ket_qua_mong_doi, trong_so, la_test_mau)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, [exercise_id, *data.values()])

    return form_page(request, "Sửa test" if original else "Thêm test", "exercises", fields, save,
                     link("Về bài tập", "exercise_detail", exercise_id), initial=original or {"trong_so": 1})


@role_required(ADMIN, TEACHER)
@require_http_methods(["GET", "POST"])
def delete_test(request, exercise_id, test_id):
    exercise_row(request, exercise_id, editing=True)
    row = require_row("SELECT mo_ta FROM TestCase WHERE ma_test = %s AND ma_bai_tap = %s", [test_id, exercise_id])

    def save(data):
        execute("DELETE FROM TestCase WHERE ma_test = %s AND ma_bai_tap = %s", [test_id, exercise_id])

    return form_page(request, f"Xóa test · {row['mo_ta']}", "exercises", {}, save,
                     link("Về bài tập", "exercise_detail", exercise_id), submit="Xác nhận xóa")


@role_required(TEACHER)
@require_http_methods(["GET", "POST"])
def assign_exercise(request, class_id):
    if not can_teach(request, class_id):
        raise PermissionDenied
    group = require_row("SELECT ma_code FROM LopHoc WHERE ma_lop = %s", [class_id])
    choices = options(fetch_all("""
        SELECT b.ma_bai_tap, CONCAT(b.tieu_de, ' · v', b.phien_ban) AS nhan FROM BaiTap b
        WHERE EXISTS (SELECT 1 FROM TestCase t WHERE t.ma_bai_tap = b.ma_bai_tap)
          AND NOT EXISTS (SELECT 1 FROM GiaoBai g WHERE g.ma_bai_tap = b.ma_bai_tap AND g.ma_lop = %s)
        ORDER BY b.ma_code, b.phien_ban DESC
    """, [class_id]), "ma_bai_tap", "nhan")
    lessons = options(fetch_all("""
        SELECT b.ma_bai_hoc, b.tieu_de FROM LopHoc l JOIN Chuong c USING (ma_khoa_hoc)
        JOIN BaiHoc b USING (ma_chuong) WHERE l.ma_lop = %s ORDER BY c.thu_tu, b.thu_tu
    """, [class_id]), "ma_bai_hoc", "tieu_de")
    fields = {
        "exercise": select("Bài tập và phiên bản", choices), "lesson": select("Bài học liên quan", lessons, required=False),
        "deadline": time_field("Hạn nộp"), "required": forms.BooleanField(label="Bài bắt buộc", required=False),
        "attempts": forms.IntegerField(label="Số lượt tối đa (để trống nếu không giới hạn)", required=False, min_value=1, max_value=65535),
    }

    def save(data):
        new_id = call_proc("sp_giao_bai", [class_id, data["exercise"], data["lesson"], request.actor["ma_nguoi_dung"],
                                          data["deadline"], data["required"], data["attempts"]], out=True)
        return link("", "assignment_report", new_id).url

    return form_page(request, f"Giao bài · {group['ma_code']}", "classes", fields, save,
                     link("Về lớp học", "class_detail", class_id),
                     initial={"deadline": datetime.now() + timedelta(days=7), "required": True})
