USE btlcsdl;
SET NAMES utf8mb4;
DELIMITER $$

CREATE PROCEDURE sp_dang_ky_lop(IN p_lop INT, IN p_hv INT, OUT p_ma_dk INT)
BEGIN
    DECLARE v_max INT;
    DECLARE v_lop_tt VARCHAR(20);
    DECLARE v_dk_tt VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    SET p_ma_dk = NULL;
    START TRANSACTION;
    SELECT si_so_toi_da, trang_thai INTO v_max, v_lop_tt
    FROM LopHoc WHERE ma_lop = p_lop FOR UPDATE;
    IF v_max IS NULL OR v_lop_tt <> 'MO_DANG_KY' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lớp không mở đăng ký';
    END IF;
    SELECT ma_dang_ky, trang_thai INTO p_ma_dk, v_dk_tt
    FROM DangKyLop WHERE ma_lop = p_lop AND ma_hoc_vien = p_hv;
    IF v_dk_tt <> 'DA_HUY' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Học viên đã đăng ký lớp này';
    END IF;
    IF fn_si_so_hien_tai(p_lop) >= v_max THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lớp đã đủ sĩ số';
    END IF;
    IF p_ma_dk IS NULL THEN
        INSERT INTO DangKyLop(ma_lop, ma_hoc_vien) VALUES (p_lop, p_hv);
        SET p_ma_dk = LAST_INSERT_ID();
    ELSE
        UPDATE DangKyLop SET trang_thai = 'DANG_HOC', thoi_diem_dang_ky = NOW()
        WHERE ma_dang_ky = p_ma_dk;
    END IF;
    COMMIT;
END$$

CREATE PROCEDURE sp_huy_dang_ky(IN p_lop INT, IN p_hv INT)
BEGIN
    DECLARE v_lop INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT ma_lop INTO v_lop FROM LopHoc WHERE ma_lop = p_lop FOR UPDATE;
    UPDATE DangKyLop SET trang_thai = 'DA_HUY'
    WHERE ma_lop = v_lop AND ma_hoc_vien = p_hv AND trang_thai = 'DANG_HOC';
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không có đăng ký đang học để hủy';
    END IF;
    COMMIT;
END$$

CREATE PROCEDURE sp_phan_cong_giang_vien(IN p_lop INT, IN p_gv INT, IN p_vai_tro VARCHAR(20))
BEGIN
    DECLARE v_lop INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT ma_lop INTO v_lop FROM LopHoc WHERE ma_lop = p_lop FOR UPDATE;
    IF v_lop IS NULL OR NOT fn_co_vai_tro(p_gv, 'GIANG_VIEN') OR p_vai_tro NOT IN ('CHINH','TRO_GIANG') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lớp, giảng viên hoặc vai trò phân công không hợp lệ';
    END IF;
    IF p_vai_tro = 'CHINH' THEN
        UPDATE PhanCongGiangDay SET vai_tro_day = 'TRO_GIANG'
        WHERE ma_lop = p_lop AND la_chinh = 1 AND ma_giang_vien <> p_gv;
    ELSEIF EXISTS (SELECT 1 FROM PhanCongGiangDay WHERE ma_lop = p_lop AND ma_giang_vien = p_gv AND la_chinh = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy chọn giảng viên chính mới trước';
    END IF;
    INSERT INTO PhanCongGiangDay(ma_lop, ma_giang_vien, vai_tro_day) VALUES (p_lop, p_gv, p_vai_tro)
    ON DUPLICATE KEY UPDATE vai_tro_day = p_vai_tro;
    COMMIT;
END$$

CREATE PROCEDURE sp_giao_bai(
    IN p_lop INT, IN p_bai INT, IN p_bai_hoc INT, IN p_gv INT,
    IN p_han DATETIME, IN p_bat_buoc BOOLEAN, IN p_max INT, OUT p_giao INT
)
BEGIN
    INSERT INTO GiaoBai(ma_lop, ma_bai_tap, ma_bai_hoc, ma_nguoi_giao, han_nop, bat_buoc, so_lan_nop_toi_da)
    VALUES (p_lop, p_bai, p_bai_hoc, p_gv, p_han, p_bat_buoc, p_max);
    SET p_giao = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_nop_bai(
    IN p_giao INT, IN p_hv INT, IN p_ngon_ngu INT, IN p_code MEDIUMTEXT, OUT p_ma_lan_nop BIGINT
)
BEGIN
    INSERT INTO LanNop(ma_giao, ma_hoc_vien, ma_ngon_ngu, ma_nguon)
    VALUES (p_giao, p_hv, p_ngon_ngu, p_code);
    SET p_ma_lan_nop = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_ghi_ket_qua_cham(IN p_ma_lan_nop BIGINT, IN p_json JSON)
BEGIN
    DECLARE v_tt VARCHAR(20);
    DECLARE v_giao INT;
    DECLARE v_tong INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT trang_thai_cham, ma_giao INTO v_tt, v_giao
    FROM LanNop WHERE ma_lan_nop = p_ma_lan_nop FOR UPDATE;
    IF v_tt IS NULL OR v_tt <> 'CHO_CHAM' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lần nộp không chờ chấm';
    END IF;
    IF p_json IS NULL OR NOT JSON_SCHEMA_VALID('{
        "type":"array",
        "items":{
            "type":"object",
            "required":["ma_test","ma_loai"],
            "additionalProperties":false,
            "properties":{
                "ma_test":{"type":"integer","minimum":1,"maximum":2147483647},
                "ma_loai":{"type":"string","pattern":"^[A-Z]{2,3}$"},
                "thoi_gian_chay_ms":{"type":["integer","null"],"minimum":0,"maximum":2147483647},
                "bo_nho_kb":{"type":["integer","null"],"minimum":0,"maximum":2147483647},
                "dau_ra_thuc_te":{"type":["string","null"]}
            }
        }
    }', p_json) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Dữ liệu JSON của kết quả chấm không đúng định dạng';
    END IF;
    SELECT COUNT(*) INTO v_tong FROM GiaoBai g JOIN TestCase t USING (ma_bai_tap) WHERE g.ma_giao = v_giao;
    INSERT INTO KetQuaTest(ma_lan_nop, ma_test, ma_loai, thoi_gian_chay_ms, bo_nho_kb, dau_ra_thuc_te)
    SELECT p_ma_lan_nop, j.ma_test, j.ma_loai, j.ms, j.kb, j.dau_ra
    FROM JSON_TABLE(p_json, '$[*]' COLUMNS (
        ma_test INT PATH '$.ma_test' ERROR ON EMPTY ERROR ON ERROR,
        ma_loai VARCHAR(32) PATH '$.ma_loai' ERROR ON EMPTY ERROR ON ERROR,
        ms INT PATH '$.thoi_gian_chay_ms' NULL ON EMPTY ERROR ON ERROR,
        kb INT PATH '$.bo_nho_kb' NULL ON EMPTY ERROR ON ERROR,
        dau_ra TEXT PATH '$.dau_ra_thuc_te' NULL ON EMPTY ERROR ON ERROR
    )) AS j;
    IF v_tong = 0 OR ROW_COUNT() <> v_tong THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phải có đúng một kết quả cho từng test của bài';
    END IF;
    UPDATE LanNop SET trang_thai_cham = 'DA_CHAM', thoi_diem_cham = NOW(3)
    WHERE ma_lan_nop = p_ma_lan_nop;
    COMMIT;
END$$

CREATE PROCEDURE sp_loi_bien_dich(IN p_lan BIGINT)
BEGIN
    UPDATE LanNop SET trang_thai_cham = 'LOI_BIEN_DICH', thoi_diem_cham = NOW(3)
    WHERE ma_lan_nop = p_lan AND trang_thai_cham = 'CHO_CHAM';
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lần nộp không chờ chấm';
    END IF;
END$$

CREATE PROCEDURE sp_tao_phien_ban_bai_tap(IN p_bai_tap INT, OUT p_moi INT)
BEGIN
    DECLARE v_code VARCHAR(30);
    DECLARE v_phien_ban INT;
    DECLARE v_khoa INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    SELECT ma_code INTO v_code FROM BaiTap WHERE ma_bai_tap = p_bai_tap;
    IF v_code IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bài tập không tồn tại';
    END IF;
    START TRANSACTION;
    -- Khóa theo phiên bản 1 trước khi tính số phiên bản tiếp theo.
    SELECT ma_bai_tap INTO v_khoa FROM BaiTap WHERE ma_code = v_code AND phien_ban = 1 FOR UPDATE;
    SELECT ma_bai_tap INTO v_khoa FROM BaiTap WHERE ma_bai_tap = p_bai_tap FOR SHARE;
    SELECT MAX(phien_ban) + 1 INTO v_phien_ban FROM BaiTap WHERE ma_code = v_code;
    INSERT INTO BaiTap(ma_code, phien_ban, tieu_de, de_bai, muc_do, gioi_han_thoi_gian_ms, gioi_han_bo_nho_mb, ma_tac_gia)
    SELECT ma_code, v_phien_ban, tieu_de, de_bai, muc_do, gioi_han_thoi_gian_ms, gioi_han_bo_nho_mb, ma_tac_gia
    FROM BaiTap WHERE ma_bai_tap = p_bai_tap;
    SET p_moi = LAST_INSERT_ID();
    INSERT INTO BaiTapChuDe SELECT p_moi, ma_chu_de FROM BaiTapChuDe WHERE ma_bai_tap = p_bai_tap;
    INSERT INTO BaiTapNgonNgu SELECT p_moi, ma_ngon_ngu, ma_khung FROM BaiTapNgonNgu WHERE ma_bai_tap = p_bai_tap;
    INSERT INTO TestCase(ma_bai_tap, thu_tu, mo_ta, du_lieu_vao, ket_qua_mong_doi, trong_so, la_test_mau)
    SELECT p_moi, thu_tu, mo_ta, du_lieu_vao, ket_qua_mong_doi, trong_so, la_test_mau
    FROM TestCase WHERE ma_bai_tap = p_bai_tap;
    COMMIT;
END$$

CREATE PROCEDURE sp_cap_chung_chi(IN p_ma_dk INT)
BEGIN
    DECLARE v_dk INT;
    DECLARE v_tong INT;
    DECLARE v_dat INT;
    DECLARE v_buoi INT;
    DECLARE v_co_mat INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT ma_dang_ky INTO v_dk FROM DangKyLop WHERE ma_dang_ky = p_ma_dk AND trang_thai <> 'DA_HUY' FOR UPDATE;
    IF v_dk IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Đăng ký không hợp lệ'; END IF;
    SELECT tong_bat_buoc, so_da_dat INTO v_tong, v_dat FROM v_tien_do_thuc_hanh WHERE ma_dang_ky = v_dk;
    SELECT tong_buoi, co_mat INTO v_buoi, v_co_mat FROM v_chuyen_can WHERE ma_dang_ky = v_dk;
    IF v_tong = 0 OR v_dat <> v_tong OR v_buoi = 0 OR v_co_mat * 100 < v_buoi * 80 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cần hoàn thành toàn bộ bài bắt buộc và chuyên cần từ 80%';
    END IF;
    INSERT INTO ChungChi(ma_dang_ky, so_hieu, xep_loai)
    VALUES (v_dk, CONCAT('CL-', LPAD(v_dk, 10, '0')), IF(v_co_mat = v_buoi, 'XUAT_SAC', 'DAT'));
    COMMIT;
END$$

CREATE PROCEDURE sp_bao_cao_lop(IN p_lop INT)
READS SQL DATA
BEGIN
    SELECT * FROM v_lop_hoc WHERE ma_lop = p_lop;
    SELECT * FROM v_bang_xep_hang_lop WHERE ma_lop = p_lop ORDER BY xep_hang, ma_hoc_vien;
    SELECT s.ma_hoc_vien, n.ho_ten, g.tieu_de, g.han_nop
    FROM v_trang_thai_hoc_vien_bai_giao s JOIN v_giao_bai g USING (ma_giao)
    JOIN NguoiDung n ON n.ma_nguoi_dung = s.ma_hoc_vien
    WHERE s.ma_lop = p_lop AND s.trang_thai = 'CHUA_NOP' ORDER BY g.han_nop, n.ho_ten;
    SELECT l.ma_giao, g.tieu_de, l.thu_tu, l.mo_ta, l.so_nguoi_sai
    FROM v_loi_lan_gan_nhat l JOIN v_giao_bai g USING (ma_giao)
    WHERE g.ma_lop = p_lop ORDER BY l.so_nguoi_sai DESC, l.ma_giao, l.thu_tu;
END$$

CREATE PROCEDURE sp_tao_nguoi_dung(
    IN p_user VARCHAR(64), IN p_email VARCHAR(254), IN p_hash CHAR(60),
    IN p_ten VARCHAR(120), IN p_role TINYINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    INSERT INTO NguoiDung(ten_dang_nhap, email, mat_khau_hash, ho_ten) VALUES (p_user, p_email, p_hash, p_ten);
    INSERT INTO NguoiDungVaiTro(ma_nguoi_dung, ma_vai_tro) VALUES (LAST_INSERT_ID(), p_role);
    COMMIT;
END$$

CREATE PROCEDURE sp_tao_bai_tap(
    IN p_code VARCHAR(30), IN p_ten VARCHAR(160), IN p_de MEDIUMTEXT,
    IN p_do VARCHAR(20), IN p_tg INT, IN p_ngon_ngu INT, IN p_chu_de INT, OUT p_bai INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    INSERT INTO BaiTap(ma_code, tieu_de, de_bai, muc_do, ma_tac_gia) VALUES (p_code, p_ten, p_de, p_do, p_tg);
    SET p_bai = LAST_INSERT_ID();
    INSERT INTO BaiTapNgonNgu(ma_bai_tap, ma_ngon_ngu) VALUES (p_bai, p_ngon_ngu);
    IF p_chu_de IS NOT NULL THEN INSERT INTO BaiTapChuDe VALUES (p_bai, p_chu_de); END IF;
    COMMIT;
END$$

DELIMITER ;
