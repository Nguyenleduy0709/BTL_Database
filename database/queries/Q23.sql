-- Doanh thu từng khóa học
-- GROUP BY nhiều bảng
SELECT k.ma_code, k.ten_khoa_hoc, COALESCE(SUM(t.so_tien), 0) AS doanh_thu
FROM KhoaHoc k LEFT JOIN LopHoc l USING (ma_khoa_hoc) LEFT JOIN DangKyLop d USING (ma_lop)
LEFT JOIN ThanhToan t ON t.ma_dang_ky = d.ma_dang_ky AND t.trang_thai = 'THANH_CONG'
GROUP BY k.ma_khoa_hoc, k.ma_code, k.ten_khoa_hoc ORDER BY doanh_thu DESC, k.ma_code;
