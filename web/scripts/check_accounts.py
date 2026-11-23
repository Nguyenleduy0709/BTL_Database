"""Kiểm thử luồng tài khoản trên MySQL, dùng hộp thư trong bộ nhớ."""
from pathlib import Path
from secrets import token_urlsafe
import os
import re
import sys
from unittest.mock import patch
from uuid import uuid4

import django

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.core import mail
from django.db import transaction
from django.test import Client
from django.test.utils import override_settings
from django.utils.crypto import salted_hmac

from core.db import execute, fetch_one
from core.email_otp import MAX_ATTEMPTS, REGISTER, RESET


OLD_PASSWORD = token_urlsafe(18)
NEW_PASSWORD = token_urlsafe(18)
TEST_ADDRESS = "198.51.100.21"


def browser():
    return Client(enforce_csrf_checks=True, REMOTE_ADDR=TEST_ADDRESS)


def post(client, route, data):
    return client.post(route, data, HTTP_X_CSRFTOKEN=client.cookies["csrftoken"].value)


def start(client, route, email):
    assert client.get(route).status_code == 200
    assert post(client, route, {"email": email}).status_code == 302


def last_code(recipient):
    message = mail.outbox[-1]
    assert message.to == [recipient]
    return re.search(r"\b[0-9]{6}\b", message.body).group()


def assert_otp_error(response):
    assert response.status_code == 200
    assert "Mã không hợp lệ" in response.content.decode("utf-8")


def password_form(code, password):
    return {"code": code, "password": password, "password_confirmation": password}


def main():
    username = "qa_" + uuid4().hex[:16]
    email = username + "@example.invalid"
    with override_settings(ALLOWED_HOSTS=["testserver"], DEBUG=False,
                           EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend"):
        with transaction.atomic():
            # Địa chỉ test riêng và rollback khi kết thúc để giữ dữ liệu cục bộ.
            mail.outbox = []
            registration = browser()
            assert registration.post("/dang-ky/", {"email": email}).status_code == 403
            start(registration, "/dang-ky/", email)
            code = last_code(email)
            flow = registration.session["email_otp_" + REGISTER]["id"]
            assert registration.session["email_otp_" + REGISTER] == {"id": flow, "email": email}
            challenge = fetch_one("SELECT ma_bam FROM MaXacThucEmail WHERE ma_yeu_cau = %s", [flow])
            assert len(challenge["ma_bam"]) == 64 and challenge["ma_bam"] != code
            assert not fetch_one("SELECT 1 FROM NguoiDung WHERE email = %s", [email])
            assert post(registration, "/dang-ky/gui-lai/", {}).status_code == 302
            assert len(mail.outbox) == 1

            candidate = {"username": username, "full_name": "Học viên kiểm thử", "role": "ADMIN"}
            wrong = "000000" if code != "000000" else "111111"
            assert_otp_error(post(registration, "/dang-ky/xac-thuc/", {**candidate, **password_form(wrong, OLD_PASSWORD)}))
            saved_cookie = {key: value.value for key, value in registration.cookies.items()}
            assert post(registration, "/dang-ky/xac-thuc/", {
                **candidate, **password_form(code, OLD_PASSWORD),
            }).url == "/login/"
            assert not fetch_one("SELECT 1 FROM MaXacThucEmail WHERE ma_yeu_cau = %s", [flow])
            role = fetch_one("""
                SELECT GROUP_CONCAT(v.ten_vai_tro) AS vai_tro FROM NguoiDung n
                JOIN NguoiDungVaiTro nv USING (ma_nguoi_dung) JOIN VaiTro v USING (ma_vai_tro)
                WHERE n.email = %s
            """, [email])
            assert role["vai_tro"] == "HOC_VIEN"
            replay = browser()
            for name, value in saved_cookie.items():
                replay.cookies[name] = value
            assert_otp_error(post(replay, "/dang-ky/xac-thuc/", {**candidate, **password_form(code, OLD_PASSWORD)}))
            print("Đăng ký, CSRF, quyền học viên, giới hạn gửi và dùng lại mã: đạt.")

            signed_in = browser()
            signed_in.get("/login/")
            assert post(signed_in, "/login/", {"username": username, "password": OLD_PASSWORD}).status_code == 302
            assert signed_in.get("/toi/tien-do/").status_code == 200

            recovery = browser()
            key = salted_hmac("codelab.auth-quota.send-wait", email, algorithm="sha256").hexdigest()
            execute("UPDATE HanMucXacThuc SET het_han = UTC_TIMESTAMP(6) WHERE khoa = %s", [key])
            start(recovery, "/quen-mat-khau/", email)
            code = last_code(email)
            flow = recovery.session["email_otp_" + RESET]["id"]
            wrong = "000000" if code != "000000" else "111111"
            for _ in range(MAX_ATTEMPTS):
                assert_otp_error(post(recovery, "/quen-mat-khau/xac-thuc/", password_form(wrong, NEW_PASSWORD)))
            assert_otp_error(post(recovery, "/quen-mat-khau/xac-thuc/", password_form(code, NEW_PASSWORD)))
            assert post(recovery, "/quen-mat-khau/gui-lai/", {}).status_code == 302
            assert len(mail.outbox) == 2

            # Tái tạo cửa sổ gửi mới cho riêng hộp thư test trong giao dịch rollback.
            execute("UPDATE HanMucXacThuc SET het_han = UTC_TIMESTAMP(6) WHERE khoa = %s", [key])
            assert post(recovery, "/quen-mat-khau/gui-lai/", {}).status_code == 302
            code = last_code(email)
            assert recovery.session["email_otp_" + RESET]["id"] != flow
            assert not fetch_one("SELECT 1 FROM MaXacThucEmail WHERE ma_yeu_cau = %s", [flow])
            assert post(recovery, "/quen-mat-khau/xac-thuc/", password_form(code, NEW_PASSWORD)).url == "/login/"
            assert signed_in.get("/toi/tien-do/").status_code == 302
            signed_in.get("/login/")
            assert post(signed_in, "/login/", {"username": username, "password": OLD_PASSWORD}).status_code == 200
            assert post(signed_in, "/login/", {"username": username, "password": NEW_PASSWORD}).status_code == 302
            print("Giới hạn nhập sai, gửi mã mới, đặt lại mật khẩu và thu hồi phiên cũ: đạt.")

            unknown = browser()
            start(unknown, "/quen-mat-khau/", "absent-" + email)
            assert len(mail.outbox) == 3
            assert unknown.get("/quen-mat-khau/xac-thuc/").status_code == 200

            expired = browser()
            expire_email = "expire-" + email
            start(expired, "/dang-ky/", expire_email)
            code = last_code(expire_email)
            flow = expired.session["email_otp_" + REGISTER]["id"]
            execute("UPDATE MaXacThucEmail SET het_han = UTC_TIMESTAMP(6) WHERE ma_yeu_cau = %s", [flow])
            assert_otp_error(post(expired, "/dang-ky/xac-thuc/", {**candidate, **password_form(code, OLD_PASSWORD)}))

            failed = browser()
            with patch("core.email_otp.send_mail", side_effect=OSError("SMTP test")):
                start(failed, "/dang-ky/", "failed-" + email)
            flow = failed.session["email_otp_" + REGISTER]["id"]
            assert not fetch_one("SELECT 1 FROM MaXacThucEmail WHERE ma_yeu_cau = %s", [flow])
            print("Email chưa tồn tại, mã hết hạn và lỗi gửi thư: đạt.")
            transaction.set_rollback(True)


if __name__ == "__main__":
    main()
