-- Xếp hạng thực hành lớp PY01
-- DENSE_RANK trong view
SELECT xep_hang, ho_ten, so_da_dat, tong_bat_buoc, diem_trung_binh
FROM v_bang_xep_hang_lop WHERE ma_lop = 1 ORDER BY xep_hang, ho_ten;
