-- Test có tỷ lệ sai cao nhất
-- Tỷ lệ · HAVING
SELECT t.ma_test, t.mo_ta, COUNT(*) AS so_ket_qua,
       ROUND(100 * SUM(k.la_dung = 0) / COUNT(*), 2) AS ty_le_loi
FROM KetQuaTest q JOIN TestCase t USING (ma_test) JOIN LoaiKetQua k USING (ma_loai)
GROUP BY t.ma_test, t.mo_ta HAVING COUNT(*) >= 3 ORDER BY ty_le_loi DESC, t.ma_test LIMIT 15;
