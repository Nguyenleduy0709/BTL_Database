# CodeLab · Quản lý khóa học lập trình và phân tích kết quả thực hành

Dự án bài tập lớn môn Cơ sở dữ liệu. MySQL thực thi các ràng buộc, giao dịch, chấm điểm theo trọng số và thống kê. Django dùng SQL tham số hóa để phục vụ các màn hình demo. Tất cả khóa học và lớp học đều miễn phí. Kết quả chấm trong bản demo được nhập hoặc sinh giả lập.

## Chạy trên Windows với MySQL đã cài

Cần **MySQL 8.0.21 trở lên** (đã kiểm tra trên 8.0.46), **Python 3.11 trở lên** và lệnh `mysql.exe`, `mysqld.exe` có trong `PATH`. Từ thư mục dự án, chạy trong PowerShell:

```powershell
.\scripts\start_local.ps1
```

Mở [CodeLab trên localhost](http://127.0.0.1:8000/). Lần đầu, script tạo một máy chủ MySQL riêng trong `.local/codelab-mysql`, nạp lược đồ và dữ liệu mẫu, với mật khẩu riêng được sinh trong tệp .env. Cổng mặc định của MySQL demo là **33317**. Dùng `-DatabasePort` hoặc `-WebPort` nếu cần đổi cổng. Tùy chọn `-WithoutBenchmark` bỏ dữ liệu khối lượng lớn ở lần khởi tạo đầu tiên.

Nhấn `Ctrl+C` để dừng Django. Có thể dừng riêng MySQL của dự án bằng `mysqladmin --protocol=TCP --host=127.0.0.1 --port=33317 -uroot shutdown`. Để tạo bộ dữ liệu mới, dừng MySQL trước và giữ lại thư mục dữ liệu cũ dưới tên khác.

## Chạy bằng Docker Compose

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r web/requirements.txt
.\.venv\Scripts\python.exe scripts/configure_local.py
docker compose up -d --wait
.\.venv\Scripts\python.exe web/manage.py runserver 127.0.0.1:8000
```

Docker tự chạy các script SQL đánh số khi tạo volume lần đầu. Với máy chủ MySQL do bạn quản lý, dùng `.\.venv\Scripts\python.exe scripts/init_db.py --port 3306 --ask-password` trên bản cài hoặc lược đồ trống rồi chỉnh `DB_PORT` trong `.env`. Tài khoản nạp dữ liệu cần quyền tạo bảng, routine, trigger, tài khoản và role. Nếu MySQL bật binary log, dùng tài khoản quản trị có quyền phù hợp hoặc cấu hình `log_bin_trust_function_creators=ON` cho máy demo.

Các chế độ trên dùng chung lược đồ `btlcsdl`. Script khởi tạo nạp lược đồ từ `database/*.sql`. Django kết nối MySQL và lưu phiên đăng nhập trong cookie ký số.

## Nâng cấp bản cài đã có dữ liệu

Khởi động lại bằng script Windows ở trên để tự áp dụng thay đổi miễn phí. Nếu dùng volume Docker cũ hoặc MySQL do bạn quản lý, chạy lệnh dưới đây bằng tài khoản quản trị MySQL trên đúng cổng rồi khởi động lại Django. Đổi số cổng nếu bản cài dùng cổng khác.

```powershell
.\.venv\Scripts\python.exe scripts/init_db.py --free-courses-only --port 33317 --ask-password
```

Bản nâng cấp đưa phí của tất cả lớp về 0 và giữ lại dữ liệu giao dịch cũ trong bảng lưu trữ. Bản cài mới tự thực hiện bước này. [SQL nâng cấp](database/09_mien_phi.sql)

## Đăng ký và đặt lại mật khẩu qua email

Trang [Đăng nhập](http://127.0.0.1:8000/login/) có **Tạo tài khoản học viên** và **Quên mật khẩu**. Người dùng nhập email, nhận mã OTP rồi nhập mã và mật khẩu. Tài khoản tự đăng ký có vai trò học viên. Sau khi đổi mật khẩu, người dùng đăng nhập lại trên các thiết bị đang dùng.

OTP có 6 chữ số, dùng một lần, hết hạn sau 10 phút và bị khóa sau 5 lần nhập sai. Có thể gửi lại sau 60 giây. Mỗi email được tối đa 5 lần gửi trong một giờ. Ứng dụng lưu mã băm HMAC và áp dụng thêm hạn mức theo IP.

Khi chạy cục bộ với `DJANGO_DEBUG=1` và `SMTP_HOST` để trống, mở thư mới nhất trong `.local/mail` để lấy mã. Để gửi thư qua SMTP, khai báo trong `.env` theo thông số nhà cung cấp:

```dotenv
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USE_TLS=1
SMTP_USE_SSL=0
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM=
```

Điền tài khoản SMTP, mật khẩu SMTP hoặc mật khẩu ứng dụng nếu nhà cung cấp yêu cầu, và địa chỉ người gửi được phép. Với nhà cung cấp dùng SSL trực tiếp trên cổng 465, đặt `SMTP_PORT=465`, `SMTP_USE_SSL=1`, `SMTP_USE_TLS=0`. Khởi động lại Django sau khi đổi `.env`. Khi tắt chế độ phát triển, cấu hình `DJANGO_SECRET_KEY` riêng cho máy chủ. Nếu chạy HTTPS, đặt `DJANGO_SECURE_COOKIES=1`. [Cấu hình email Django](https://docs.djangoproject.com/en/5.2/ref/settings/#email-backend)

`start_local.ps1` tự bổ sung hai bảng xác thực khi phát hiện bản cài cũ của dự án. Với MySQL đang chạy hoặc volume Docker đã có, nâng cấp bằng tài khoản quản trị MySQL rồi khởi động lại Django:

```powershell
python scripts/init_db.py --account-auth-only --port 33317 --ask-password
```

Lượt triển khai đầu tiên của tính năng này yêu cầu các tài khoản đang đăng nhập xác thực lại. Có thể kiểm tra hai luồng bằng `web/scripts/check_accounts.py`. Bộ kiểm thử dùng thư trong bộ nhớ và rollback dữ liệu thử.

## Tài khoản demo

Xem mật khẩu của các tài khoản mẫu tại `CODELAB_DEMO_PASSWORD` trong tệp `.env` của bản cài.

| Tên tài khoản | Vai trò | Màn hình nên mở |
| --- | --- | --- |
| `admin` | Quản trị viên | Tổng quan, mở lớp, phân công, chứng chỉ và nhật ký |
| `giangvien` | Giảng viên | PY01, bảng điểm, chờ chấm và ngân hàng đề |
| `an`, `binh`, `chi` | Học viên | Lớp đã đăng ký, nộp bài, kết quả từng test và tiến độ |
| `dung` | Học viên PY02 | Nộp bài mới để diễn tập chấm mà vẫn giữ kết quả ban đầu của PY01 |
| `trogiang` | Giảng viên PY02 và trợ giảng PY01 | Giao và chấm bài cho PY02 |

### Demo nhanh

1. Trên bản dữ liệu mẫu mới nạp, vào **Lớp học → PY01** và mở bài *Phần tử lớn thứ hai phân biệt*. PY01 có **3 lượt nộp, 2 học viên đã thử, 1 đạt, 1 chưa đạt và 1 chưa nộp**. An đạt **100%**, Bình **80%**, Chi chưa có điểm. Test *Giá trị lớn nhất lặp lại* có một người sai ở lượt chấm gần nhất.
2. Mở các câu Q07, Q14 và Q18 trong `database/queries` bằng MySQL Workbench hoặc mysql CLI để xem tổng hợp, lỗi gần nhất và bảng điểm pivot.
3. Đăng nhập bằng `dung`, mở bài thực hành trong PY02 và nộp đoạn mã. Đăng nhập bằng `trogiang`, mở **Chờ chấm**, chọn kết quả cho năm test. Kết quả hiển thị trong lịch sử của Dung.
4. Mở bài `SECOND-MAX` trong ngân hàng đề. Chọn **Tạo phiên bản mới**, mở bản sao rồi sửa một test. Kết quả đã chấm ở phiên bản 1 vẫn gắn với bộ test cũ.
5. Đăng nhập quản trị, mở **Chứng chỉ** và kiểm tra điều kiện cấp của An. Ngay sau khi nạp dữ liệu, An đủ 100% thực hành và 80% chuyên cần.

## Danh mục và nội dung khóa học

Khách có thể xem khóa đã công bố, lớp mở và bài học thử. Học viên vào khóa đã đăng ký để đọc bài, chuyển bài và đánh dấu hoàn thành. Quản trị viên quản lý tài khoản tại **Người dùng** và soạn chương, bài ngay trong trang khóa học.

Các bản cài mới tự nạp bài học Python và SQL. Với cơ sở dữ liệu đã tạo từ bản cũ, chạy lệnh sau trên đúng máy chủ CodeLab để nạp 11 bài mẫu. Script bổ sung các mục mẫu còn thiếu và mở rộng những bài vẫn dùng bản mô tả ban đầu. Có thể chạy lại lệnh này.

```powershell
python scripts/init_db.py --course-content-only
```

## Kiểm thử và EXPLAIN ANALYZE

Chạy trên dữ liệu mẫu mới nạp để kết quả khớp kịch bản. Hạn nộp và lịch học mẫu được tính từ thời điểm nạp.

```powershell
cmd /c "mysql --protocol=TCP --host=127.0.0.1 --port=33317 --default-character-set=utf8mb4 -uroot < database/tests/kiem_thu_kich_ban.sql"
.\.venv\Scripts\python.exe web/scripts/check_web.py
.\.venv\Scripts\python.exe web/scripts/check_accounts.py
.\.venv\Scripts\python.exe web/scripts/race_dang_ky.py
.\.venv\Scripts\python.exe scripts/benchmark_plans.py
```

Nếu chạy Docker, truyền `-p` vào lệnh MySQL để nhập mật khẩu root của container qua cổng công bố, hoặc chạy `docker compose exec -T` với CLI bên trong container. Lệnh tranh chỗ tạo một lớp demo `RACE-…` có một chỗ, dùng hai kết nối riêng và kiểm tra sĩ số cuối. Đo với Q33 và Q34 trên `PY-BENCH` có 200 học viên, 10.000 lượt nộp và 50.000 kết quả test. [Hướng dẫn so sánh chỉ mục](docs/toi-uu.md).

## Tài liệu

| Tài liệu | Nội dung |
| --- | --- |
| [Danh mục bảng và truy cập DB](docs/bang-va-truy-cap-co-so-du-lieu.md) | 31 bảng, khóa, view và các truy vấn từ backend |
| [ERD quan hệ](docs/erd-quan-he.md) | Khóa chính, khóa ngoại và bội số bằng Crow’s Foot |
| [ERD khái niệm](docs/erd-khai-niem.md) | Thực thể và quan hệ Chen theo phân hệ |
| [Cấu trúc và phép đo chỉ mục](docs/toi-uu.md) | Q33/Q34, cách đọc kế hoạch và so sánh đối chứng |
| [Lược đồ SQL](database/01_schema.sql) | 29 bảng lõi, gồm bảng nhật ký và bảng lưu giao dịch cũ |
| [Xác thực email](database/14_xac_thuc_tai_khoan.sql) | Bảng OTP, hạn mức và procedure tạo học viên đã xác thực |
| [Ngân hàng truy vấn](database/queries) | Q01–Q35 dùng với MySQL Workbench hoặc mysql CLI |

Mật khẩu mẫu và cấu hình máy chủ chỉ phục vụ demo trên máy cục bộ. Hệ thống dùng Bootstrap và Chart.js ngay trong thư mục static để giao diện hoạt động khi máy không có Internet.
