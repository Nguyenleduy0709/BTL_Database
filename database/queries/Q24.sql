-- Doanh thu theo tháng và lũy kế
-- CTE · SUM OVER
WITH doanh_thu AS (
    SELECT DATE_FORMAT(thoi_diem, '%Y-%m') AS thang, SUM(so_tien) AS tong
    FROM ThanhToan WHERE trang_thai = 'THANH_CONG' GROUP BY DATE_FORMAT(thoi_diem, '%Y-%m')
)
SELECT thang, tong, SUM(tong) OVER (ORDER BY thang ROWS UNBOUNDED PRECEDING) AS luy_ke
FROM doanh_thu ORDER BY thang;
