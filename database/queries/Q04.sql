-- Giảng viên chính và trợ giảng
-- JOIN · CASE
SELECT l.ma_code, n.ho_ten,
       CASE p.vai_tro_day WHEN 'CHINH' THEN 'Giảng viên chính' ELSE 'Trợ giảng' END AS vai_tro
FROM LopHoc l JOIN PhanCongGiangDay p USING (ma_lop)
JOIN NguoiDung n ON n.ma_nguoi_dung = p.ma_giang_vien ORDER BY l.ma_code, p.vai_tro_day;
