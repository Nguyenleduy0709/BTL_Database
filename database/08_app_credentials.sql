-- Hai biến được cấp từ môi trường bởi scripts/init_db.py hoặc scripts/docker_init.sh.
SET @account_sql = CONCAT('ALTER USER ''app_web''@''%'' IDENTIFIED BY ',
    QUOTE(CONVERT(UNHEX(@codelab_web_password_hex) USING utf8mb4)), ' ACCOUNT UNLOCK');
PREPARE account_stmt FROM @account_sql;
EXECUTE account_stmt;
DEALLOCATE PREPARE account_stmt;

SET @account_sql = CONCAT('ALTER USER ''app_readonly''@''%'' IDENTIFIED BY ',
    QUOTE(CONVERT(UNHEX(@codelab_read_password_hex) USING utf8mb4)), ' ACCOUNT UNLOCK');
PREPARE account_stmt FROM @account_sql;
EXECUTE account_stmt;
DEALLOCATE PREPARE account_stmt;
SET @account_sql = NULL, @codelab_web_password_hex = NULL, @codelab_read_password_hex = NULL;
