"""Kiểm tra màn hình học, phân quyền và truy vấn mẫu trên MySQL."""
from pathlib import Path
import os
import sys

import django

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.db import DatabaseError, transaction
from django.test import Client
from django.test.utils import override_settings
from core.db import fetch_one, query

QUERY_DIR = Path(__file__).resolve().parents[2] / "database" / "queries"


def main():
    demo_password = os.getenv("CODELAB_DEMO_PASSWORD")
    if not demo_password:
        raise SystemExit("Set CODELAB_DEMO_PASSWORD in .env to test the sample accounts.")
    urls = {
        "admin": ["/", "/lop/1/", "/khoa-hoc/1/", "/giao-bai/1/thong-ke/", "/lop/1/bang-diem/",
                  "/nhat-ky/", "/hoc-phi/", "/nguoi-dung/", "/bai-tap/1/"],
        "giangvien": ["/", "/lop/1/giao-bai/", "/buoi/1/diem-danh/", "/cho-cham/", "/lan-nop/3/ket-qua/"],
        "an": ["/", "/lop/1/", "/lop/1/bai-hoc/3/", "/giao-bai/1/nop/", "/lan-nop/2/ket-qua/",
               "/toi/tien-do/", "/toi/1/thanh-toan/", "/khoa-hoc/", "/khoa-hoc/1/", "/khoa-hoc/2/"],
    }
    with override_settings(ALLOWED_HOSTS=["testserver"], DEBUG=False):
        for user, pages in urls.items():
            client = Client()
            assert client.post("/login/", {"username": user, "password": demo_password}).status_code == 302, user
            for url in pages:
                response = client.get(url)
                assert response.status_code == 200, (user, url, response.status_code)
                assert b'id="sql-panel"' not in response.content and b'/sql-lab/' not in response.content, (user, url)
            if user == "an":
                for url in ("/nguoi-dung/", "/lan-nop/3/ket-qua/"):
                    assert client.get(url).status_code == 403, url
                check_learning(client, demo_password)
            assert client.get("/sql-lab/Q07/run/").status_code == 404
            print(f"{user}: {len(pages)} trang đạt")
        check_queries()
    print("Danh mục khóa học, học thử, tiến độ, phân quyền web, 35 truy vấn và 35 EXPLAIN đạt.")


def check_learning(student, demo_password):
    guest = Client()
    catalog = guest.get("/khoa-hoc/?q=SQL")
    assert catalog.status_code == 200 and "SQL thực hành" in catalog.content.decode()
    assert "Python cơ bản" not in catalog.content.decode()
    assert guest.get("/khoa-hoc/2/").status_code == 200
    for course_id, lesson_id in ((1, 1), (2, 5)):
        preview = guest.get(f"/khoa-hoc/{course_id}/hoc-thu/{lesson_id}/")
        assert preview.status_code == 200 and b"<pre" in preview.content
    assert guest.get("/khoa-hoc/1/hoc-thu/2/").status_code == 404
    assert student.get("/lop/2/bai-hoc/1/").status_code == 404
    assert student.get("/lop/1/bai-hoc/5/").status_code == 404
    login = guest.post("/login/?next=/khoa-hoc/2/", {"username": "an", "password": demo_password})
    assert login.status_code == 302 and login.url == "/khoa-hoc/2/"

    course = student.get("/khoa-hoc/1/")
    assert "Tiến độ của bạn" in course.content.decode()
    assert b"/lop/1/bai-hoc/4/" in course.content
    with transaction.atomic():
        response = student.post("/lop/1/bai-hoc/4/hoan-thanh/")
        assert response.status_code == 302
        assert fetch_one("SELECT 1 FROM TienDoBaiHoc WHERE ma_dang_ky = 1 AND ma_bai_hoc = 4")
        assert "Đã hoàn thành" in student.get(response.url).content.decode()
        transaction.set_rollback(True)


def check_queries():
    queries = sorted(QUERY_DIR.glob("Q[0-9][0-9].sql"))
    assert len(queries) == 35
    for path in queries:
        statement = path.read_text(encoding="utf-8").split("\n", 2)[2].strip().removesuffix(";")
        for prefix in ("", "EXPLAIN FORMAT=TREE "):
            try:
                query(prefix + statement, alias="readonly", limit=101)
            except DatabaseError as error:
                raise AssertionError(f"{path.stem} {prefix}: {error}") from error
    for blocked in (
        "UPDATE LopHoc SET hoc_phi = hoc_phi WHERE 1 = 0",
        "SELECT mat_khau_hash FROM NguoiDung WHERE 1 = 0",
        "SELECT ma_nguon FROM LanNop WHERE 1 = 0",
    ):
        try:
            query(blocked, alias="readonly")
        except DatabaseError as error:
            assert error.args[0] in {1142, 1143}
        else:
            raise AssertionError(f"User chỉ đọc có quyền ngoài phạm vi: {blocked}")


if __name__ == "__main__":
    main()
