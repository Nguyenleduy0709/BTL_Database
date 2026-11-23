-- An cải thiện điểm qua các lượt
-- LAG · chênh lệch
SELECT ma_lan_nop, thoi_diem_nop, diem,
       diem - LAG(diem) OVER (PARTITION BY ma_giao ORDER BY thoi_diem_nop, ma_lan_nop) AS diem_tang,
       TIMESTAMPDIFF(MINUTE, LAG(thoi_diem_nop) OVER (
           PARTITION BY ma_giao ORDER BY thoi_diem_nop, ma_lan_nop), thoi_diem_nop) AS phut_cach_nhau
FROM v_diem_lan_nop WHERE ma_hoc_vien = 3 ORDER BY ma_giao, thoi_diem_nop, ma_lan_nop;
