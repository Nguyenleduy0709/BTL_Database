-- Học viên PY01 chưa nộp lần nào
-- Anti-join · NOT EXISTS
SELECT n.ho_ten FROM DangKyLop d JOIN NguoiDung n ON n.ma_nguoi_dung = d.ma_hoc_vien
WHERE d.ma_lop = 1 AND d.trang_thai <> 'DA_HUY' AND NOT EXISTS (
    SELECT 1 FROM v_lan_nop_cong_khai ln WHERE ln.ma_giao = 1 AND ln.ma_hoc_vien = d.ma_hoc_vien
) ORDER BY n.ho_ten;
