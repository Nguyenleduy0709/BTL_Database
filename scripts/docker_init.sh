#!/usr/bin/env bash
# Dùng subshell vì MySQL có thể source file bind-mount.
(
set -euo pipefail

sql_variable() {
    printf "SET @%s = '%s';\n" "$1" "$(printf '%s' "$2" | od -An -tx1 | tr -d ' \n')"
}

for file in /opt/codelab/database/[0-9]*.sql; do
    printf 'CodeLab: %s\n' "${file##*/}"
    {
        case "${file##*/}" in
            08_*)
                sql_variable codelab_web_password_hex "$DB_PASSWORD"
                sql_variable codelab_read_password_hex "$DB_READ_PASSWORD"
                ;;
            11_*) sql_variable codelab_demo_hash_hex "$CODELAB_DEMO_PASSWORD_HASH" ;;
        esac
        cat "$file"
    } | MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql --protocol=socket --default-character-set=utf8mb4 -uroot
done
)
