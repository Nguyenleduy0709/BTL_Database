USE btlcsdl;
SET NAMES utf8mb4;
DELIMITER $$

CREATE FUNCTION fn_co_vai_tro(p_nguoi INT, p_vai_tro VARCHAR(30))
RETURNS BOOLEAN READS SQL DATA
RETURN EXISTS (
    SELECT 1 FROM NguoiDung n
    JOIN NguoiDungVaiTro nv USING (ma_nguoi_dung)
    JOIN VaiTro v USING (ma_vai_tro)
    WHERE n.ma_nguoi_dung = p_nguoi AND n.trang_thai = 'HOAT_DONG'
      AND v.ten_vai_tro = p_vai_tro
)$$

CREATE FUNCTION fn_si_so_hien_tai(p_lop INT)
RETURNS INT READS SQL DATA
RETURN (SELECT COUNT(*) FROM DangKyLop WHERE ma_lop = p_lop AND trang_thai <> 'DA_HUY')$$

CREATE FUNCTION fn_diem_lan_nop(p_lan BIGINT)
RETURNS DECIMAL(5,2) READS SQL DATA
RETURN (SELECT diem FROM v_diem_lan_nop WHERE ma_lan_nop = p_lan)$$

CREATE FUNCTION fn_hoc_vien_dat_bai(p_giao INT, p_hv INT)
RETURNS BOOLEAN READS SQL DATA
RETURN EXISTS (SELECT 1 FROM v_diem_lan_nop WHERE ma_giao = p_giao AND ma_hoc_vien = p_hv AND dat)$$

CREATE FUNCTION fn_tien_do_thuc_hanh(p_dk INT)
RETURNS DECIMAL(5,2) READS SQL DATA
RETURN (SELECT tien_do FROM v_tien_do_thuc_hanh WHERE ma_dang_ky = p_dk)$$

CREATE FUNCTION fn_ty_le_chuyen_can(p_dk INT)
RETURNS DECIMAL(5,2) READS SQL DATA
RETURN (SELECT ty_le FROM v_chuyen_can WHERE ma_dang_ky = p_dk)$$

DELIMITER ;
