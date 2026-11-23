-- Chủ đề và độ khó ở ngân hàng bài
-- GROUP BY · COUNT DISTINCT
SELECT c.ten_chu_de, b.muc_do, COUNT(DISTINCT b.ma_code) AS so_de
FROM ChuDe c LEFT JOIN BaiTapChuDe bc USING (ma_chu_de) LEFT JOIN BaiTap b USING (ma_bai_tap)
GROUP BY c.ma_chu_de, c.ten_chu_de, b.muc_do ORDER BY c.ten_chu_de, b.muc_do;
