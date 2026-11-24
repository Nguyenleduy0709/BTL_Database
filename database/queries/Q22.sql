-- Học viên dưới ngưỡng chuyên cần 80%
-- JOIN · Bộ lọc trên view
SELECT l.ma_code, n.ho_ten, c.co_mat, c.tong_buoi, c.ty_le
FROM v_chuyen_can c JOIN v_lop_hoc l USING (ma_lop)
JOIN NguoiDung n ON n.ma_nguoi_dung = c.ma_hoc_vien
WHERE c.ty_le < 80 ORDER BY c.ty_le, l.ma_code, n.ho_ten LIMIT 100;
