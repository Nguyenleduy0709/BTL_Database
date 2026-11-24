param(
    [int]$DatabasePort = 33317,
    [int]$WebPort = 8000,
    [switch]$WithoutBenchmark,
    [switch]$InitOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
$env:DB_PORT = "$DatabasePort"
$database = Join-Path $root '.local/codelab-mysql'
$mysql = (Get-Command mysql.exe).Source
$mysqld = (Get-Command mysqld.exe).Source
$client = @('--no-defaults', '--protocol=TCP', '--host=127.0.0.1', "--port=$DatabasePort",
    '--connect-timeout=2', '--user=root', '--silent', '--skip-column-names', '--raw')

function Invoke-LocalMySql($sql) {
    & $mysql @client --execute=$sql 2>$null
}

New-Item -ItemType Directory -Force -Path $database | Out-Null
$serverPath = Invoke-LocalMySql 'SELECT @@datadir'
if ($LASTEXITCODE -ne 0) {
    if (-not (Test-Path -LiteralPath (Join-Path $database 'mysql'))) {
        & $mysqld --no-defaults --initialize-insecure --console "--datadir=$database"
        if ($LASTEXITCODE -ne 0) { throw 'Khởi tạo MySQL cục bộ thất bại.' }
    }
    $errorLog = Join-Path $database 'codelab.err'
    $proc = Start-Process -FilePath $mysqld -ArgumentList @(
        '--no-defaults', ('--datadir="' + $database + '"'), '--bind-address=127.0.0.1',
        "--port=$DatabasePort", '--mysqlx=OFF', '--default-time-zone=+07:00',
        '--log-bin-trust-function-creators=ON', ('--log-error="' + $errorLog + '"')
    ) -WindowStyle Hidden -PassThru
    for ($attempt = 0; $attempt -lt 16; $attempt++) {
        $serverPath = Invoke-LocalMySql 'SELECT @@datadir'
        if ($LASTEXITCODE -eq 0 -or $proc.HasExited) { break }
        Start-Sleep -Milliseconds 500
    }
}

$expected = $database.Replace('/', '\').TrimEnd('\')
if (-not $serverPath -or $serverPath.Replace('/', '\').TrimEnd('\') -ne $expected) {
    throw "Không xác nhận được MySQL của dự án trên cổng $DatabasePort. Xem .local/codelab-mysql/codelab.err."
}
$venv = Join-Path $root '.venv/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $venv)) {
    python -m venv .venv
    if ($LASTEXITCODE -ne 0) { throw 'Không tạo được môi trường Python.' }
}
& $venv -c 'import django, MySQLdb, bcrypt, dotenv'
if ($LASTEXITCODE -ne 0) {
    & $venv -m pip install -r web/requirements.txt
    if ($LASTEXITCODE -ne 0) { throw 'Không cài được thư viện Python.' }
}
& $venv scripts/configure_local.py
if ($LASTEXITCODE -ne 0) { throw 'Không tạo được cấu hình .env.' }

$ready = Invoke-LocalMySql "SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_SCHEMA='btlcsdl' AND TABLE_TYPE='BASE TABLE' AND LOWER(TABLE_NAME) NOT IN ('maxacthucemail', 'hanmucxacthuc')"
$sample = Invoke-LocalMySql "SELECT COUNT(*) FROM btlcsdl.NguoiDung WHERE ten_dang_nhap IN ('admin','an','binh','chi','giangvien')"
if ($ready -eq '0') {
    $init = @('scripts/init_db.py', '--port', $DatabasePort)
    if ($WithoutBenchmark) { $init += '--without-benchmark' }
    & $venv @init
    if ($LASTEXITCODE -ne 0) { throw 'Nạp lược đồ hoặc dữ liệu mẫu thất bại.' }
} elseif ($ready -ne '29' -or $sample -ne '5') {
    throw 'MySQL của dự án đang có dữ liệu khởi tạo dở. Xem README để chọn một bản cài sạch.'
} else {
    $auth = Invoke-LocalMySql "SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_SCHEMA='btlcsdl' AND TABLE_TYPE='BASE TABLE' AND LOWER(TABLE_NAME) IN ('maxacthucemail', 'hanmucxacthuc')"
    $routine = Invoke-LocalMySql "SELECT COUNT(*) FROM mysql.procs_priv WHERE Db='btlcsdl' AND Routine_name='sp_dang_ky_hoc_vien_xac_thuc' AND User='btl_web' AND FIND_IN_SET('Execute', Proc_priv) > 0"
    if ($auth -ne '2' -or $routine -ne '1') {
        & $venv scripts/init_db.py --account-auth-only --port $DatabasePort
        if ($LASTEXITCODE -ne 0) { throw 'Nâng cấp xác thực email thất bại.' }
    }
    $free = Invoke-LocalMySql "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA='btlcsdl' AND LOWER(TABLE_NAME)='lophoc' AND CONSTRAINT_NAME='ck_lophoc_mien_phi' AND ENFORCED='YES'"
    if ($free -ne '1') {
        & $venv scripts/init_db.py --free-courses-only --port $DatabasePort
        if ($LASTEXITCODE -ne 0) { throw 'Nâng cấp lớp học miễn phí thất bại.' }
    }
}
if ($InitOnly) { return }

& $venv web/manage.py runserver "127.0.0.1:$WebPort"
