-- Test sai ở lượt chấm mới nhất
-- ROW_NUMBER trong view
SELECT thu_tu, mo_ta, so_nguoi_co_ket_qua, so_nguoi_sai
FROM v_loi_lan_gan_nhat WHERE ma_giao = 1 ORDER BY so_nguoi_sai DESC, thu_tu;
