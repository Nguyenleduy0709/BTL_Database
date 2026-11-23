-- Tình trạng từng học viên của bài PY01
-- LEFT JOIN · tổng hợp
SELECT n.ho_ten, s.so_lan_nop, s.so_lan_da_cham, s.diem_tot_nhat, s.trang_thai
FROM v_trang_thai_hoc_vien_bai_giao s JOIN NguoiDung n ON n.ma_nguoi_dung = s.ma_hoc_vien
WHERE s.ma_giao = 1 ORDER BY s.ma_hoc_vien;
