"""SQL thuần, với tên procedure được cung cấp từ mã nguồn."""
from django.db import connections


def _rows(cursor):
    columns = [item[0] for item in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def query(sql, params=None, *, alias="default", limit=None):
    with connections[alias].cursor() as cursor:
        cursor.execute(sql, params)
        columns = [item[0] for item in cursor.description]
        records = cursor.fetchmany(limit) if limit is not None else cursor.fetchall()
        return columns, [dict(zip(columns, record)) for record in records]


def fetch_all(sql, params=None):
    return query(sql, params)[1]


def fetch_one(sql, params=None):
    _, rows = query(sql, params, limit=1)
    return rows[0] if rows else None


def execute(sql, params=None, *, affected=False):
    with connections["default"].cursor() as cursor:
        cursor.execute(sql, params)
        return cursor.rowcount if affected else cursor.lastrowid


def call_proc(name, params=(), out=False):
    placeholders = ["%s"] * len(params)
    if out:
        placeholders.append("@codelab_out")
    with connections["default"].cursor() as cursor:
        cursor.execute(f"CALL {name}({', '.join(placeholders)})", params or None)
        result_sets = []
        while True:
            if cursor.description:
                result_sets.append(_rows(cursor))
            if not cursor.nextset():
                break
        if out:
            cursor.execute("SELECT @codelab_out")
            return cursor.fetchone()[0]
        return result_sets
