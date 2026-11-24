USE btlcsdl;
SET NAMES utf8mb4;
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_test_btl_khang_dinh$$
CREATE PROCEDURE sp_test_btl_khang_dinh(IN p_dung BOOLEAN, IN p_noi_dung VARCHAR(128))
BEGIN
    IF NOT COALESCE(p_dung, FALSE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = p_noi_dung;
    END IF;
    SELECT p_noi_dung AS kiem_thu, 'PASS' AS ket_qua;
END$$

DROP PROCEDURE IF EXISTS sp_test_btl_nghiep_vu$$
CREATE PROCEDURE sp_test_btl_nghiep_vu()
BEGIN
    DECLARE v_lan BIGINT;
    DECLARE v_moi INT;
    DECLARE v_loi BOOLEAN DEFAULT FALSE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

    CALL sp_test_btl_khang_dinh((
        SELECT tong_luot = 3 AND da_thu = 2 AND dat = 1 AND chua_dat = 1 AND chua_nop = 1 AND cho_cham = 0
        FROM v_thong_ke_bai_giao WHERE ma_giao = 1
    ), 'PY01: thống kê 3 / 2 / 1 / 1 / 1');
    CALL sp_test_btl_khang_dinh((
        SELECT COUNT(*) = 3 AND SUM(
            (ma_hoc_vien = 3 AND diem_tot_nhat = 100)
            OR (ma_hoc_vien = 4 AND diem_tot_nhat = 80)
            OR (ma_hoc_vien = 5 AND diem_tot_nhat IS NULL AND trang_thai = 'CHUA_NOP')
        ) = 3 FROM v_trang_thai_hoc_vien_bai_giao WHERE ma_giao = 1
    ), 'Điểm tốt nhất An 100, Bình 80, Chi NULL');
    CALL sp_test_btl_khang_dinh((
        SELECT COUNT(*) = 5 AND SUM(so_nguoi_sai) = 1 AND SUM(thu_tu = 5 AND so_nguoi_sai = 1) = 1
        FROM v_loi_lan_gan_nhat WHERE ma_giao = 1
    ), 'Lỗi lượt gần nhất chỉ còn một người sai test 5');
    CALL sp_test_btl_khang_dinh(
        fn_si_so_hien_tai(1) = 3 AND fn_diem_lan_nop(1) = 60 AND fn_diem_lan_nop(2) = 100
        AND fn_hoc_vien_dat_bai(1, 3) AND NOT fn_hoc_vien_dat_bai(1, 4)
        AND fn_tien_do_thuc_hanh(1) = 100 AND fn_ty_le_chuyen_can(1) = 80,
        'Các function trả đúng sĩ số, điểm, tiến độ và chuyên cần');
    CALL sp_test_btl_khang_dinh((SELECT COUNT(*) = 29 FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
        AND LOWER(table_name) NOT IN ('maxacthucemail', 'hanmucxacthuc')),
        'Lược đồ có 28 bảng nghiệp vụ và một bảng nhật ký');
    CALL sp_test_btl_khang_dinh((SELECT COUNT(*) = 2 FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
        AND LOWER(table_name) IN ('maxacthucemail', 'hanmucxacthuc')),
        'Lược đồ có hai bảng hỗ trợ xác thực email');

    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        CALL sp_dang_ky_lop(2, 6, @trung);
    END;
    CALL sp_test_btl_khang_dinh(v_loi, 'Chặn đăng ký trùng của Dung vào PY02');

    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        CALL sp_nop_bai(2, 5, 1, 'print(1)', v_lan);
    END;
    CALL sp_test_btl_khang_dinh(v_loi, 'Chặn Chi nộp khi không thuộc PY02');

    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        CALL sp_nop_bai(1, 5, 2, 'int main() {}', v_lan);
    END;
    CALL sp_test_btl_khang_dinh(v_loi, 'Chặn ngôn ngữ không được phép');

    START TRANSACTION;
    UPDATE GiaoBai SET so_lan_nop_toi_da = 2 WHERE ma_giao = 1;
    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        CALL sp_nop_bai(1, 3, 1, 'print(1)', v_lan);
    END;
    CALL sp_test_btl_khang_dinh(v_loi, 'Chặn An khi đã dùng hết hai lượt nộp');
    ROLLBACK;

    START TRANSACTION;
    UPDATE GiaoBai SET han_nop = NOW() - INTERVAL 1 MINUTE WHERE ma_giao = 2;
    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        CALL sp_nop_bai(2, 6, 1, 'print(1)', v_lan);
    END;
    CALL sp_test_btl_khang_dinh(v_loi, 'Chặn Dung nộp sau hạn');
    ROLLBACK;

    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        UPDATE TestCase SET trong_so = 2 WHERE ma_test = 1;
    END;
    CALL sp_test_btl_khang_dinh(v_loi AND (SELECT trong_so = 1 FROM TestCase WHERE ma_test = 1), 'Khóa bộ test sau khi có bài nộp');

    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        UPDATE BaiTap SET de_bai = 'Đề sửa' WHERE ma_bai_tap = 1;
    END;
    CALL sp_test_btl_khang_dinh(v_loi, 'Khóa nội dung đề cũ sau khi có bài nộp');

    CALL sp_tao_phien_ban_bai_tap(1, v_moi);
    START TRANSACTION;
    CALL sp_test_btl_khang_dinh(
        (SELECT phien_ban > 1 AND ma_code = 'SECOND-MAX' FROM BaiTap WHERE ma_bai_tap = v_moi)
        AND (SELECT COUNT(*) = 5 FROM TestCase WHERE ma_bai_tap = v_moi)
        AND (SELECT COUNT(*) = 1 FROM BaiTapNgonNgu WHERE ma_bai_tap = v_moi)
        AND (SELECT COUNT(*) = 2 FROM BaiTapChuDe WHERE ma_bai_tap = v_moi),
        'Phiên bản mới sao chép đủ test, ngôn ngữ và chủ đề');
    DELETE FROM TestCase WHERE ma_bai_tap = v_moi;
    DELETE FROM BaiTapNgonNgu WHERE ma_bai_tap = v_moi;
    DELETE FROM BaiTapChuDe WHERE ma_bai_tap = v_moi;
    DELETE FROM BaiTap WHERE ma_bai_tap = v_moi;
    COMMIT;

    START TRANSACTION;
    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR 3819 SET v_loi = TRUE;
        UPDATE LopHoc SET hoc_phi = 1 WHERE ma_lop = 1;
    END;
    ROLLBACK;
    CALL sp_test_btl_khang_dinh(v_loi AND NOT EXISTS (SELECT 1 FROM LopHoc WHERE hoc_phi <> 0),
                            'Mọi lớp đều miễn phí, MySQL chặn mức học phí khác 0');

    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        CALL sp_cap_chung_chi(2);
    END;
    CALL sp_test_btl_khang_dinh(v_loi, 'Chưa đạt thực hành thì chưa cấp chứng chỉ');
    IF NOT EXISTS (SELECT 1 FROM ChungChi WHERE ma_dang_ky = 1) THEN
        CALL sp_cap_chung_chi(1);
        CALL sp_test_btl_khang_dinh((SELECT xep_loai = 'DAT' FROM ChungChi WHERE ma_dang_ky = 1),
                                'Đủ 100% thực hành và 80% chuyên cần thì cấp chứng chỉ');
        DELETE FROM ChungChi WHERE ma_dang_ky = 1;
    END IF;

    CALL sp_nop_bai(2, 6, 1, 'print("Bài nộp kiểm thử")', v_lan);
    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        CALL sp_ghi_ket_qua_cham(v_lan, '[{"ma_test":1,"ma_loai":"AC"},{"ma_test":6,"ma_loai":"WA"}]');
    END;
    CALL sp_test_btl_khang_dinh(v_loi AND NOT EXISTS (SELECT 1 FROM KetQuaTest WHERE ma_lan_nop = v_lan)
        AND (SELECT trang_thai_cham = 'CHO_CHAM' FROM LanNop WHERE ma_lan_nop = v_lan),
        'Test khác đề: cả lô kết quả bị hoàn tác');
    SET v_loi = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_loi = TRUE;
        CALL sp_ghi_ket_qua_cham(v_lan, '[{"ma_test":1,"ma_loai":"AC"}]');
    END;
    CALL sp_test_btl_khang_dinh(v_loi AND NOT EXISTS (SELECT 1 FROM KetQuaTest WHERE ma_lan_nop = v_lan)
        AND (SELECT trang_thai_cham = 'CHO_CHAM' FROM LanNop WHERE ma_lan_nop = v_lan),
        'Thiếu test: cả lô kết quả bị hoàn tác');
    CALL sp_ghi_ket_qua_cham(v_lan, '[{"ma_test":1,"ma_loai":"AC"},{"ma_test":2,"ma_loai":"AC"},
        {"ma_test":3,"ma_loai":"WA"},{"ma_test":4,"ma_loai":"AC"},{"ma_test":5,"ma_loai":"AC"}]');
    CALL sp_test_btl_khang_dinh((SELECT diem = 80 AND dat = 0 FROM v_diem_lan_nop WHERE ma_lan_nop = v_lan),
                            'Đủ test: chấm thành công, trả điểm 80%');
    START TRANSACTION;
    DELETE FROM KetQuaTest WHERE ma_lan_nop = v_lan;
    DELETE FROM LanNop WHERE ma_lan_nop = v_lan;
    COMMIT;

    IF EXISTS (SELECT 1 FROM LopHoc WHERE ma_code = 'PY-BENCH') THEN
        CALL sp_test_btl_khang_dinh((
            SELECT COUNT(DISTINCT ln.ma_hoc_vien) = 200 AND COUNT(DISTINCT ln.ma_lan_nop) = 10000
                   AND COUNT(q.ma_test) = 50000
            FROM v_giao_bai g JOIN LanNop ln USING (ma_giao) JOIN KetQuaTest q USING (ma_lan_nop)
            WHERE g.ma_lop_code = 'PY-BENCH'
        ), 'PY-BENCH: 200 học viên, 10.000 lượt, 50.000 kết quả');
    END IF;
END$$

DELIMITER ;

CALL sp_test_btl_nghiep_vu();
DROP PROCEDURE sp_test_btl_nghiep_vu;
DROP PROCEDURE sp_test_btl_khang_dinh;
