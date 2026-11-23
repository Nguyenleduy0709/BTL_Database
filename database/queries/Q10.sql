-- Học viên đạt tất cả bài bắt buộc
-- Phép chia quan hệ
SELECT d.ma_lop, n.ho_ten FROM DangKyLop d
JOIN NguoiDung n ON n.ma_nguoi_dung = d.ma_hoc_vien
WHERE d.trang_thai <> 'DA_HUY'
AND EXISTS (SELECT 1 FROM GiaoBai g WHERE g.ma_lop = d.ma_lop AND g.bat_buoc AND g.thoi_diem_giao <= NOW())
AND NOT EXISTS (
    SELECT 1 FROM GiaoBai g WHERE g.ma_lop = d.ma_lop AND g.bat_buoc AND g.thoi_diem_giao <= NOW()
    AND NOT EXISTS (
        SELECT 1 FROM v_diem_lan_nop l WHERE l.ma_giao = g.ma_giao AND l.ma_hoc_vien = d.ma_hoc_vien AND l.dat
    )
)
ORDER BY d.ma_lop, n.ho_ten LIMIT 100;
