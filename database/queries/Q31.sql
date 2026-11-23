-- Các ngôn ngữ được phép theo đề
-- GROUP_CONCAT · LEFT JOIN
SELECT b.ma_code, b.phien_ban,
       GROUP_CONCAT(CONCAT(n.ten, ' ', n.phien_ban) ORDER BY n.ten SEPARATOR ', ') AS ngon_ngu
FROM BaiTap b LEFT JOIN BaiTapNgonNgu bn USING (ma_bai_tap) LEFT JOIN NgonNguLapTrinh n USING (ma_ngon_ngu)
GROUP BY b.ma_bai_tap, b.ma_code, b.phien_ban ORDER BY b.ma_code, b.phien_ban;
