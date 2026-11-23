-- Lỗi gần nhất trên PY-BENCH
-- CTE · window · EXPLAIN
SELECT e.thu_tu, e.mo_ta, e.so_nguoi_sai
FROM v_loi_lan_gan_nhat e JOIN v_giao_bai g USING (ma_giao)
WHERE g.ma_lop_code = 'PY-BENCH' ORDER BY e.so_nguoi_sai DESC, e.thu_tu;
