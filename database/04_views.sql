USE btlcsdl;

CREATE VIEW v_diem_lan_nop AS
SELECT ln.ma_lan_nop, ln.ma_giao, ln.ma_hoc_vien, ln.thoi_diem_nop, ln.thoi_diem_cham,
       COUNT(t.ma_test) AS tong_test,
       SUM(COALESCE(k.la_dung, 0)) AS so_test_dung,
       ROUND(100 * SUM(COALESCE(k.la_dung, 0) * t.trong_so) / SUM(t.trong_so), 2) AS diem,
       COUNT(t.ma_test) = SUM(COALESCE(k.la_dung, 0)) AS dat
FROM LanNop ln
JOIN GiaoBai g USING (ma_giao)
JOIN TestCase t ON t.ma_bai_tap = g.ma_bai_tap
LEFT JOIN KetQuaTest q ON q.ma_lan_nop = ln.ma_lan_nop AND q.ma_test = t.ma_test
LEFT JOIN LoaiKetQua k ON k.ma_loai = q.ma_loai AND ln.trang_thai_cham = 'DA_CHAM'
WHERE ln.trang_thai_cham IN ('DA_CHAM', 'LOI_BIEN_DICH')
GROUP BY ln.ma_lan_nop, ln.ma_giao, ln.ma_hoc_vien, ln.thoi_diem_nop, ln.thoi_diem_cham;

CREATE VIEW v_trang_thai_hoc_vien_bai_giao AS
SELECT dk.ma_dang_ky, g.ma_giao, g.ma_lop, dk.ma_hoc_vien,
       COUNT(ln.ma_lan_nop) AS so_lan_nop,
       COUNT(d.ma_lan_nop) AS so_lan_da_cham,
       MAX(d.diem) AS diem_tot_nhat,
       CASE WHEN COUNT(ln.ma_lan_nop) = 0 THEN 'CHUA_NOP'
            WHEN MAX(d.dat) = 1 THEN 'DAT'
            WHEN COUNT(d.ma_lan_nop) = 0 THEN 'CHO_CHAM'
            ELSE 'CHUA_DAT' END AS trang_thai
FROM DangKyLop dk
JOIN GiaoBai g ON g.ma_lop = dk.ma_lop
LEFT JOIN LanNop ln ON ln.ma_giao = g.ma_giao AND ln.ma_hoc_vien = dk.ma_hoc_vien
LEFT JOIN v_diem_lan_nop d ON d.ma_lan_nop = ln.ma_lan_nop
WHERE dk.trang_thai <> 'DA_HUY'
GROUP BY dk.ma_dang_ky, g.ma_giao, g.ma_lop, dk.ma_hoc_vien;

CREATE VIEW v_thong_ke_bai_giao AS
SELECT g.ma_giao, g.ma_lop, COUNT(s.ma_hoc_vien) AS si_so,
       COALESCE(SUM(s.so_lan_nop), 0) AS tong_luot,
       COALESCE(SUM(s.so_lan_da_cham), 0) AS da_cham,
       COALESCE(SUM(s.so_lan_nop > 0), 0) AS da_thu,
       COALESCE(SUM(s.trang_thai = 'DAT'), 0) AS dat,
       COALESCE(SUM(s.trang_thai = 'CHUA_DAT'), 0) AS chua_dat,
       COALESCE(SUM(s.trang_thai = 'CHUA_NOP'), 0) AS chua_nop,
       COALESCE(SUM(s.trang_thai = 'CHO_CHAM'), 0) AS cho_cham
FROM GiaoBai g LEFT JOIN v_trang_thai_hoc_vien_bai_giao s USING (ma_giao)
GROUP BY g.ma_giao, g.ma_lop;

CREATE VIEW v_loi_lan_gan_nhat AS
WITH gan_nhat AS (
    SELECT ln.ma_lan_nop, ln.ma_giao, ln.trang_thai_cham,
           ROW_NUMBER() OVER (
               PARTITION BY ln.ma_giao, ln.ma_hoc_vien
               ORDER BY ln.thoi_diem_cham DESC, ln.ma_lan_nop DESC
           ) AS rn
    FROM LanNop ln
    JOIN GiaoBai g USING (ma_giao)
    JOIN DangKyLop dk ON dk.ma_lop = g.ma_lop AND dk.ma_hoc_vien = ln.ma_hoc_vien
    WHERE ln.trang_thai_cham IN ('DA_CHAM', 'LOI_BIEN_DICH') AND dk.trang_thai <> 'DA_HUY'
)
SELECT g.ma_giao, t.ma_test, t.thu_tu, t.mo_ta,
       COUNT(k.ma_loai) AS so_nguoi_co_ket_qua,
       COALESCE(SUM(k.la_dung = 0), 0) AS so_nguoi_sai
FROM GiaoBai g
JOIN TestCase t ON t.ma_bai_tap = g.ma_bai_tap
LEFT JOIN gan_nhat n ON n.ma_giao = g.ma_giao AND n.rn = 1 AND n.trang_thai_cham = 'DA_CHAM'
LEFT JOIN KetQuaTest q ON q.ma_lan_nop = n.ma_lan_nop AND q.ma_test = t.ma_test
LEFT JOIN LoaiKetQua k USING (ma_loai)
GROUP BY g.ma_giao, t.ma_test, t.thu_tu, t.mo_ta;

CREATE VIEW v_tien_do_thuc_hanh AS
SELECT dk.ma_dang_ky, dk.ma_lop, dk.ma_hoc_vien,
       COUNT(g.ma_giao) AS tong_bat_buoc,
       COALESCE(SUM(s.trang_thai = 'DAT'), 0) AS so_da_dat,
       ROUND(100 * SUM(s.trang_thai = 'DAT') / NULLIF(COUNT(g.ma_giao), 0), 2) AS tien_do
FROM DangKyLop dk
LEFT JOIN GiaoBai g ON g.ma_lop = dk.ma_lop AND g.bat_buoc AND g.thoi_diem_giao <= NOW()
LEFT JOIN v_trang_thai_hoc_vien_bai_giao s ON s.ma_giao = g.ma_giao AND s.ma_dang_ky = dk.ma_dang_ky
WHERE dk.trang_thai <> 'DA_HUY'
GROUP BY dk.ma_dang_ky, dk.ma_lop, dk.ma_hoc_vien;

CREATE VIEW v_tien_do_ly_thuyet AS
SELECT dk.ma_dang_ky, dk.ma_lop, dk.ma_hoc_vien, COUNT(b.ma_bai_hoc) AS tong_bai,
       COUNT(t.ma_bai_hoc) AS da_hoc,
       ROUND(100 * COUNT(t.ma_bai_hoc) / NULLIF(COUNT(b.ma_bai_hoc), 0), 2) AS tien_do
FROM DangKyLop dk
JOIN LopHoc l USING (ma_lop)
LEFT JOIN Chuong c ON c.ma_khoa_hoc = l.ma_khoa_hoc
LEFT JOIN BaiHoc b USING (ma_chuong)
LEFT JOIN TienDoBaiHoc t ON t.ma_bai_hoc = b.ma_bai_hoc AND t.ma_dang_ky = dk.ma_dang_ky
WHERE dk.trang_thai <> 'DA_HUY'
GROUP BY dk.ma_dang_ky, dk.ma_lop, dk.ma_hoc_vien;

CREATE VIEW v_bang_xep_hang_lop AS
SELECT p.*, n.ho_ten,
       DENSE_RANK() OVER (PARTITION BY p.ma_lop ORDER BY p.so_da_dat DESC, AVG(s.diem_tot_nhat) DESC) AS xep_hang,
       ROUND(AVG(s.diem_tot_nhat), 2) AS diem_trung_binh
FROM v_tien_do_thuc_hanh p JOIN NguoiDung n ON n.ma_nguoi_dung = p.ma_hoc_vien
LEFT JOIN v_trang_thai_hoc_vien_bai_giao s USING (ma_dang_ky)
GROUP BY p.ma_dang_ky, p.ma_lop, p.ma_hoc_vien, p.tong_bat_buoc, p.so_da_dat, p.tien_do, n.ho_ten;

CREATE VIEW v_cong_no_hoc_phi AS
SELECT dk.ma_dang_ky, dk.ma_lop, dk.ma_hoc_vien, n.ho_ten, l.ma_code, l.hoc_phi,
       COALESCE(SUM(t.so_tien), 0) AS da_thanh_toan,
       l.hoc_phi - COALESCE(SUM(t.so_tien), 0) AS con_no
FROM DangKyLop dk
JOIN LopHoc l USING (ma_lop)
JOIN NguoiDung n ON n.ma_nguoi_dung = dk.ma_hoc_vien
LEFT JOIN ThanhToan t ON t.ma_dang_ky = dk.ma_dang_ky AND t.trang_thai = 'THANH_CONG'
WHERE dk.trang_thai <> 'DA_HUY'
GROUP BY dk.ma_dang_ky, dk.ma_lop, dk.ma_hoc_vien, n.ho_ten, l.ma_code, l.hoc_phi;

CREATE VIEW v_chuyen_can AS
SELECT dk.ma_dang_ky, dk.ma_lop, dk.ma_hoc_vien,
       COUNT(b.ma_buoi) AS tong_buoi,
       COALESCE(SUM(d.trang_thai IN ('CO_MAT', 'MUON')), 0) AS co_mat,
       ROUND(100 * COALESCE(SUM(d.trang_thai IN ('CO_MAT', 'MUON')), 0)
             / NULLIF(COUNT(b.ma_buoi), 0), 2) AS ty_le
FROM DangKyLop dk
LEFT JOIN BuoiHoc b ON b.ma_lop = dk.ma_lop AND b.ket_thuc <= NOW()
LEFT JOIN DiemDanh d ON d.ma_buoi = b.ma_buoi AND d.ma_dang_ky = dk.ma_dang_ky
WHERE dk.trang_thai <> 'DA_HUY'
GROUP BY dk.ma_dang_ky, dk.ma_lop, dk.ma_hoc_vien;

CREATE VIEW v_lop_hoc AS
SELECT l.*, k.ten_khoa_hoc, n.ho_ten AS giang_vien_chinh,
       (SELECT COUNT(*) FROM DangKyLop dk WHERE dk.ma_lop = l.ma_lop AND dk.trang_thai <> 'DA_HUY') AS si_so_hien_tai
FROM LopHoc l JOIN KhoaHoc k USING (ma_khoa_hoc)
LEFT JOIN PhanCongGiangDay p ON p.ma_lop = l.ma_lop AND p.la_chinh = 1
LEFT JOIN NguoiDung n ON n.ma_nguoi_dung = p.ma_giang_vien;

CREATE VIEW v_giao_bai AS
SELECT g.*, b.ma_code AS ma_bai, b.tieu_de, b.phien_ban, l.ma_code AS ma_lop_code
FROM GiaoBai g JOIN BaiTap b USING (ma_bai_tap) JOIN LopHoc l USING (ma_lop);

CREATE VIEW v_lan_nop_cong_khai AS
SELECT ma_lan_nop, ma_giao, ma_hoc_vien, ma_ngon_ngu, thoi_diem_nop, trang_thai_cham, thoi_diem_cham
FROM LanNop;

CREATE VIEW v_tong_quan AS
SELECT (SELECT COUNT(*) FROM LopHoc WHERE trang_thai IN ('DANG_HOC', 'MO_DANG_KY')) AS so_lop,
       (SELECT COUNT(DISTINCT ma_hoc_vien) FROM DangKyLop WHERE trang_thai <> 'DA_HUY') AS so_hoc_vien,
       (SELECT COUNT(*) FROM LanNop) AS so_lan_nop,
       (SELECT COALESCE(SUM(so_tien),0) FROM ThanhToan WHERE trang_thai = 'THANH_CONG') AS doanh_thu;
