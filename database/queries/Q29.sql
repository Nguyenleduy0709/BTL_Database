-- Phiên bản mới nhất của mỗi bài tập
-- ROW_NUMBER · gom theo mã đề
WITH phien_ban_bai AS (
    SELECT ma_code, phien_ban, tieu_de, ROW_NUMBER() OVER (PARTITION BY ma_code ORDER BY phien_ban DESC) AS rn
    FROM BaiTap
)
SELECT ma_code, phien_ban, tieu_de FROM phien_ban_bai WHERE rn = 1 ORDER BY ma_code;
