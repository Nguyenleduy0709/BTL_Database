USE btlcsdl;
SET NAMES utf8mb4;

-- Giữ bảng và dữ liệu giao dịch cũ để lưu trữ.
DROP PROCEDURE IF EXISTS sp_thanh_toan;
DROP VIEW IF EXISTS v_cong_no_hoc_phi;
DROP TRIGGER IF EXISTS trg_thanhtoan_bi;
DROP TRIGGER IF EXISTS trg_thanhtoan_bu;
DROP TRIGGER IF EXISTS trg_audit_thanhtoan_i;
DROP TRIGGER IF EXISTS trg_audit_thanhtoan_u;
DROP TRIGGER IF EXISTS trg_audit_thanhtoan_d;
DROP PROCEDURE IF EXISTS sp_kiem_tra_thanh_toan;

CREATE OR REPLACE VIEW v_tong_quan AS
SELECT (SELECT COUNT(*) FROM LopHoc WHERE trang_thai IN ('DANG_HOC', 'MO_DANG_KY')) AS so_lop,
       (SELECT COUNT(DISTINCT ma_hoc_vien) FROM DangKyLop WHERE trang_thai <> 'DA_HUY') AS so_hoc_vien,
       (SELECT COUNT(*) FROM LanNop) AS so_lan_nop,
       (SELECT COUNT(*) FROM LanNop WHERE trang_thai_cham = 'CHO_CHAM') AS cho_cham;

DROP PROCEDURE IF EXISTS sp_tao_lop;
DROP PROCEDURE IF EXISTS sp_sua_lop;
DELIMITER $$

CREATE PROCEDURE sp_tao_lop(
    IN p_code VARCHAR(20), IN p_khoa INT, IN p_bat_dau DATE, IN p_ket_thuc DATE,
    IN p_max INT, IN p_gv INT, OUT p_lop INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    INSERT INTO LopHoc(ma_code, ma_khoa_hoc, ngay_bat_dau, ngay_ket_thuc, si_so_toi_da)
    VALUES (p_code, p_khoa, p_bat_dau, p_ket_thuc, p_max);
    SET p_lop = LAST_INSERT_ID();
    INSERT INTO PhanCongGiangDay(ma_lop, ma_giang_vien, vai_tro_day) VALUES (p_lop, p_gv, 'CHINH');
    COMMIT;
END$$

CREATE PROCEDURE sp_sua_lop(
    IN p_lop INT, IN p_code VARCHAR(20), IN p_bat_dau DATE, IN p_ket_thuc DATE,
    IN p_max INT, IN p_tt VARCHAR(20)
)
BEGIN
    DECLARE v_lop INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT ma_lop INTO v_lop FROM LopHoc WHERE ma_lop = p_lop FOR UPDATE;
    IF v_lop IS NULL OR p_max < fn_si_so_hien_tai(v_lop) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lớp không tồn tại hoặc sĩ số mới thấp hơn số đã đăng ký';
    END IF;
    UPDATE LopHoc SET ma_code = p_code, ngay_bat_dau = p_bat_dau, ngay_ket_thuc = p_ket_thuc,
        si_so_toi_da = p_max, trang_thai = p_tt WHERE ma_lop = p_lop;
    COMMIT;
END$$

DELIMITER ;

GRANT SELECT ON btlcsdl.v_tong_quan TO btl_web, btl_readonly;
GRANT EXECUTE ON PROCEDURE btlcsdl.sp_tao_lop TO btl_web;
GRANT EXECUTE ON PROCEDURE btlcsdl.sp_sua_lop TO btl_web;

UPDATE LopHoc SET hoc_phi = 0 WHERE hoc_phi <> 0;

-- Dùng tên CHECK để nhận biết bản cài đã nâng cấp. Nạp lại được khi cần.
SET @kiem_tra_mien_phi = IF(EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'LopHoc'
      AND CONSTRAINT_NAME = 'ck_lophoc_mien_phi' AND CONSTRAINT_TYPE = 'CHECK'
), 'DO 0', 'ALTER TABLE LopHoc ADD CONSTRAINT ck_lophoc_mien_phi CHECK (hoc_phi = 0)');
PREPARE mien_phi_stmt FROM @kiem_tra_mien_phi;
EXECUTE mien_phi_stmt;
DEALLOCATE PREPARE mien_phi_stmt;
SET @kiem_tra_mien_phi = NULL;
