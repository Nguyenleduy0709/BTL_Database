-- Học viên đủ điều kiện nhận chứng chỉ
-- JOIN · so sánh chính xác
SELECT n.ho_ten, p.ma_lop, p.tien_do, c.ty_le
FROM v_tien_do_thuc_hanh p JOIN v_chuyen_can c USING (ma_dang_ky)
JOIN NguoiDung n ON n.ma_nguoi_dung = p.ma_hoc_vien
WHERE p.tong_bat_buoc > 0 AND p.tong_bat_buoc = p.so_da_dat AND c.tong_buoi > 0 AND c.co_mat * 100 >= c.tong_buoi * 80
ORDER BY n.ho_ten LIMIT 100;
