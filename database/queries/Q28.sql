-- Dòng thời gian học tập của An
-- UNION ALL
SELECT thoi_diem_nop AS thoi_diem, 'Nộp bài' AS hoat_dong,
       CAST(ma_giao AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_unicode_ci AS doi_tuong
FROM v_lan_nop_cong_khai WHERE ma_hoc_vien = 3
UNION ALL
SELECT t.thoi_diem_hoan_thanh, 'Học lý thuyết', b.tieu_de
FROM TienDoBaiHoc t JOIN DangKyLop d USING (ma_dang_ky) JOIN BaiHoc b USING (ma_bai_hoc)
WHERE d.ma_hoc_vien = 3
UNION ALL
SELECT b.bat_dau, 'Điểm danh', x.trang_thai
FROM DiemDanh x JOIN DangKyLop d USING (ma_dang_ky) JOIN BuoiHoc b USING (ma_buoi)
WHERE d.ma_hoc_vien = 3 ORDER BY thoi_diem DESC, hoat_dong;
