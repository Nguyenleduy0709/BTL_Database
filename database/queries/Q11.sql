-- Tỷ lệ đạt thấp hơn 30%
-- GROUP BY · HAVING
SELECT g.ma_lop_code, g.tieu_de, COUNT(*) AS si_so,
       ROUND(100 * SUM(s.trang_thai = 'DAT') / COUNT(*), 2) AS ty_le_dat
FROM v_trang_thai_hoc_vien_bai_giao s JOIN v_giao_bai g USING (ma_giao)
GROUP BY g.ma_giao, g.ma_lop_code, g.tieu_de
HAVING SUM(s.trang_thai = 'DAT') / COUNT(*) < 0.30 ORDER BY ty_le_dat;
