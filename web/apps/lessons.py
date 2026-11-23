import re

from django.http import Http404
from django.shortcuts import render
from django.views.decorators.http import require_GET, require_POST

from core.auth import STUDENT, role_required
from core.db import execute
from .courses import curriculum, is_admin, visible_course
from .ui import action, link, require_row

CONTENT_MARKERS = re.compile(r"^```[^\n`]*\n(.*?)^```[ \t]*$|^##[ \t]+([^\n]+)$", re.MULTILINE | re.DOTALL)


def lesson_blocks(content):
    content = content.replace("\r\n", "\n").replace("\r", "\n")
    end = 0
    for match in CONTENT_MARKERS.finditer(content):
        if paragraph := content[end:match.start()].strip():
            yield ("text", paragraph)
        if match[1] is not None:
            yield ("code", match[1].removesuffix("\n"))
        else:
            yield ("heading", match[2].strip())
        end = match.end()
    if paragraph := content[end:].strip():
        yield ("text", paragraph)


def member_lesson(request, class_id, lesson_id):
    return require_row("""
        SELECT b.*, c.ten_chuong, c.ma_khoa_hoc, l.ma_code, k.ten_khoa_hoc,
               d.ma_dang_ky, t.thoi_diem_hoan_thanh
        FROM DangKyLop d JOIN LopHoc l USING (ma_lop) JOIN Chuong c USING (ma_khoa_hoc)
        JOIN KhoaHoc k ON k.ma_khoa_hoc = c.ma_khoa_hoc
        JOIN BaiHoc b USING (ma_chuong)
        LEFT JOIN TienDoBaiHoc t ON t.ma_bai_hoc = b.ma_bai_hoc AND t.ma_dang_ky = d.ma_dang_ky
        WHERE d.ma_lop = %s AND b.ma_bai_hoc = %s AND d.ma_hoc_vien = %s AND d.trang_thai <> 'DA_HUY'
    """, [class_id, lesson_id, request.actor["ma_nguoi_dung"]])


@role_required(STUDENT)
@require_GET
def lesson(request, class_id, lesson_id):
    row = member_lesson(request, class_id, lesson_id)
    chapters = curriculum(row["ma_khoa_hoc"], row["ma_dang_ky"])
    ids = [item["ma_bai_hoc"] for chapter in chapters for item in chapter["lessons"]]
    if lesson_id not in ids:
        raise Http404
    position = ids.index(lesson_id)
    return render(request, "lesson.html", {
        "title": row["tieu_de"], "section": "courses", "lesson": row, "class_id": class_id,
        "blocks": list(lesson_blocks(row["noi_dung"])), "chapters": chapters,
        "previous_id": ids[position - 1] if position else None,
        "next_id": ids[position + 1] if position + 1 < len(ids) else None,
    })


@require_GET
def preview(request, course_id, lesson_id):
    course = visible_course(request, course_id)
    if not is_admin(request):
        first = require_row("""
            SELECT b.ma_bai_hoc FROM Chuong c JOIN BaiHoc b USING (ma_chuong)
            WHERE c.ma_khoa_hoc = %s ORDER BY c.thu_tu, b.thu_tu LIMIT 1
        """, [course_id])
        if first["ma_bai_hoc"] != lesson_id:
            raise Http404
    row = require_row("""
        SELECT b.*, c.ten_chuong, c.ma_khoa_hoc FROM BaiHoc b JOIN Chuong c USING (ma_chuong)
        WHERE c.ma_khoa_hoc = %s AND b.ma_bai_hoc = %s
    """, [course_id, lesson_id])
    row["ten_khoa_hoc"] = course["ten_khoa_hoc"]
    return render(request, "lesson.html", {
        "title": row["tieu_de"], "section": "courses", "public_catalog": True, "lesson": row,
        "blocks": list(lesson_blocks(row["noi_dung"])),
    })


@role_required(STUDENT)
@require_POST
def complete(request, class_id, lesson_id):
    row = member_lesson(request, class_id, lesson_id)
    return action(request, lambda: execute("""
        INSERT INTO TienDoBaiHoc(ma_dang_ky, ma_bai_hoc) VALUES (%s, %s)
        ON DUPLICATE KEY UPDATE thoi_diem_hoan_thanh = thoi_diem_hoan_thanh
    """, [row["ma_dang_ky"], lesson_id]), link("", "lesson", class_id, lesson_id).url, "Đã đánh dấu hoàn thành.")
