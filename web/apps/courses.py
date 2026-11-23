from django import forms
from django.shortcuts import redirect, render
from django.views.decorators.http import require_GET, require_http_methods

from core.auth import ADMIN, STUDENT, role_required
from core.db import execute, fetch_all
from .ui import STATUS, area, enum, form_page, link, money, options, require_row, select, text

LEVELS = ("CO_BAN", "TRUNG_CAP", "NANG_CAO")


def is_admin(request):
    return bool(request.actor and ADMIN in request.actor["roles"])


def student_id(request):
    if request.actor and STUDENT in request.actor["roles"]:
        return request.actor["ma_nguoi_dung"]
    return None


@require_GET
def courses(request):
    search = request.GET.get("q", "").strip()[:120]
    level = request.GET.get("trinh_do", "")
    level = level if level in LEVELS else ""
    catalog = fetch_all("""
        SELECT k.ma_khoa_hoc, k.ma_code, k.ten_khoa_hoc, k.mo_ta, k.trang_thai,
               k.trinh_do, d.ten_danh_muc, COUNT(DISTINCT c.ma_chuong) AS so_chuong,
               COUNT(b.ma_bai_hoc) AS so_bai, COALESCE(SUM(b.thoi_luong_phut), 0) AS so_phut,
               hv.ma_khoa_hoc IS NOT NULL AS da_dang_ky
        FROM KhoaHoc k JOIN DanhMucKhoaHoc d USING (ma_danh_muc)
        LEFT JOIN Chuong c ON c.ma_khoa_hoc = k.ma_khoa_hoc
        LEFT JOIN BaiHoc b ON b.ma_chuong = c.ma_chuong
        LEFT JOIN (
            SELECT DISTINCT l.ma_khoa_hoc FROM DangKyLop dk JOIN LopHoc l USING (ma_lop)
            WHERE dk.ma_hoc_vien = %s AND dk.trang_thai <> 'DA_HUY'
        ) hv ON hv.ma_khoa_hoc = k.ma_khoa_hoc
        WHERE (%s OR k.trang_thai = 'CONG_BO' OR hv.ma_khoa_hoc IS NOT NULL)
          AND (%s = '' OR k.trinh_do = %s)
          AND (%s = '' OR LOCATE(%s, k.ten_khoa_hoc) > 0 OR LOCATE(%s, d.ten_danh_muc) > 0
                       OR LOCATE(%s, k.ma_code) > 0)
        GROUP BY k.ma_khoa_hoc, d.ten_danh_muc, hv.ma_khoa_hoc
        ORDER BY da_dang_ky DESC, k.ten_khoa_hoc
    """, [student_id(request), is_admin(request), level, level, search, search, search, search])
    for course in catalog:
        course["level_name"] = STATUS[course["trinh_do"]]
        course["state_name"] = STATUS[course["trang_thai"]]
    return render(request, "courses.html", {
        "title": "Khóa học", "section": "courses", "public_catalog": True, "courses": catalog,
        "can_edit": is_admin(request), "search": search, "level": level,
        "levels": [(item, STATUS[item]) for item in LEVELS],
    })


def visible_course(request, course_id):
    return require_row("""
        SELECT k.*, dm.ten_danh_muc FROM KhoaHoc k JOIN DanhMucKhoaHoc dm USING (ma_danh_muc)
        WHERE k.ma_khoa_hoc = %s AND (k.trang_thai = 'CONG_BO' OR %s OR EXISTS (
            SELECT 1 FROM DangKyLop dk JOIN LopHoc l USING (ma_lop)
            WHERE l.ma_khoa_hoc = k.ma_khoa_hoc AND dk.ma_hoc_vien = %s AND dk.trang_thai <> 'DA_HUY'
        ))
    """, [course_id, is_admin(request), student_id(request)])


def curriculum(course_id, registration_id=None):
    rows = fetch_all("""
        SELECT c.ma_chuong, c.thu_tu AS so_chuong, c.ten_chuong,
               b.ma_bai_hoc, b.tieu_de, b.thoi_luong_phut, t.thoi_diem_hoan_thanh
        FROM Chuong c LEFT JOIN BaiHoc b USING (ma_chuong)
        LEFT JOIN TienDoBaiHoc t ON t.ma_bai_hoc = b.ma_bai_hoc AND t.ma_dang_ky = %s
        WHERE c.ma_khoa_hoc = %s ORDER BY c.thu_tu, b.thu_tu
    """, [registration_id, course_id])
    chapters = {}
    for row in rows:
        chapter = chapters.setdefault(row["ma_chuong"], {
            "ma_chuong": row["ma_chuong"], "thu_tu": row["so_chuong"],
            "ten_chuong": row["ten_chuong"], "lessons": [],
        })
        if row["ma_bai_hoc"] is not None:
            chapter["lessons"].append(row)
    return list(chapters.values())


@require_GET
def course_detail(request, course_id):
    course = visible_course(request, course_id)
    groups = fetch_all("""
        SELECT l.ma_lop, l.ma_code, l.ngay_bat_dau, l.ngay_ket_thuc, l.giang_vien_chinh, l.hoc_phi,
               GREATEST(CAST(l.si_so_toi_da AS SIGNED) - l.si_so_hien_tai, 0) AS so_cho_con,
               dk.ma_dang_ky
        FROM v_lop_hoc l LEFT JOIN DangKyLop dk
            ON dk.ma_lop = l.ma_lop AND dk.ma_hoc_vien = %s AND dk.trang_thai <> 'DA_HUY'
        WHERE l.ma_khoa_hoc = %s AND (dk.ma_dang_ky IS NOT NULL OR
               (l.trang_thai = 'MO_DANG_KY' AND %s AND (%s OR l.si_so_hien_tai < l.si_so_toi_da)))
        ORDER BY FIELD(l.trang_thai, 'DANG_HOC', 'MO_DANG_KY', 'KET_THUC', 'HUY'),
                 l.ngay_bat_dau, l.ma_lop
    """, [student_id(request), course_id, course["trang_thai"] == "CONG_BO" or is_admin(request), is_admin(request)])
    enrolled = [group for group in groups if group["ma_dang_ky"]]
    group = enrolled[0] if enrolled else None
    open_groups = [item for item in groups if not item["ma_dang_ky"]]
    for item in open_groups:
        item["fee"] = money(item["hoc_phi"]) if item["hoc_phi"] else "Miễn phí"
    chapters = curriculum(course_id, group["ma_dang_ky"] if group else None)
    lessons = [lesson for chapter in chapters for lesson in chapter["lessons"]]
    completed = sum(lesson["thoi_diem_hoan_thanh"] is not None for lesson in lessons)
    first_lesson = lessons[0] if lessons else None
    next_lesson = next((item for item in lessons if not item["thoi_diem_hoan_thanh"]), first_lesson)
    return render(request, "course.html", {
        "title": course["ten_khoa_hoc"], "section": "courses", "public_catalog": True,
        "course": course, "level_name": STATUS[course["trinh_do"]], "chapters": chapters,
        "lesson_count": len(lessons), "minutes": sum(lesson["thoi_luong_phut"] for lesson in lessons),
        "completed": completed, "first_lesson": first_lesson, "next_lesson": next_lesson,
        "group": group, "enrolled": enrolled, "open_groups": open_groups,
        "can_edit": is_admin(request), "is_student": student_id(request) is not None,
    })


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def edit_course(request, course_id=None):
    original = require_row("SELECT * FROM KhoaHoc WHERE ma_khoa_hoc = %s", [course_id]) if course_id else None
    categories = options(fetch_all("SELECT ma_danh_muc, ten_danh_muc FROM DanhMucKhoaHoc ORDER BY ten_danh_muc"),
                         "ma_danh_muc", "ten_danh_muc")
    fields = {
        "ma_code": text("Mã khóa học", 20), "ten_khoa_hoc": text("Tên khóa học"),
        "ma_danh_muc": select("Danh mục", categories), "mo_ta": area("Mô tả", required=False),
        "trinh_do": enum("Trình độ", ["CO_BAN", "TRUNG_CAP", "NANG_CAO"]),
        "trang_thai": enum("Trạng thái", ["NHAP", "CONG_BO", "NGUNG"]),
    }

    def save(data):
        values = [
            data["ma_code"], data["ten_khoa_hoc"], data["ma_danh_muc"],
            data["mo_ta"], data["trinh_do"], data["trang_thai"],
        ]
        if original:
            execute("""
                UPDATE KhoaHoc SET ma_code=%s, ten_khoa_hoc=%s, ma_danh_muc=%s, mo_ta=%s,
                                   trinh_do=%s, trang_thai=%s WHERE ma_khoa_hoc=%s
            """, [*values, course_id])
            return link("", "course_detail", course_id).url
        new_id = execute("""
            INSERT INTO KhoaHoc(ma_code, ten_khoa_hoc, ma_danh_muc, mo_ta, trinh_do, trang_thai, ma_nguoi_tao)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, [*values, request.actor["ma_nguoi_dung"]])
        return link("", "course_detail", new_id).url

    return form_page(request, "Sửa khóa học" if original else "Tạo khóa học", "courses", fields, save,
                     link("Khóa học", "courses"), initial=original)


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def edit_chapter(request, parent_id, chapter_id=None):
    require_row("SELECT ma_khoa_hoc FROM KhoaHoc WHERE ma_khoa_hoc = %s", [parent_id])
    original = require_row("SELECT * FROM Chuong WHERE ma_chuong = %s AND ma_khoa_hoc = %s",
                           [chapter_id, parent_id]) if chapter_id else None
    fields = {"thu_tu": forms.IntegerField(label="Thứ tự", min_value=1, max_value=65535),
              "ten_chuong": text("Tên chương")}

    def save(data):
        values = [data["thu_tu"], data["ten_chuong"]]
        if original:
            execute("UPDATE Chuong SET thu_tu=%s, ten_chuong=%s WHERE ma_chuong=%s", [*values, chapter_id])
        else:
            execute("INSERT INTO Chuong(ma_khoa_hoc, thu_tu, ten_chuong) VALUES (%s, %s, %s)", [parent_id, *values])

    return form_page(request, "Sửa chương" if original else "Tạo chương", "courses", fields, save,
                     link("Khóa học", "course_detail", parent_id), initial=original)


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def edit_lesson(request, parent_id, lesson_id=None):
    chapter = require_row("SELECT ma_khoa_hoc, ten_chuong FROM Chuong WHERE ma_chuong = %s", [parent_id])
    original = require_row("SELECT * FROM BaiHoc WHERE ma_bai_hoc = %s AND ma_chuong = %s",
                           [lesson_id, parent_id]) if lesson_id else None
    fields = {
        "thu_tu": forms.IntegerField(label="Thứ tự", min_value=1, max_value=65535), "tieu_de": text("Tên bài học"),
        "noi_dung": area("Nội dung"), "thoi_luong_phut": forms.IntegerField(label="Thời lượng (phút)", min_value=1, max_value=65535),
    }

    def save(data):
        values = [data["thu_tu"], data["tieu_de"], data["noi_dung"], data["thoi_luong_phut"]]
        if original:
            execute("UPDATE BaiHoc SET thu_tu=%s, tieu_de=%s, noi_dung=%s, thoi_luong_phut=%s WHERE ma_bai_hoc=%s",
                    [*values, lesson_id])
        else:
            execute("INSERT INTO BaiHoc(ma_chuong, thu_tu, tieu_de, noi_dung, thoi_luong_phut) VALUES (%s, %s, %s, %s, %s)",
                    [parent_id, *values])

    fields["noi_dung"].widget.attrs["rows"] = 16
    fields["noi_dung"].help_text = "Bắt đầu tiêu đề mục bằng ##. Đặt ví dụ mã giữa hai dòng có ba dấu backtick."
    return form_page(request, "Sửa bài học" if original else "Tạo bài học", "courses", fields, save,
                     link("Khóa học", "course_detail", chapter["ma_khoa_hoc"]), initial=original)


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def delete_content(request, kind, object_id):
    if kind == "course":
        row = require_row("SELECT ten_khoa_hoc AS ten FROM KhoaHoc WHERE ma_khoa_hoc = %s", [object_id])
        sql = "DELETE FROM KhoaHoc WHERE ma_khoa_hoc = %s"
        back = link("Khóa học", "courses")
    elif kind == "chapter":
        row = require_row("SELECT ten_chuong AS ten, ma_khoa_hoc FROM Chuong WHERE ma_chuong = %s", [object_id])
        sql = "DELETE FROM Chuong WHERE ma_chuong = %s"
        back = link("Khóa học", "course_detail", row["ma_khoa_hoc"])
    elif kind == "lesson":
        row = require_row("SELECT tieu_de AS ten, ma_khoa_hoc FROM BaiHoc JOIN Chuong USING (ma_chuong) WHERE ma_bai_hoc = %s", [object_id])
        sql = "DELETE FROM BaiHoc WHERE ma_bai_hoc = %s"
        back = link("Khóa học", "course_detail", row["ma_khoa_hoc"])
    else:
        return redirect("courses")

    def save(data):
        execute(sql, [object_id])
        return back.url

    return form_page(request, f"Xóa {row['ten']}", "courses", {}, save, back,
                     description="Nội dung liên quan sẽ được kiểm tra bằng khóa ngoại MySQL.", submit="Xác nhận xóa")
