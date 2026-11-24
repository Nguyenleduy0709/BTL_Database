USE btlcsdl;
SET NAMES utf8mb4;
DELIMITER $$

-- Dữ liệu minh họa chỉ nằm ở lớp PY-BENCH. Chạy khi khởi tạo để có dữ liệu EXPLAIN.
CREATE PROCEDURE sp_sinh_du_lieu_mau(IN p_hv INT, IN p_lan_moi_hoc_vien INT)
BEGIN
    DECLARE v_lop INT;
    DECLARE v_giao INT;
    DECLARE v_phan_hoi INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    IF p_hv IS NULL OR p_hv NOT BETWEEN 1 AND 1000 OR
       p_lan_moi_hoc_vien IS NULL OR p_lan_moi_hoc_vien NOT BETWEEN 1 AND 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Số học viên từ 1 đến 1000, số lượt mỗi người từ 1 đến 100';
    END IF;
    START TRANSACTION;
    INSERT INTO LopHoc(ma_code, ma_khoa_hoc, ngay_bat_dau, ngay_ket_thuc, si_so_toi_da, trang_thai)
    VALUES ('PY-BENCH', 1, CURRENT_DATE-INTERVAL 60 DAY, CURRENT_DATE+INTERVAL 30 DAY, p_hv, 'DANG_HOC');
    SET v_lop = LAST_INSERT_ID();
    INSERT INTO PhanCongGiangDay(ma_lop, ma_giang_vien, vai_tro_day) VALUES (v_lop, 2, 'CHINH');

    INSERT INTO NguoiDung(ten_dang_nhap, email, mat_khau_hash, ho_ten)
    WITH RECURSIVE so(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM so WHERE n < p_hv)
    SELECT CONCAT('bench', LPAD(n,4,'0')), CONCAT('bench', n, '@codelab.example'),
           'TAI-KHOAN-SINH-TU-DONG', CONCAT('Học viên mẫu ', LPAD(n,4,'0'))
    FROM so;
    INSERT INTO NguoiDungVaiTro(ma_nguoi_dung, ma_vai_tro)
    SELECT ma_nguoi_dung, 3 FROM NguoiDung WHERE ten_dang_nhap REGEXP '^bench[0-9]{4}$';

    INSERT INTO DangKyLop(ma_lop, ma_hoc_vien, thoi_diem_dang_ky)
    SELECT v_lop, ma_nguoi_dung, NOW()-INTERVAL 55 DAY
    FROM NguoiDung WHERE ten_dang_nhap REGEXP '^bench[0-9]{4}$';

    INSERT INTO GiaoBai(ma_lop, ma_bai_tap, ma_bai_hoc, ma_nguoi_giao, thoi_diem_giao, han_nop)
    VALUES (v_lop, 1, 3, 2, NOW()-INTERVAL 50 DAY, NOW()+INTERVAL 25 DAY);
    SET v_giao = LAST_INSERT_ID();

    INSERT INTO LanNop(ma_giao, ma_hoc_vien, ma_ngon_ngu, ma_nguon, thoi_diem_nop)
    WITH RECURSIVE luot(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM luot WHERE n < p_lan_moi_hoc_vien)
    SELECT v_giao, dk.ma_hoc_vien, 1, '# Dữ liệu kiểm thử hiệu năng',
           NOW(3)-INTERVAL 30 DAY+INTERVAL MOD(dk.ma_hoc_vien * 13 + luot.n * 7, 28800) MINUTE
    FROM DangKyLop dk CROSS JOIN luot WHERE dk.ma_lop = v_lop;

    INSERT INTO KetQuaTest(ma_lan_nop, ma_test, ma_loai, thoi_gian_chay_ms, bo_nho_kb)
    SELECT ln.ma_lan_nop, t.ma_test,
           IF(MOD(CRC32(CONCAT_WS('-', ln.ma_lan_nop, t.ma_test)), 13) < t.thu_tu, 'WA', 'AC'),
           5 + MOD(ln.ma_lan_nop * t.ma_test, 250), 2048 + MOD(ln.ma_lan_nop, 4096)
    FROM LanNop ln JOIN TestCase t ON t.ma_bai_tap = 1 WHERE ln.ma_giao = v_giao;

    UPDATE LanNop SET trang_thai_cham = 'DA_CHAM', thoi_diem_cham = thoi_diem_nop + INTERVAL 1 MINUTE
    WHERE ma_giao = v_giao;
    UPDATE NguoiDung SET trang_thai = 'KHOA' WHERE ten_dang_nhap REGEXP '^bench[0-9]{4}$';
    COMMIT;
END$$

DELIMITER ;
CALL sp_sinh_du_lieu_mau(200, 50);
