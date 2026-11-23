USE btlcsdl;
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS MaXacThucEmail (
    ma_yeu_cau CHAR(32) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
    muc_dich ENUM('DANG_KY', 'QUEN_MAT_KHAU') NOT NULL,
    email VARCHAR(254) NOT NULL,
    ma_nguoi_dung INT,
    dau_mat_khau CHAR(64) CHARACTER SET ascii COLLATE ascii_bin,
    ma_bam CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    het_han DATETIME(6) NOT NULL,
    so_lan_sai TINYINT UNSIGNED NOT NULL DEFAULT 0,
    UNIQUE (muc_dich, email),
    KEY ix_otp_het_han (het_han),
    FOREIGN KEY (ma_nguoi_dung) REFERENCES NguoiDung(ma_nguoi_dung) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS HanMucXacThuc (
    khoa CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
    het_han DATETIME(6) NOT NULL,
    so_lan SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    KEY ix_hanmuc_het_han (het_han)
) ENGINE=InnoDB;

-- View Django gọi procedure này bên trong giao dịch đã khóa OTP.
-- Procedure không mở giao dịch mới để tránh commit trước khi dùng mã.
DROP PROCEDURE IF EXISTS sp_dang_ky_hoc_vien_xac_thuc;
DELIMITER $$
CREATE PROCEDURE sp_dang_ky_hoc_vien_xac_thuc(
    IN p_user VARCHAR(64), IN p_email VARCHAR(254), IN p_hash CHAR(60), IN p_ten VARCHAR(120)
)
BEGIN
    INSERT INTO NguoiDung(ten_dang_nhap, email, mat_khau_hash, ho_ten)
    VALUES (p_user, p_email, p_hash, p_ten);
    INSERT INTO NguoiDungVaiTro(ma_nguoi_dung, ma_vai_tro)
    SELECT LAST_INSERT_ID(), ma_vai_tro FROM VaiTro WHERE ten_vai_tro = 'HOC_VIEN';
    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chưa cấu hình vai trò học viên';
    END IF;
END$$
DELIMITER ;

GRANT SELECT, INSERT, UPDATE, DELETE ON btlcsdl.MaXacThucEmail TO btl_web;
GRANT SELECT, INSERT, UPDATE, DELETE ON btlcsdl.HanMucXacThuc TO btl_web;
GRANT UPDATE (mat_khau_hash) ON btlcsdl.NguoiDung TO btl_web;
GRANT EXECUTE ON PROCEDURE btlcsdl.sp_dang_ky_hoc_vien_xac_thuc TO btl_web;
