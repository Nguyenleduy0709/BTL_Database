"""Nạp SQL theo thứ tự bằng mysql CLI, giữ nguyên UTF-8 và DELIMITER."""
import argparse
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]

CONFIGURED_SQL = {
    "08": {"codelab_web_password_hex": "DB_PASSWORD", "codelab_read_password_hex": "DB_READ_PASSWORD"},
    "11": {"codelab_demo_hash_hex": "CODELAB_DEMO_PASSWORD_HASH"},
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=33317)
    parser.add_argument("--user", default="root")
    parser.add_argument("--ask-password", action="store_true")
    parser.add_argument("--without-benchmark", action="store_true")
    parser.add_argument("--without-secondary-indexes", action="store_true")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--course-content-only", action="store_true",
                      help="Chỉ bổ sung nội dung cho hai khóa mẫu đã có.")
    mode.add_argument("--account-auth-only", action="store_true",
                      help="Chỉ nâng cấp cơ sở dữ liệu đã có để dùng xác thực email.")
    mode.add_argument("--free-courses-only", action="store_true",
                      help="Chỉ nâng cấp cơ sở dữ liệu đã có để mọi lớp đều miễn phí.")
    parser.add_argument("--shared-memory")
    args = parser.parse_args()

    command = ["mysql", "--no-defaults", "--default-character-set=utf8mb4", f"--user={args.user}"]
    if args.shared_memory:
        command += ["--protocol=MEMORY", f"--shared-memory-base-name={args.shared_memory}"]
    else:
        command += ["--protocol=TCP", f"--host={args.host}", f"--port={args.port}"]
    if args.ask_password:
        from getpass import getpass
        environment = {**os.environ, "MYSQL_PWD": getpass("MySQL password: ")}
    else:
        environment = os.environ

    database_dir = ROOT / "database"
    if args.account_auth_only:
        scripts = [database_dir / "14_xac_thuc_tai_khoan.sql"]
    elif args.course_content_only:
        scripts = [database_dir / "13_noi_dung_khoa_hoc.sql"]
    elif args.free_courses_only:
        scripts = [database_dir / "09_mien_phi.sql"]
    else:
        scripts = sorted(database_dir.glob("[0-9]*.sql"))
        from dotenv import load_dotenv
        load_dotenv(ROOT / ".env")
        missing = [key for variables in CONFIGURED_SQL.values() for key in variables.values() if not os.getenv(key)]
        if missing:
            parser.error(f"Thiếu {', '.join(missing)}. Chạy scripts/configure_local.py trước khi nạp.")

    for script in scripts:
        if args.without_benchmark and script.name.startswith("12_"):
            continue
        if args.without_secondary_indexes and script.name.startswith("02_"):
            continue
        print(script.name, flush=True)
        variables = CONFIGURED_SQL.get(script.name.split("_", 1)[0], {})
        prefix = "".join(f"SET @{name} = '{os.environ[key].encode('utf-8').hex()}';\n"
                         for name, key in variables.items()).encode("ascii")
        subprocess.run(command, input=prefix + script.read_bytes(), env=environment, check=True)


if __name__ == "__main__":
    main()
