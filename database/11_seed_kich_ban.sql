USE btlcsdl;
SET @demo_hash = CONVERT(UNHEX(@codelab_demo_hash_hex) USING ascii);
SET NAMES utf8mb4;
SET @app_user_id = NULL;

INSERT INTO NguoiDung(ma_nguoi_dung, ten_dang_nhap, email, mat_khau_hash, ho_ten) VALUES
(1, 'admin', 'admin@codelab.example', @demo_hash, 'Quản trị CodeLab'),
(2, 'giangvien', 'giangvien@codelab.example', @demo_hash, 'Nguyễn Minh Khoa'),
(3, 'an', 'an@codelab.example', @demo_hash, 'Nguyễn Bảo An'),
(4, 'binh', 'binh@codelab.example', @demo_hash, 'Trần Quốc Bình'),
(5, 'chi', 'chi@codelab.example', @demo_hash, 'Lê Khánh Chi'),
(6, 'dung', 'dung@codelab.example', @demo_hash, 'Phạm Thùy Dung'),
(7, 'ha', 'ha@codelab.example', @demo_hash, 'Võ Thanh Hà'),
(8, 'trogiang', 'trogiang@codelab.example', @demo_hash, 'Phan Mai Linh');
INSERT INTO NguoiDungVaiTro(ma_nguoi_dung, ma_vai_tro) VALUES
(1,1), (2,2), (3,3), (4,3), (5,3), (6,3), (7,3), (8,2);

INSERT INTO KhoaHoc(ma_khoa_hoc, ma_code, ten_khoa_hoc, ma_danh_muc, mo_ta, ma_nguoi_tao, trang_thai) VALUES
(1, 'PY-CB', 'Python cơ bản', 2, 'Học Python qua bài tập về vòng lặp, danh sách và thuật toán.', 2, 'CONG_BO'),
(2, 'SQL-CB', 'SQL thực hành', 3, 'Luyện truy vấn quan hệ trên MySQL.', 2, 'CONG_BO');
INSERT INTO Chuong VALUES (1,1,1,'Nhập môn Python'), (2,1,2,'Mảng và danh sách'), (3,2,1,'Truy vấn dữ liệu');
INSERT INTO BaiHoc VALUES
(1,1,1,'Biến và kiểu dữ liệu','Khai báo biến và chuyển đổi giữa các kiểu dữ liệu Python.',45),
(2,1,2,'Điều kiện và vòng lặp','Sử dụng if, for và while để điều khiển luồng chương trình.',60),
(3,2,1,'Duyệt danh sách','Duyệt một danh sách bằng for. Theo dõi hai giá trị lớn nhất phân biệt sau mỗi bước.',60),
(4,2,2,'Sắp xếp và tập hợp','Dùng set để loại trùng, sau đó dùng sorted để xếp thứ tự các phần tử.',45),
(5,3,1,'JOIN và GROUP BY','Ghép dữ liệu theo khóa ngoại rồi tổng hợp theo nhóm.',60);

CALL sp_tao_lop('PY01', 1, CURRENT_DATE - INTERVAL 21 DAY, CURRENT_DATE + INTERVAL 28 DAY, 16, 2, @py01);
CALL sp_tao_lop('PY02', 1, CURRENT_DATE - INTERVAL 7 DAY, CURRENT_DATE + INTERVAL 42 DAY, 12, 8, @py02);
CALL sp_tao_lop('SQL01', 2, CURRENT_DATE + INTERVAL 3 DAY, CURRENT_DATE + INTERVAL 45 DAY, 20, 2, @sql01);
CALL sp_phan_cong_giang_vien(@py01, 8, 'TRO_GIANG');
CALL sp_dang_ky_lop(@py01, 3, @dk_an);
CALL sp_dang_ky_lop(@py01, 4, @dk_binh);
CALL sp_dang_ky_lop(@py01, 5, @dk_chi);
CALL sp_dang_ky_lop(@py02, 6, @dk_dung);
CALL sp_sua_lop(@py01, 'PY01', CURRENT_DATE - INTERVAL 21 DAY, CURRENT_DATE + INTERVAL 28 DAY, 16, 'DANG_HOC');

INSERT INTO TienDoBaiHoc(ma_dang_ky, ma_bai_hoc) VALUES
(@dk_an,1), (@dk_an,2), (@dk_an,3), (@dk_binh,1), (@dk_binh,2), (@dk_chi,1);
INSERT INTO BuoiHoc(ma_buoi, ma_lop, so_thu_tu, bat_dau, ket_thuc, hinh_thuc, dia_diem, ma_bai_hoc) VALUES
(1, @py01, 1, NOW()-INTERVAL 20 DAY, NOW()-INTERVAL 20 DAY+INTERVAL 2 HOUR, 'TRUC_TIEP', 'Phòng A201', 1),
(2, @py01, 2, NOW()-INTERVAL 16 DAY, NOW()-INTERVAL 16 DAY+INTERVAL 2 HOUR, 'TRUC_TIEP', 'Phòng A201', 2),
(3, @py01, 3, NOW()-INTERVAL 12 DAY, NOW()-INTERVAL 12 DAY+INTERVAL 2 HOUR, 'ONLINE', 'Lớp trực tuyến', 3),
(4, @py01, 4, NOW()-INTERVAL 8 DAY, NOW()-INTERVAL 8 DAY+INTERVAL 2 HOUR, 'TRUC_TIEP', 'Phòng A201', 4),
(5, @py01, 5, NOW()-INTERVAL 4 DAY, NOW()-INTERVAL 4 DAY+INTERVAL 2 HOUR, 'TRUC_TIEP', 'Phòng A201', NULL),
(6, @py01, 6, NOW()+INTERVAL 3 DAY, NOW()+INTERVAL 3 DAY+INTERVAL 2 HOUR, 'TRUC_TIEP', 'Phòng A201', NULL);
INSERT INTO DiemDanh(ma_buoi, ma_dang_ky, trang_thai) VALUES
(1,@dk_an,'CO_MAT'), (2,@dk_an,'MUON'), (3,@dk_an,'CO_MAT'), (4,@dk_an,'CO_MAT'), (5,@dk_an,'VANG'),
(1,@dk_binh,'CO_MAT'), (2,@dk_binh,'CO_MAT'), (3,@dk_binh,'VANG_CO_PHEP'), (4,@dk_binh,'MUON'),
(1,@dk_chi,'CO_MAT'), (2,@dk_chi,'VANG'), (3,@dk_chi,'CO_MAT');
INSERT INTO ThongBaoLop(ma_lop, ma_nguoi_dang, tieu_de, noi_dung, ghim) VALUES
(@py01, 2, 'Bài thực hành tuần này', 'Hãy thử thêm mảng toàn số âm và mảng có phần tử lớn nhất lặp lại trước khi nộp.', 1);

CALL sp_tao_bai_tap('SECOND-MAX', 'Phần tử lớn thứ hai phân biệt',
    'Cho một mảng số nguyên. In ra giá trị lớn thứ hai phân biệt. Nếu có ít hơn hai giá trị phân biệt, in NONE. Dữ liệu vào gồm các số nguyên cách nhau bởi dấu cách.',
    'TRUNG_BINH', 2, 1, 1, @bai_max);
INSERT INTO BaiTapChuDe VALUES (@bai_max, 2);
INSERT INTO TestCase(ma_test, ma_bai_tap, thu_tu, mo_ta, du_lieu_vao, ket_qua_mong_doi, la_test_mau) VALUES
(1,@bai_max,1,'Các số dương phân biệt','3 9 4','4',1),
(2,@bai_max,2,'Chỉ hai phần tử','2 5','2',1),
(3,@bai_max,3,'Mọi phần tử bằng nhau','4 4 4','NONE',0),
(4,@bai_max,4,'Mảng toàn số âm','-8 -3 -6 -9','-6',0),
(5,@bai_max,5,'Giá trị lớn nhất lặp lại','7 9 9 4','7',0);
CALL sp_tao_bai_tap('TONG-HAI-SO', 'Tổng hai số nguyên',
    'Đọc hai số nguyên và in ra tổng.', 'DE', 2, 1, 3, @bai_tong);
INSERT INTO TestCase(ma_test, ma_bai_tap, thu_tu, mo_ta, du_lieu_vao, ket_qua_mong_doi, la_test_mau)
VALUES (6,@bai_tong,1,'Hai số dương','3 9','12',1);
INSERT INTO GiaoBai(ma_lop, ma_bai_tap, ma_bai_hoc, ma_nguoi_giao, thoi_diem_giao, han_nop, so_lan_nop_toi_da) VALUES
(@py01, @bai_max, 3, 2, NOW()-INTERVAL 7 DAY, NOW()+INTERVAL 14 DAY, 5),
(@py02, @bai_max, 3, 8, NOW()-INTERVAL 3 DAY, NOW()+INTERVAL 21 DAY, 5);

INSERT INTO LanNop(ma_giao, ma_hoc_vien, ma_ngon_ngu, ma_nguon, thoi_diem_nop) VALUES
(1,3,1,'a = sorted(map(int, input().split()), reverse=True)\nprint(a[1] if len(a) > 1 and a[0] != a[-1] else "NONE")', NOW(3)-INTERVAL 3 DAY),
(1,3,1,'a = sorted(set(map(int, input().split())))\nprint(a[-2] if len(a) >= 2 else "NONE")', NOW(3)-INTERVAL 2 DAY),
(1,4,1,'a = list(map(int, input().split()))\nprint(sorted(a)[-2] if len(set(a)) >= 2 else "NONE")', NOW(3)-INTERVAL 1 DAY);
INSERT INTO KetQuaTest(ma_lan_nop, ma_test, ma_loai, thoi_gian_chay_ms, bo_nho_kb)
SELECT ln.ma_lan_nop, t.ma_test,
       CASE WHEN ln.ma_lan_nop = 1 AND t.ma_test IN (4,5) THEN 'WA'
            WHEN ln.ma_lan_nop = 3 AND t.ma_test = 5 THEN 'WA' ELSE 'AC' END,
       12 + t.thu_tu, 4096
FROM LanNop ln CROSS JOIN TestCase t WHERE ln.ma_giao = 1 AND t.ma_bai_tap = @bai_max;
UPDATE LanNop SET trang_thai_cham = 'DA_CHAM', thoi_diem_cham = thoi_diem_nop + INTERVAL 1 MINUTE WHERE ma_giao = 1;
INSERT INTO NhanXetLanNop(ma_lan_nop, ma_giang_vien, dong_code, noi_dung)
VALUES (3, 2, 2, 'Loại các giá trị trùng trước khi lấy phần tử lớn thứ hai.');
