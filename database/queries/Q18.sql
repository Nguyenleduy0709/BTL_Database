-- Ma trận điểm theo phiên bản bài
-- Pivot · MAX CASE
SELECT n.ho_ten,
       MAX(CASE WHEN g.ma_bai = 'SECOND-MAX' AND g.phien_ban = 1 THEN s.diem_tot_nhat END) AS second_max_v1,
       MAX(CASE WHEN g.ma_bai = 'SECOND-MAX' AND g.phien_ban = 2 THEN s.diem_tot_nhat END) AS second_max_v2,
       MAX(CASE WHEN g.ma_bai = 'TONG-HAI-SO' THEN s.diem_tot_nhat END) AS tong_hai_so
FROM DangKyLop d JOIN NguoiDung n ON n.ma_nguoi_dung = d.ma_hoc_vien
LEFT JOIN v_trang_thai_hoc_vien_bai_giao s USING (ma_dang_ky) LEFT JOIN v_giao_bai g USING (ma_giao)
WHERE d.ma_lop = 1 AND d.trang_thai <> 'DA_HUY'
GROUP BY d.ma_hoc_vien, n.ho_ten ORDER BY d.ma_hoc_vien;
