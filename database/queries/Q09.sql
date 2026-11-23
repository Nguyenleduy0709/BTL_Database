-- Học viên PY01 chưa nộp bằng LEFT JOIN
-- Anti-join · IS NULL
SELECT n.ho_ten FROM DangKyLop d JOIN NguoiDung n ON n.ma_nguoi_dung = d.ma_hoc_vien
LEFT JOIN v_lan_nop_cong_khai ln ON ln.ma_giao = 1 AND ln.ma_hoc_vien = d.ma_hoc_vien
WHERE d.ma_lop = 1 AND d.trang_thai <> 'DA_HUY' AND ln.ma_lan_nop IS NULL ORDER BY n.ho_ten;
