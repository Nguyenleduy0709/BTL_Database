from django import forms
from django.core.exceptions import PermissionDenied
from django.shortcuts import render
from django.views.decorators.http import require_GET, require_http_methods, require_POST

from core.auth import ADMIN, STUDENT, TEACHER, can_teach, require_teaching, role_required
from core.db import call_proc, execute, fetch_all, fetch_one
from .ui import action, area, day_field, enum, form_page, link, money, options, page, require_row, select, status, table, text, time_field


def admin(request):
    return ADMIN in request.actor["roles"]


def enrollment(request, class_id):
    return fetch_one("SELECT * FROM DangKyLop WHERE ma_lop = %s AND ma_hoc_vien = %s",
                     [class_id, request.actor["ma_nguoi_dung"]])


def teachers():
    return options(fetch_all("""
        SELECT n.ma_nguoi_dung, n.ho_ten FROM NguoiDung n JOIN NguoiDungVaiTro nv USING (ma_nguoi_dung)
        JOIN VaiTro v USING (ma_vai_tro) WHERE v.ten_vai_tro = 'GIANG_VIEN' AND n.trang_thai = 'HOAT_DONG'
        ORDER BY n.ho_ten
    """), "ma_nguoi_dung", "ho_ten")


@role_required()
@require_GET
def classes(request):
    uid = request.actor["ma_nguoi_dung"]
    if admin(request):
        rows = fetch_all("SELECT * FROM v_lop_hoc ORDER BY ma_lop")
    elif TEACHER in request.actor["roles"]:
        rows = fetch_all("""
            SELECT DISTINCT l.* FROM v_lop_hoc l JOIN KhoaHoc k USING (ma_khoa_hoc)
            LEFT JOIN PhanCongGiangDay p ON p.ma_lop = l.ma_lop AND p.ma_giang_vien = %s
            LEFT JOIN DangKyLop d ON d.ma_lop = l.ma_lop AND d.ma_hoc_vien = %s AND d.trang_thai <> 'DA_HUY'
            WHERE p.ma_giang_vien IS NOT NULL OR (%s AND (d.ma_dang_ky IS NOT NULL OR
                  (l.trang_thai = 'MO_DANG_KY' AND k.trang_thai = 'CONG_BO')))
            ORDER BY l.ma_lop
        """, [uid, uid, STUDENT in request.actor["roles"]])
    else:
        rows = fetch_all("""
            SELECT l.* FROM v_lop_hoc l JOIN KhoaHoc k USING (ma_khoa_hoc) LEFT JOIN DangKyLop d
              ON d.ma_lop = l.ma_lop AND d.ma_hoc_vien = %s AND d.trang_thai <> 'DA_HUY'
            WHERE (l.trang_thai = 'MO_DANG_KY' AND k.trang_thai = 'CONG_BO')
                   OR d.ma_dang_ky IS NOT NULL ORDER BY l.ma_lop
        """, [uid])
    grid = table("Danh sách lớp học", {
        "Mã lớp": lambda r: link(r["ma_code"], "class_detail", r["ma_lop"]), "Khóa học": "ten_khoa_hoc",
        "Giảng viên chính": "giang_vien_chinh", "Chỗ còn": lambda r: r["si_so_toi_da"] - r["si_so_hien_tai"],
        "Học phí": lambda r: money(r["hoc_phi"]), "Trạng thái": lambda r: status(r["trang_thai"]),
    }, rows)
    return page(request, "Lớp học", "classes", tables=[grid],
                actions=[link("Mở lớp mới", "new_class")] if admin(request) else [])


@role_required()
@require_GET
def class_detail(request, class_id):
    group = require_row("""
        SELECT l.*, k.trang_thai AS trang_thai_khoa_hoc
        FROM v_lop_hoc l JOIN KhoaHoc k USING (ma_khoa_hoc) WHERE l.ma_lop = %s
    """, [class_id])
    staff = admin(request) or can_teach(request, class_id)
    enrolled = enrollment(request, class_id)
    member = bool(enrolled and enrolled["trang_thai"] != "DA_HUY")
    student = STUDENT in request.actor["roles"]
    registration_open = group["trang_thai"] == "MO_DANG_KY" and group["trang_thai_khoa_hoc"] == "CONG_BO"
    if not (staff or member or student and registration_open):
        raise PermissionDenied

    actions = []
    grids = []
    if admin(request):
        actions += [link("Sửa lớp", "edit_class", class_id), link("Phân công giảng dạy", "assign_teacher", class_id)]
        assignments = fetch_all("""
            SELECT n.ho_ten, p.vai_tro_day FROM PhanCongGiangDay p JOIN NguoiDung n ON n.ma_nguoi_dung = p.ma_giang_vien
            WHERE p.ma_lop = %s ORDER BY p.la_chinh DESC, n.ho_ten
        """, [class_id])
        grids.append(table("Phân công", {"Giảng viên": "ho_ten", "Vai trò": lambda r: status(r["vai_tro_day"])}, assignments))
    if can_teach(request, class_id):
        actions.append(link("Giao bài", "assign_exercise", class_id))
    if staff:
        actions += [link("Bảng điểm", "class_report", class_id), link("Thêm buổi học", "new_session", class_id),
                    link("Đăng thông báo", "new_notice", class_id)]
    if staff or member:
        exercises = fetch_all("SELECT * FROM v_giao_bai WHERE ma_lop = %s AND thoi_diem_giao <= NOW() ORDER BY han_nop", [class_id])
        grids.append(table("Bài thực hành", {
            "Bài tập": lambda r: link(r["tieu_de"], "assignment_report" if staff else "submit", r["ma_giao"]),
            "Phiên bản": "phien_ban", "Hạn nộp": "han_nop",
            "Yêu cầu": lambda r: "Bắt buộc" if r["bat_buoc"] else "Tự chọn",
        }, exercises))
        meetings = fetch_all("SELECT * FROM BuoiHoc WHERE ma_lop = %s ORDER BY so_thu_tu", [class_id])
        grids.append(table("Lịch học", {
            "Buổi": (lambda r: link(f"Buổi {r['so_thu_tu']}", "attendance", r["ma_buoi"])) if staff else "so_thu_tu",
            "Bắt đầu": "bat_dau", "Kết thúc": "ket_thuc", "Địa điểm": "dia_diem",
        }, meetings))
    notices = fetch_all("SELECT * FROM ThongBaoLop WHERE ma_lop = %s ORDER BY ghim DESC, thoi_diem_dang DESC", [class_id]) if staff or member else []
    lessons = fetch_all("""
        SELECT b.ma_bai_hoc, b.tieu_de, c.ten_chuong, t.thoi_diem_hoan_thanh
        FROM LopHoc l JOIN Chuong c USING (ma_khoa_hoc) JOIN BaiHoc b USING (ma_chuong)
        LEFT JOIN TienDoBaiHoc t ON t.ma_bai_hoc = b.ma_bai_hoc AND t.ma_dang_ky = %s
        WHERE l.ma_lop = %s ORDER BY c.thu_tu, b.thu_tu
    """, [enrolled["ma_dang_ky"], class_id]) if member else []
    return render(request, "class.html", {
        "title": f"{group['ma_code']} · {group['ten_khoa_hoc']}", "section": "classes", "group": group,
        "group_state": status(group["trang_thai"]), "fee": money(group["hoc_phi"]), "actions": actions,
        "tables": grids, "notices": notices, "lessons": lessons,
        "can_register": student and not member and registration_open,
        "can_cancel": student and enrolled and enrolled["trang_thai"] == "DANG_HOC",
    })


@role_required(STUDENT)
@require_POST
def register(request, class_id):
    require_row("""
        SELECT 1 FROM LopHoc l JOIN KhoaHoc k USING (ma_khoa_hoc)
        WHERE l.ma_lop = %s AND k.trang_thai = 'CONG_BO'
    """, [class_id])
    return action(request, lambda: call_proc("sp_dang_ky_lop", [class_id, request.actor["ma_nguoi_dung"]], out=True),
                  link("", "class_detail", class_id).url, "Đăng ký lớp thành công.")


@role_required(STUDENT)
@require_POST
def cancel(request, class_id):
    return action(request, lambda: call_proc("sp_huy_dang_ky", [class_id, request.actor["ma_nguoi_dung"]]),
                  link("", "classes").url, "Đã hủy đăng ký.")


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def edit_class(request, class_id=None):
    original = require_row("SELECT * FROM LopHoc WHERE ma_lop = %s", [class_id]) if class_id else None
    fields = {"ma_code": text("Mã lớp", 20)}
    if not original:
        course_options = options(fetch_all("SELECT ma_khoa_hoc, ten_khoa_hoc FROM KhoaHoc ORDER BY ten_khoa_hoc"),
                                 "ma_khoa_hoc", "ten_khoa_hoc")
        fields["ma_khoa_hoc"] = select("Khóa học", course_options)
    fields.update({
        "ngay_bat_dau": day_field("Ngày bắt đầu"), "ngay_ket_thuc": day_field("Ngày kết thúc"),
        "si_so_toi_da": forms.IntegerField(label="Sĩ số tối đa", min_value=1, max_value=65535),
        "hoc_phi": forms.DecimalField(label="Học phí (₫)", min_value=0, max_digits=12, decimal_places=0),
    })
    if original:
        fields["trang_thai"] = enum("Trạng thái", ["MO_DANG_KY", "DANG_HOC", "KET_THUC", "HUY"])
    else:
        fields["teacher"] = select("Giảng viên chính", teachers())

    def save(data):
        if original:
            call_proc("sp_sua_lop", [class_id, *data.values()])
            return link("", "class_detail", class_id).url
        new_id = call_proc("sp_tao_lop", list(data.values()), out=True)
        return link("", "class_detail", new_id).url

    return form_page(request, "Sửa lớp" if original else "Mở lớp mới", "classes", fields, save,
                     link("Lớp học", "classes"), initial=original)


@role_required(ADMIN)
@require_http_methods(["GET", "POST"])
def assign_teacher(request, class_id):
    group = require_row("SELECT ma_code FROM LopHoc WHERE ma_lop = %s", [class_id])
    fields = {"teacher": select("Giảng viên", teachers()), "role": enum("Vai trò", ["CHINH", "TRO_GIANG"])}

    def save(data):
        call_proc("sp_phan_cong_giang_vien", [class_id, data["teacher"], data["role"]])

    return form_page(request, f"Phân công lớp {group['ma_code']}", "classes", fields, save,
                     link("Về lớp học", "class_detail", class_id))


@role_required(ADMIN, TEACHER)
@require_http_methods(["GET", "POST"])
def new_session(request, class_id):
    require_teaching(request, class_id)
    lessons = options(fetch_all("""
        SELECT b.ma_bai_hoc, b.tieu_de FROM LopHoc l JOIN Chuong c USING (ma_khoa_hoc)
        JOIN BaiHoc b USING (ma_chuong) WHERE l.ma_lop = %s ORDER BY c.thu_tu, b.thu_tu
    """, [class_id]), "ma_bai_hoc", "tieu_de")
    fields = {"order": forms.IntegerField(label="Số thứ tự", min_value=1, max_value=65535),
              "start": time_field("Bắt đầu"), "end": time_field("Kết thúc"),
              "type": enum("Hình thức", ["TRUC_TIEP", "ONLINE"], {"TRUC_TIEP": "Trực tiếp", "ONLINE": "Trực tuyến"}),
              "location": text("Địa điểm", 255, required=False), "lesson": select("Bài học liên quan", lessons, required=False)}

    def save(data):
        execute("""
            INSERT INTO BuoiHoc(ma_lop, so_thu_tu, bat_dau, ket_thuc, hinh_thuc, dia_diem, ma_bai_hoc)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, [class_id, *data.values()])

    return form_page(request, "Thêm buổi học", "classes", fields, save, link("Về lớp học", "class_detail", class_id))


@role_required(ADMIN, TEACHER)
@require_http_methods(["GET", "POST"])
def new_notice(request, class_id):
    require_teaching(request, class_id)
    fields = {"title": text("Tiêu đề"), "body": area("Nội dung"),
              "pin": forms.BooleanField(label="Ghim thông báo", required=False)}

    def save(data):
        execute("""
            INSERT INTO ThongBaoLop(ma_lop, ma_nguoi_dang, tieu_de, noi_dung, ghim) VALUES (%s, %s, %s, %s, %s)
        """, [class_id, request.actor["ma_nguoi_dung"], *data.values()])

    return form_page(request, "Đăng thông báo", "classes", fields, save, link("Về lớp học", "class_detail", class_id))


@role_required(ADMIN, TEACHER)
@require_http_methods(["GET", "POST"])
def attendance(request, session_id):
    meeting = require_row("SELECT * FROM BuoiHoc WHERE ma_buoi = %s", [session_id])
    class_id = meeting["ma_lop"]
    require_teaching(request, class_id)
    students = fetch_all("""
        SELECT d.ma_dang_ky, n.ho_ten, x.trang_thai, x.ghi_chu
        FROM DangKyLop d JOIN NguoiDung n ON n.ma_nguoi_dung = d.ma_hoc_vien
        LEFT JOIN DiemDanh x ON x.ma_dang_ky = d.ma_dang_ky AND x.ma_buoi = %s
        WHERE d.ma_lop = %s AND d.trang_thai <> 'DA_HUY' ORDER BY n.ho_ten
    """, [session_id, class_id])
    fields = {
        "enrollment": select("Học viên", options(students, "ma_dang_ky", "ho_ten")),
        "state": enum("Trạng thái", ["CO_MAT", "MUON", "VANG_CO_PHEP", "VANG"]),
        "note": text("Ghi chú", 255, required=False),
    }

    def save(data):
        execute("""
            INSERT INTO DiemDanh(ma_buoi, ma_dang_ky, trang_thai, ghi_chu) VALUES (%s, %s, %s, %s)
            AS moi ON DUPLICATE KEY UPDATE trang_thai = moi.trang_thai, ghi_chu = moi.ghi_chu
        """, [session_id, *data.values()])
        return link("", "attendance", session_id).url

    return form_page(request, f"Điểm danh · Buổi {meeting['so_thu_tu']}", "classes", fields, save,
                     link("Về lớp học", "class_detail", class_id),
                     tables=[table("Danh sách điểm danh", {"Học viên": "ho_ten", "Trạng thái": lambda r: status(r["trang_thai"]), "Ghi chú": "ghi_chu"}, students)])
