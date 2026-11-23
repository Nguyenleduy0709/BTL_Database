-- Tiến độ thực hành và lý thuyết
-- NULLIF · JOIN view
SELECT n.ho_ten, p.tong_bat_buoc, p.so_da_dat, p.tien_do AS thuc_hanh, l.tien_do AS ly_thuyet
FROM v_tien_do_thuc_hanh p JOIN v_tien_do_ly_thuyet l USING (ma_dang_ky)
JOIN NguoiDung n ON n.ma_nguoi_dung = p.ma_hoc_vien WHERE p.ma_lop = 1 ORDER BY n.ho_ten;
