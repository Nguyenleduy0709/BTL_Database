USE btlcsdl;
SET NAMES utf8mb4;

INSERT INTO VaiTro VALUES
(1, 'ADMIN', 'Quản trị viên'), (2, 'GIANG_VIEN', 'Giảng viên'), (3, 'HOC_VIEN', 'Học viên');

INSERT INTO DanhMucKhoaHoc VALUES
(1, 'Lập trình', NULL), (2, 'Python', 1), (3, 'Cơ sở dữ liệu', 1), (4, 'Thuật toán', 2);

INSERT INTO NgonNguLapTrinh VALUES
(1, 'Python', '3.11'), (2, 'C++', '17'), (3, 'Java', '21'), (4, 'SQL', 'MySQL 8');

INSERT INTO ChuDe VALUES
(1, 'Mảng và danh sách', 'Duyệt mảng và xử lý danh sách'),
(2, 'Sắp xếp', 'Sắp xếp và chọn phần tử'),
(3, 'Số học', 'Biểu thức và phép tính cơ bản'),
(4, 'Câu truy vấn', 'Ghép bảng và tổng hợp');

INSERT INTO LoaiKetQua VALUES
('AC', 'Chính xác', 'Đầu ra đúng với đáp án', 1),
('WA', 'Sai kết quả', 'Đầu ra khác đáp án', 0),
('TLE', 'Quá thời gian', 'Vượt giới hạn thời gian', 0),
('MLE', 'Quá bộ nhớ', 'Vượt giới hạn bộ nhớ', 0),
('RE', 'Lỗi thực thi', 'Chương trình dừng khi đang chạy', 0);
