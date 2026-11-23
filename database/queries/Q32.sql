-- Các lớp dùng chung đề với hai hạn
-- Self-join
SELECT a.ma_bai, a.phien_ban, a.ma_lop_code AS lop_1, a.han_nop AS han_1,
       b.ma_lop_code AS lop_2, b.han_nop AS han_2
FROM v_giao_bai a JOIN v_giao_bai b ON a.ma_bai_tap = b.ma_bai_tap AND a.ma_giao < b.ma_giao
WHERE a.han_nop <> b.han_nop ORDER BY a.ma_bai, lop_1, lop_2;
