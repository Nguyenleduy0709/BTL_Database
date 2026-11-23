-- Khung giờ có nhiều lượt nộp nhất
-- HOUR · GROUP BY
SELECT HOUR(thoi_diem_nop) AS gio, COUNT(*) AS so_luot
FROM v_lan_nop_cong_khai GROUP BY HOUR(thoi_diem_nop) ORDER BY so_luot DESC, gio;
