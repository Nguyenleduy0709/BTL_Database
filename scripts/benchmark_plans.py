"""Đo Q33 và Q34 bằng EXPLAIN ANALYZE trên MySQL đã nạp PY-BENCH."""
import argparse
import os
from pathlib import Path
import re
import statistics

import MySQLdb
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]


def main():
    load_dotenv(ROOT / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=int(os.getenv("DB_PORT", "33317")))
    parser.add_argument("--runs", type=int, default=5, choices=range(1, 31), metavar="1–30")
    args = parser.parse_args()
    connection = MySQLdb.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"), port=args.port, db=os.getenv("DB_NAME", "btlcsdl"),
        user=os.getenv("DB_READ_USER", "app_readonly"), passwd=os.getenv("DB_READ_PASSWORD", ""),
        charset="utf8mb4",
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM v_giao_bai WHERE ma_lop_code = 'PY-BENCH'")
            if not cursor.fetchone()[0]:
                raise SystemExit("Cần nạp 12_seed_khoi_luong.sql trước khi đo.")
            for query_id in ("Q33", "Q34"):
                sql = (ROOT / "database" / "queries" / f"{query_id}.sql").read_text(encoding="utf-8")
                statement = "EXPLAIN ANALYZE " + sql.split("\n", 2)[2].strip().removesuffix(";")
                times = []
                for run in range(args.runs + 1):
                    cursor.execute(statement)
                    plan = cursor.fetchone()[0]
                    if run:
                        elapsed = re.search(r"actual time=[\d.]+\.\.([\d.]+)", plan)
                        if elapsed:
                            times.append(float(elapsed[1]))
                print(f"{query_id} · trung vị {statistics.median(times):.3f} ms" if times else query_id)
                print(plan)
    finally:
        connection.close()


if __name__ == "__main__":
    main()
