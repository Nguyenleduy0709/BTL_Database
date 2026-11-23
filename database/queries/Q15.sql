-- Lần chấm gần nhất của từng học viên
-- ROW_NUMBER · PARTITION BY
WITH gan_nhat AS (
    SELECT ma_lan_nop, ma_hoc_vien, thoi_diem_cham, ROW_NUMBER() OVER (
        PARTITION BY ma_hoc_vien ORDER BY thoi_diem_cham DESC, ma_lan_nop DESC
    ) AS stt
    FROM v_lan_nop_cong_khai WHERE ma_giao = 1 AND trang_thai_cham <> 'CHO_CHAM'
)
SELECT ma_hoc_vien, ma_lan_nop, thoi_diem_cham FROM gan_nhat WHERE stt = 1 ORDER BY ma_hoc_vien;
