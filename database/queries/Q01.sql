-- Cây danh mục khóa học
-- CTE đệ quy
WITH RECURSIVE cay AS (
    SELECT ma_danh_muc, ten_danh_muc, 0 AS cap, CAST(ten_danh_muc AS CHAR(500)) AS duong_dan
    FROM DanhMucKhoaHoc WHERE ma_danh_muc_cha IS NULL
    UNION ALL
    SELECT d.ma_danh_muc, d.ten_danh_muc, c.cap + 1, CONCAT(c.duong_dan, ' / ', d.ten_danh_muc)
    FROM DanhMucKhoaHoc d JOIN cay c ON c.ma_danh_muc = d.ma_danh_muc_cha
)
SELECT * FROM cay ORDER BY duong_dan;
