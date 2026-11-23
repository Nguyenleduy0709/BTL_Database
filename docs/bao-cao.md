# Báo cáo kỹ thuật CodeLab

## 1. Giới thiệu và phạm vi

Đề tài xây dựng cơ sở dữ liệu quản lý khóa học lập trình cho một trung tâm đào tạo. Một khóa học dùng lại cho nhiều lớp. Mỗi lớp dùng ngân hàng bài chung và quy định hạn riêng cho từng bài được giao. Người học có thể nộp nhiều lượt, hệ thống ghi toàn bộ mã nguồn và kết quả theo từng test.

Ba nhóm người dùng gồm quản trị viên, giảng viên và học viên. Django render giao diện và truyền tham số đến MySQL. Bộ chấm ghi kết quả do người demo chọn, hoặc sinh mã kết quả mẫu. Giao diện học phí lưu giao dịch giả lập. Bài tập tập trung vào tính toàn vẹn, phân tích báo cáo và thực nghiệm chỉ mục.

## 2. Kịch bản nghiệp vụ

| Bước | Nghiệp vụ | Đối tượng chính |
| --- | --- | --- |
| 1 | Mở PY01 và PY02 cùng dạy Python cơ bản | `KhoaHoc`, `LopHoc`, `PhanCongGiangDay` |
| 2 | An, Bình và Chi đăng ký PY01 | `DangKyLop`, `sp_dang_ky_lop` |
| 3 | Giảng viên dùng cùng phiên bản bài tìm phần tử lớn thứ hai, quy định hạn khác nhau | `BaiTap`, `TestCase`, `GiaoBai` |
| 4 | An đúng 3/5 rồi 5/5. Bình đúng 4/5. Chi chưa nộp | `LanNop`, `KetQuaTest` |
| 5 | Giảng viên xem số người đạt và lấy điểm tốt nhất | `v_thong_ke_bai_giao`, `v_trang_thai_hoc_vien_bai_giao` |
| 6 | Giảng viên quyết định chữa trường hợp giá trị lớn nhất lặp lại | `v_loi_lan_gan_nhat` |

## 3. Quy tắc và cơ chế thực thi

| Mã | Quy tắc | Cơ chế |
| --- | --- | --- |
| R1 | Giữ lịch sử nộp. Điểm tốt nhất và thống kê lỗi mới nhất lấy từ hai phép tổng hợp riêng | `MAX(diem)`, `ROW_NUMBER` theo giờ chấm giảm dần và mã lần nộp |
| R2 | Ít nhất một lần đúng đủ mọi test thì đạt | `v_diem_lan_nop.dat` tính theo từng lượt, sau đó lấy `MAX(dat)` |
| R3 | Tiến độ bằng số bài bắt buộc đã đạt chia cho số bài bắt buộc đã giao | `NULLIF` trả `NULL` khi lớp chưa có bài bắt buộc |
| R4 | Học viên chưa nộp vẫn có dòng trong bảng điểm | Ghi danh còn hiệu lực làm tập gốc của `LEFT JOIN` |
| R5 | Khóa đề và bộ test khi đã có lượt nộp | Trigger kiểm tra lượt nộp theo phiên bản và procedure sao chép phiên bản |
| R6 | Đăng ký đồng thời không vượt sĩ số | Khóa hàng lớp bằng `FOR UPDATE`, kiểm tra rồi ghi trong một transaction |
| R7 | Nộp đúng lớp, hạn, ngôn ngữ và giới hạn lượt | Trigger `trg_lannop_bi`, khóa bài giao khi ghi lượt |
| R8 | Một lô chấm đủ và chỉ chứa test của đúng bài | `JSON_SCHEMA_VALID`, `JSON_TABLE`, khóa ghép, trigger và rollback |
| R9 | Lớp có đúng một giảng viên chính qua quy trình quản lý. Người giao được phân công | Cột sinh và UNIQUE chặn chính thứ hai. Procedure tạo lớp và phân công trong cùng transaction. Khóa ngoại ghép kiểm tra người giao |
| R10 | Tổng tiền thành công không vượt học phí | Trigger khóa đăng ký/lớp và so sánh tổng. Procedure sửa lớp kiểm tra khi hạ học phí |
| R11 | Chứng chỉ yêu cầu đủ bài bắt buộc và chuyên cần từ 80% | `sp_cap_chung_chi` so sánh số đếm chính xác trước khi cấp |
| R12 | Tính sĩ số, điểm, tiến độ và công nợ từ dữ liệu nguồn | View và function |

Ứng dụng phân biệt `CHO_CHAM` với `CHUA_NOP` và `CHUA_DAT`. Một lượt chờ chấm được tính là đã nộp nhưng chưa có điểm. Một lượt lỗi biên dịch có điểm 0 và không có kết quả từng test. Nếu đó là kết quả chấm mới nhất, học viên không đóng góp vào thống kê sai theo test. Chuyên cần tính trên các buổi đã kết thúc, trong đó đi muộn vẫn được tính có mặt. Lớp đang mở nhận đăng ký mới, lớp đang học dùng giá trị ghi danh để kiểm tra quyền nộp.

## 4. Thiết kế khái niệm và quan hệ

[Mô hình Chen](erd-khai-niem.md) mô tả yêu cầu theo từng phân hệ. [Sơ đồ Crow’s Foot](erd-quan-he.md) thể hiện các cạnh khóa ngoại. [SQL tạo bảng](../database/01_schema.sql) chứa kiểu dữ liệu, khóa và điều kiện kiểm tra của từng quan hệ.

Các phân hệ có 28 bảng nghiệp vụ gồm người dùng và vai trò (3), đào tạo (4), tổ chức lớp (7), tài chính và phản hồi (3), ngân hàng bài (6), giao và chấm bài (5). Bảng `NhatKyHeThong` bổ sung dấu vết thao tác. Danh mục dùng khóa cha tự tham chiếu. Quan hệ N–N dùng bảng kết hợp và khóa ghép.

## 5. Chuẩn hóa

Một bảng phẳng `PhieuNop(ma_lan_nop, ma_test, ma_hv, ho_ten, email, ma_lop, ma_khoa_hoc, ten_khoa, ma_giao, han_nop, ma_bai_tap, de_bai, trong_so, ma_loai, ...)` lặp lại thông tin khóa học ở mỗi kết quả test. Đổi tên khóa phải cập nhật nhiều dòng. Xóa lượt cuối làm mất thông tin đề và test nếu chúng chỉ tồn tại trong bảng phẳng. Thêm khóa chưa có lượt nộp buộc để trống khóa nhận diện kết quả.

- **1NF.** Mỗi hàng biểu diễn một kết quả test, thay cho một cột danh sách kết quả hoặc nhiều cột `test_1`, `test_2`, `test_3`. Khóa nhận diện là `(ma_lan_nop, ma_test)`.
- **2NF.** `ma_lan_nop → ma_giao, ma_hoc_vien, ma_ngon_ngu, ma_nguon, thoi_diem_nop` và `ma_test → ma_bai_tap, du_lieu_vao, ket_qua_mong_doi, trong_so`. Tách `LanNop` và `TestCase` để `KetQuaTest` giữ riêng thông tin phụ thuộc vào cả cặp.
- **3NF.** `ma_lan_nop → ma_giao → ma_lop`, `ma_lop → ma_khoa_hoc → ten_khoa_hoc` và `ma_loai → la_dung, ten`. Tách `GiaoBai`, `LopHoc`, `KhoaHoc`, `LoaiKetQua`. Tách các quan hệ đăng ký, phân công, lý thuyết, tài chính và lớp theo sự kiện tương ứng.

Mỗi dòng dưới đây nêu các khóa ứng viên dùng trong thiết kế logic, phân cách bằng dấu chấm phẩy, và thuộc tính phụ thuộc vào khóa. Với tập phụ thuộc nghiệp vụ đã mô hình hóa, các định thức không tầm thường của dữ liệu logic đều là siêu khóa, đáp ứng 3NF và BCNF. `la_chinh` là cột ảo phục vụ UNIQUE có điều kiện, đứng ngoài tập thuộc tính của mô hình logic. `so_dien_thoai` và `ma_giao_dich` duy nhất khi có giá trị, vì vậy không dùng làm khóa ứng viên bắt buộc. Nhật ký giữ bản chụp JSON cho mục đích audit.

| Bảng | Khóa ứng viên | Phụ thuộc vào khóa | Chuẩn |
| --- | --- | --- | --- |
| `VaiTro` | ma_vai_tro; ten_vai_tro | Mô tả vai trò | BCNF |
| `NguoiDung` | ma_nguoi_dung; ten_dang_nhap; email | Họ tên, băm mật khẩu, liên hệ và trạng thái | BCNF |
| `NguoiDungVaiTro` | ma_nguoi_dung + ma_vai_tro | Ngày gán vai trò | BCNF |
| `DanhMucKhoaHoc` | ma_danh_muc; ten_danh_muc | Danh mục cha | BCNF |
| `KhoaHoc` | ma_khoa_hoc; ma_code | Tên khóa, danh mục, mô tả, trình độ, người tạo | BCNF |
| `Chuong` | ma_chuong; ma_khoa_hoc + thu_tu | Tên chương | BCNF |
| `BaiHoc` | ma_bai_hoc; ma_chuong + thu_tu | Tiêu đề, nội dung và thời lượng | BCNF |
| `LopHoc` | ma_lop; ma_code | Khóa, lịch bắt đầu/kết thúc, học phí, giới hạn sĩ số, trạng thái | BCNF |
| `PhanCongGiangDay` | ma_lop + ma_giang_vien | Vai trò dạy và ngày phân công | BCNF |
| `DangKyLop` | ma_dang_ky; ma_lop + ma_hoc_vien | Thời điểm, trạng thái ghi danh | BCNF |
| `TienDoBaiHoc` | ma_dang_ky + ma_bai_hoc | Thời điểm hoàn thành bài lý thuyết | BCNF |
| `BuoiHoc` | ma_buoi; ma_lop + so_thu_tu | Giờ học, hình thức, địa điểm và bài học | BCNF |
| `DiemDanh` | ma_buoi + ma_dang_ky | Trạng thái buổi và ghi chú | BCNF |
| `ThongBaoLop` | ma_thong_bao | Lớp, người đăng, nội dung và ghim | BCNF |
| `ThanhToan` | ma_thanh_toan | Đăng ký, số tiền, phương thức và thời điểm | BCNF |
| `DanhGiaLopHoc` | ma_dang_ky | Số sao, nhận xét và thời điểm | BCNF |
| `ChungChi` | ma_chung_chi; ma_dang_ky; so_hieu | Ngày cấp, xếp loại tại lúc cấp | BCNF |
| `ChuDe` | ma_chu_de; ten_chu_de | Mô tả chủ đề | BCNF |
| `BaiTap` | ma_bai_tap; ma_code + phien_ban | Đề, giới hạn tài nguyên, tác giả và độ khó | BCNF |
| `BaiTapChuDe` | ma_bai_tap + ma_chu_de | Một cặp biểu diễn quan hệ, không có thuộc tính mô tả | BCNF |
| `NgonNguLapTrinh` | ma_ngon_ngu; ten + phien_ban | Định danh và phiên bản môi trường | BCNF |
| `BaiTapNgonNgu` | ma_bai_tap + ma_ngon_ngu | Mã khung của cặp bài và ngôn ngữ | BCNF |
| `TestCase` | ma_test; ma_bai_tap + thu_tu | Đầu vào, đáp án, trọng số và cờ test mẫu | BCNF |
| `GiaoBai` | ma_giao; ma_lop + ma_bai_tap | Người giao, bài học, thời điểm, hạn, bắt buộc và giới hạn lượt | BCNF |
| `LanNop` | ma_lan_nop | Bài giao, học viên, ngôn ngữ, mã nguồn và trạng thái | BCNF |
| `LoaiKetQua` | ma_loai | Tên, mô tả và cờ đúng | BCNF |
| `KetQuaTest` | ma_lan_nop + ma_test | Mã kết quả và số đo thực thi | BCNF |
| `NhanXetLanNop` | ma_nhan_xet | Lần nộp, giảng viên, dòng, nội dung và thời điểm | BCNF |

Sĩ số hiện tại, điểm, tiến độ và công nợ được suy ra từ dữ liệu nguồn. `ChungChi.xep_loai` phản ánh quyết định tại ngày cấp. Một thay đổi về buổi học sau đó không sửa giá trị chứng chỉ đã phát hành.

## 6. Thiết kế vật lý và toàn vẹn

MySQL dùng InnoDB, bộ ký tự `utf8mb4` và collation `utf8mb4_unicode_ci`. Điểm và trọng số dùng `DECIMAL`. Thời điểm nộp và chấm có độ chính xác mili giây. `BIGINT` dùng cho lượt nộp và nhật ký. Các khóa ngoại bảo vệ bản ghi lịch sử. Chương và bài học thuộc nội dung dùng cascade, có điều kiện tham chiếu từ tiến độ và giao bài.

| Loại ràng buộc | Ví dụ |
| --- | --- |
| Miền và liên bộ | `CHECK` trọng số dương, số sao 1–5, giờ kết thúc sau giờ bắt đầu |
| Khóa và tham chiếu | Mỗi người đăng ký một lần cho một lớp, mỗi cặp lượt/test có tối đa một dòng, người giao phải thuộc phân công |
| Liên quan hệ | Bài học phải thuộc đúng khóa, buổi học và ghi danh phải cùng lớp, người phân công phải có vai trò giảng viên |
| Giao dịch | Đăng ký khóa hàng lớp, ghi kết quả chấm đồng nhất, cấp chứng chỉ sau khi đủ điều kiện |

Điểm là tổng trọng số test đúng chia tổng trọng số test. Cờ đạt so sánh số test đúng với tổng, vì làm tròn điểm hiển thị có thể che phần điểm rất nhỏ. Đặt chỉ mục ghép theo bài giao, học viên và thời điểm để hỗ trợ báo cáo. So sánh chỉ mục bằng [thực nghiệm Q33 và Q34](toi-uu.md).

## 7. Giao dịch và quyền

`sp_dang_ky_lop` bắt đầu transaction, đọc khóa lớp theo PK, kiểm tra chỗ trống rồi thêm hoặc kích hoạt lại đăng ký. Mọi thao tác đăng ký qua tài khoản web đều dùng routine này. `sp_ghi_ket_qua_cham` khóa lượt chờ chấm, kiểm tra JSON, ghi các kết quả, xác nhận số test rồi cập nhật trạng thái. Handler rollback giữ lượt chờ chấm khi có lỗi. Thay giảng viên chính diễn ra nguyên tử và giữ phân công cũ dưới vai trò trợ giảng để bảo toàn bài đã giao.

Tài khoản MySQL `app_web` đọc dữ liệu và gọi các procedure nghiệp vụ. Quyền ghi đơn bảng được cấp theo danh sách thao tác cần thiết cho quản lý nội dung, điểm danh, đánh giá và nhận xét. `app_readonly` có `SELECT` và `SHOW VIEW` trên các đối tượng phục vụ kiểm thử truy vấn và phân tích kế hoạch. Quyền học viên, giảng viên và quản trị được kiểm tra ở lớp Django. `@app_user_id` gắn người thao tác vào nhật ký các bảng ghi danh, giao bài và thanh toán.

## 8. Kết quả kiểm thử và trình diễn

| Kiểm thử | Kết quả lúc nạp mẫu |
| --- | --- |
| PY01 tổng hợp | 3 lượt, 2 người đã thử, 1 đạt, 1 chưa đạt, 1 chưa nộp |
| Điểm tốt nhất | An 100%, Bình 80%, Chi NULL |
| Lượt chấm gần nhất | 1 người sai test 5, 0 người sai các test còn lại |
| Khóa bộ test | Sửa bản đã có lượt nộp bị chặn. Tạo phiên bản mới sao chép đủ thành phần |
| Chấm thiếu test hoặc test sai bài | Không thêm hàng kết quả, lần nộp vẫn chờ chấm |
| Tranh chỗ | Hai kết nối, một đăng ký thành công, một báo lớp đầy, sĩ số cuối 1/1 |
| Học phí và chứng chỉ | Từ chối thu vượt học phí. Cấp chứng chỉ cho An tại ngưỡng chuyên cần 80% |
| Ngân hàng truy vấn | 35 câu SQL và 35 kế hoạch chạy qua script kiểm thử. Kết nối chỉ đọc được kiểm tra bằng thao tác ghi bị từ chối |

[Script kiểm thử SQL](../database/tests/kiem_thu_kich_ban.sql), [kiểm thử web và phân quyền](../web/scripts/check_web.py), [chương trình thử đồng thời](../web/scripts/race_dang_ky.py) và [kịch bản bảo vệ](kich-ban-bao-ve.md) hỗ trợ tái hiện kết quả.

## 9. Kết luận và phạm vi phát triển

CodeLab trả lời hai câu hỏi độc lập của giảng viên trên cùng lịch sử dữ liệu: ai đã từng qua đủ test, và test nào vướng nhiều nhất ở thời điểm hiện tại. Ứng dụng demo giữ lớp web mỏng, dùng các view và procedure có thể chạy độc lập từ MySQL Workbench. Một hệ thống vận hành thật có thể bổ sung bộ chấm cách ly, tích hợp cổng thanh toán, kiểm soát vòng đời phiên đăng nhập và quy trình vận hành cho dữ liệu vượt quy mô demo.

Tài liệu kỹ thuật tham khảo [MySQL Locking Reads](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html), [MySQL Window Functions](https://dev.mysql.com/doc/refman/8.0/en/window-functions.html), [Django Raw SQL](https://docs.djangoproject.com/en/5.2/topics/db/sql/).
