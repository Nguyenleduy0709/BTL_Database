-- Khối lượng dữ liệu PY-BENCH
-- COUNT DISTINCT · JOIN
SELECT g.ma_lop_code, COUNT(DISTINCT ln.ma_hoc_vien) AS hoc_vien,
       COUNT(DISTINCT ln.ma_lan_nop) AS lan_nop, COUNT(q.ma_test) AS ket_qua_test
FROM v_giao_bai g JOIN v_lan_nop_cong_khai ln USING (ma_giao) LEFT JOIN KetQuaTest q USING (ma_lan_nop)
WHERE g.ma_lop_code = 'PY-BENCH' GROUP BY g.ma_lop_code;
