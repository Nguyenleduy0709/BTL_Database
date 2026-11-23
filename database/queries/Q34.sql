-- Bảng điểm trên PY-BENCH
-- View · MAX · EXPLAIN
SELECT n.ho_ten, s.so_lan_nop, s.diem_tot_nhat, s.trang_thai
FROM v_trang_thai_hoc_vien_bai_giao s JOIN v_giao_bai g USING (ma_giao)
JOIN NguoiDung n ON n.ma_nguoi_dung = s.ma_hoc_vien
WHERE g.ma_lop_code = 'PY-BENCH' ORDER BY s.diem_tot_nhat DESC, s.ma_hoc_vien;
