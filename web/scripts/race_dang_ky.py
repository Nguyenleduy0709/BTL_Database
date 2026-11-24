"""Hai học viên đăng ký đồng thời vào một lớp demo chỉ có một chỗ."""
from datetime import date, timedelta
from pathlib import Path
import os
import sys
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from uuid import uuid4

import django

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.db import DatabaseError, connections
from core.db import call_proc, execute, fetch_one


def main():
    today = date.today()
    code = "RACE-" + uuid4().hex[:8].upper()
    class_id = call_proc("sp_tao_lop", [code, 1, today, today + timedelta(days=42), 1, 2], out=True)
    ready = Barrier(2, timeout=10)

    def enroll(student):
        try:
            execute("SET @app_user_id = %s", [student])
            ready.wait()
            enrollment = call_proc("sp_dang_ky_lop", [class_id, student], out=True)
            return student, enrollment, None
        except DatabaseError as error:
            return student, None, error.args
        finally:
            connections.close_all()

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(enroll, [6, 7]))
    for student, enrollment, error in results:
        text = f"đăng ký thành công (mã {enrollment})" if enrollment else error
        print(f"Học viên {student} | {text}")
    group = fetch_one("SELECT si_so_hien_tai, si_so_toi_da FROM v_lop_hoc WHERE ma_lop = %s", [class_id])
    print(f"{code} | Sĩ số {group['si_so_hien_tai']} / {group['si_so_toi_da']}")
    assert sum(enrollment is not None for _, enrollment, _ in results) == 1
    failures = [error for _, _, error in results if error]
    assert len(failures) == 1 and failures[0][0] == 1644 and "đủ sĩ số" in failures[0][1]
    assert group["si_so_hien_tai"] == group["si_so_toi_da"] == 1


if __name__ == "__main__":
    main()
