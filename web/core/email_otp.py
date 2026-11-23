import logging
from secrets import randbelow, token_hex
import unicodedata

import bcrypt
from django.core.mail import send_mail
from django.db import transaction
from django.utils.crypto import constant_time_compare, salted_hmac

from .auth import password_stamp
from .db import call_proc, execute, fetch_one

REGISTER = "DANG_KY"
RESET = "QUEN_MAT_KHAU"
VALID_SECONDS = 10 * 60
RESEND_SECONDS = 60
MAX_ATTEMPTS = 5

logger = logging.getLogger(__name__)


def token_hash(purpose, request_id, code):
    return salted_hmac("codelab.email-otp", f"{purpose}:{request_id}:{code}", algorithm="sha256").hexdigest()


def take_quota(scope, value, limit, seconds):
    key = salted_hmac(f"codelab.auth-quota.{scope}", value, algorithm="sha256").hexdigest()
    with transaction.atomic():
        execute("""
            INSERT INTO HanMucXacThuc(khoa, het_han) VALUES (%s, UTC_TIMESTAMP(6))
            ON DUPLICATE KEY UPDATE khoa = khoa
        """, [key])
        quota = fetch_one("""
            SELECT so_lan, het_han <= UTC_TIMESTAMP(6) AS het_han
            FROM HanMucXacThuc WHERE khoa = %s FOR UPDATE
        """, [key])
        if quota["het_han"]:
            execute("""
                UPDATE HanMucXacThuc SET so_lan = 1, het_han = TIMESTAMPADD(SECOND, %s, UTC_TIMESTAMP(6))
                WHERE khoa = %s
            """, [seconds, key])
        elif quota["so_lan"] >= limit:
            return False
        else:
            execute("UPDATE HanMucXacThuc SET so_lan = so_lan + 1 WHERE khoa = %s", [key])
    return True


def quota_email(email):
    normalized = unicodedata.normalize("NFKD", email.casefold())
    return "".join(character for character in normalized if not unicodedata.combining(character))


def issue_code(purpose, email, address):
    if not take_quota("send-ip", address, 20, 60 * 60):
        return None
    account = fetch_one("""
        SELECT ma_nguoi_dung, email, trang_thai, mat_khau_hash FROM NguoiDung WHERE email = %s
    """, [email])
    # Dùng địa chỉ đã lưu cho email đặt lại mật khẩu, kể cả khi collation coi địa chỉ nhập là tương đương.
    recipient = account["email"] if account else email
    key = quota_email(recipient)
    if not take_quota("send-wait", key, 1, RESEND_SECONDS):
        return None
    if not take_quota("send-email", key, 5, 60 * 60):
        return None

    request_id = token_hex(16)
    eligible = ((purpose == REGISTER and account is None)
                or (purpose == RESET and account and account["trang_thai"] == "HOAT_DONG"))
    if not eligible:
        return request_id

    code = f"{randbelow(1_000_000):06d}"
    execute("DELETE FROM MaXacThucEmail WHERE het_han <= UTC_TIMESTAMP(6) ORDER BY het_han LIMIT 50")
    execute("""
        DELETE FROM HanMucXacThuc WHERE het_han < UTC_TIMESTAMP(6) - INTERVAL 1 DAY ORDER BY het_han LIMIT 50
    """)
    execute("""
        INSERT INTO MaXacThucEmail(ma_yeu_cau, muc_dich, email, ma_nguoi_dung, dau_mat_khau, ma_bam, het_han)
        VALUES (%s, %s, %s, %s, %s, %s, TIMESTAMPADD(SECOND, %s, UTC_TIMESTAMP(6)))
        AS moi ON DUPLICATE KEY UPDATE
            ma_yeu_cau = moi.ma_yeu_cau, email = moi.email, ma_nguoi_dung = moi.ma_nguoi_dung,
            dau_mat_khau = moi.dau_mat_khau, ma_bam = moi.ma_bam, het_han = moi.het_han, so_lan_sai = 0
    """, [request_id, purpose, recipient, account["ma_nguoi_dung"] if account else None,
          password_stamp(account["mat_khau_hash"]) if account else None,
          token_hash(purpose, request_id, code), VALID_SECONDS])
    action = "đăng ký học viên" if purpose == REGISTER else "đặt lại mật khẩu"
    try:
        delivered = send_mail(
            f"CodeLab | Mã {action}",
            f"Mã OTP của bạn là {code}.\n\nMã dùng một lần và có hiệu lực trong {VALID_SECONDS // 60} phút. "
            "Hãy bỏ qua thư nếu bạn không thực hiện yêu cầu này.",
            None, [recipient],
        )
    except OSError as error:
        logger.warning("Gửi OTP thất bại (%s).", type(error).__name__)
        delivered = 0
    if delivered != 1:
        execute("DELETE FROM MaXacThucEmail WHERE ma_yeu_cau = %s", [request_id])
    return request_id


def verify_and_save(purpose, request_id, code, address, data):
    if not take_quota("verify-ip", address, 60, 15 * 60):
        return False

    with transaction.atomic():
        challenge = fetch_one("""
            SELECT email, ma_nguoi_dung, dau_mat_khau, ma_bam, so_lan_sai,
                   het_han > UTC_TIMESTAMP(6) AS con_han
            FROM MaXacThucEmail WHERE ma_yeu_cau = %s AND muc_dich = %s FOR UPDATE
        """, [request_id, purpose])
        if not challenge or not challenge["con_han"] or challenge["so_lan_sai"] >= MAX_ATTEMPTS:
            return False
        if not constant_time_compare(challenge["ma_bam"], token_hash(purpose, request_id, code)):
            execute("UPDATE MaXacThucEmail SET so_lan_sai = so_lan_sai + 1 WHERE ma_yeu_cau = %s", [request_id])
            return False

        if purpose == RESET:
            account = fetch_one("""
                SELECT mat_khau_hash FROM NguoiDung
                WHERE ma_nguoi_dung = %s AND email = %s AND trang_thai = 'HOAT_DONG' FOR UPDATE
            """, [challenge["ma_nguoi_dung"], challenge["email"]])
            if not account or not constant_time_compare(
                challenge["dau_mat_khau"], password_stamp(account["mat_khau_hash"]),
            ):
                execute("DELETE FROM MaXacThucEmail WHERE ma_yeu_cau = %s", [request_id])
                return False

        password_hash = bcrypt.hashpw(data["password"].encode("utf-8"), bcrypt.gensalt()).decode("ascii")
        if purpose == REGISTER:
            call_proc("sp_dang_ky_hoc_vien_xac_thuc", [
                data["username"], challenge["email"], password_hash, data["full_name"],
            ])
        else:
            execute("UPDATE NguoiDung SET mat_khau_hash = %s WHERE ma_nguoi_dung = %s",
                    [password_hash, challenge["ma_nguoi_dung"]])
        execute("DELETE FROM MaXacThucEmail WHERE ma_yeu_cau = %s", [request_id])
    return True
