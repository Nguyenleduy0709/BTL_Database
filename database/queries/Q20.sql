-- Chuyên cần lớp PY01
-- Gom nhóm có điều kiện
SELECT n.ho_ten, c.tong_buoi, c.co_mat, c.ty_le
FROM v_chuyen_can c JOIN NguoiDung n ON n.ma_nguoi_dung = c.ma_hoc_vien
WHERE c.ma_lop = 1 ORDER BY c.ty_le DESC, n.ho_ten;
