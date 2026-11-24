-- Số lớp và số học viên ghi danh của từng khóa
-- GROUP BY nhiều bảng
SELECT k.ma_code, k.ten_khoa_hoc, COUNT(DISTINCT l.ma_lop) AS so_lop,
       COUNT(DISTINCT d.ma_hoc_vien) AS so_hoc_vien
FROM KhoaHoc k LEFT JOIN LopHoc l USING (ma_khoa_hoc)
LEFT JOIN DangKyLop d ON d.ma_lop = l.ma_lop AND d.trang_thai <> 'DA_HUY'
GROUP BY k.ma_khoa_hoc, k.ma_code, k.ten_khoa_hoc ORDER BY so_hoc_vien DESC, k.ma_code;
