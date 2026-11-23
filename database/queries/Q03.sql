-- Chương và bài học từng khóa
-- JOIN nhiều bảng
SELECT k.ma_code, c.thu_tu AS chuong, c.ten_chuong, b.thu_tu AS bai, b.tieu_de
FROM KhoaHoc k JOIN Chuong c USING (ma_khoa_hoc) LEFT JOIN BaiHoc b USING (ma_chuong)
ORDER BY k.ma_code, c.thu_tu, b.thu_tu;
