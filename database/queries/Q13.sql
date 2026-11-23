-- Lượt nộp trên điểm trung bình của PY01
-- Subquery tương quan
SELECT a.ma_lan_nop, a.ma_hoc_vien, a.diem FROM v_diem_lan_nop a
WHERE a.ma_giao = 1 AND a.diem > (SELECT AVG(b.diem) FROM v_diem_lan_nop b WHERE b.ma_giao = a.ma_giao)
ORDER BY a.diem DESC, a.ma_lan_nop;
