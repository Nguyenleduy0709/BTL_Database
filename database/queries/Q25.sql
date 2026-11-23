-- Các loại kết quả của bài PY01
-- GROUP BY · COUNT
SELECT k.ma_loai, k.ten, COUNT(q.ma_test) AS so_lan
FROM LoaiKetQua k LEFT JOIN (
    SELECT q.ma_test, q.ma_loai FROM KetQuaTest q JOIN v_lan_nop_cong_khai ln USING (ma_lan_nop)
    WHERE ln.ma_giao = 1
) q USING (ma_loai)
GROUP BY k.ma_loai, k.ten ORDER BY so_lan DESC, k.ma_loai;
