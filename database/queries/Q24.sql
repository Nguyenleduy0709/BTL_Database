-- Ghi danh còn hiệu lực theo tháng và lũy kế
-- CTE · SUM OVER
WITH dang_ky_thang AS (
    SELECT DATE_FORMAT(thoi_diem_dang_ky, '%Y-%m') AS thang, COUNT(*) AS so_dang_ky
    FROM DangKyLop WHERE trang_thai <> 'DA_HUY' GROUP BY DATE_FORMAT(thoi_diem_dang_ky, '%Y-%m')
)
SELECT thang, so_dang_ky, SUM(so_dang_ky) OVER (ORDER BY thang ROWS UNBOUNDED PRECEDING) AS luy_ke
FROM dang_ky_thang ORDER BY thang;
