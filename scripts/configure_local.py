"""Tạo cấu hình cục bộ và mật khẩu riêng cho bản cài CodeLab."""
from pathlib import Path
from secrets import token_urlsafe

import bcrypt
from dotenv import dotenv_values, set_key

ROOT = Path(__file__).resolve().parents[1]


def main():
    config = ROOT / ".env"
    if not config.exists():
        with config.open("x", encoding="utf-8") as target:
            target.write((ROOT / ".env.example").read_text(encoding="utf-8"))
    values = dotenv_values(config)
    for key in ("MYSQL_ROOT_PASSWORD", "DB_PASSWORD", "DB_READ_PASSWORD", "CODELAB_DEMO_PASSWORD"):
        if not values.get(key):
            values[key] = token_urlsafe(24)
            set_key(config, key, values[key])
    password = values["CODELAB_DEMO_PASSWORD"].encode("utf-8")
    if len(password) > 72:
        raise SystemExit("CODELAB_DEMO_PASSWORD dài quá giới hạn 72 byte của bcrypt.")
    current_hash = (values.get("CODELAB_DEMO_PASSWORD_HASH") or "").encode("ascii")
    if not current_hash or not bcrypt.checkpw(password, current_hash):
        password_hash = bcrypt.hashpw(password, bcrypt.gensalt()).decode("ascii")
        set_key(config, "CODELAB_DEMO_PASSWORD_HASH", password_hash)


if __name__ == "__main__":
    main()
