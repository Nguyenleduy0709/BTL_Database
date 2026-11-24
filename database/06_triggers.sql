USE btlcsdl;
SET NAMES utf8mb4;
DELIMITER $$

CREATE PROCEDURE sp_kiem_tra_bai_hoc(IN p_lop INT, IN p_bai INT)
READS SQL DATA
BEGIN
    IF p_bai IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM LopHoc l JOIN Chuong c USING (ma_khoa_hoc) JOIN BaiHoc b USING (ma_chuong)
        WHERE l.ma_lop = p_lop AND b.ma_bai_hoc = p_bai
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bài học không thuộc khóa học của lớp';
    END IF;
END$$

CREATE TRIGGER trg_dangky_bi BEFORE INSERT ON DangKyLop FOR EACH ROW
BEGIN
    IF NOT fn_co_vai_tro(NEW.ma_hoc_vien, 'HOC_VIEN') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Người đăng ký phải là học viên đang hoạt động';
    END IF;
END$$

CREATE TRIGGER trg_dangky_bu BEFORE UPDATE ON DangKyLop FOR EACH ROW
BEGIN
    IF NEW.ma_lop <> OLD.ma_lop OR NEW.ma_hoc_vien <> OLD.ma_hoc_vien THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không được thay đổi lớp hoặc học viên của đăng ký';
    END IF;
    IF OLD.trang_thai = 'DA_HUY' AND NEW.trang_thai = 'DANG_HOC'
       AND NOT fn_co_vai_tro(NEW.ma_hoc_vien, 'HOC_VIEN') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Người đăng ký phải là học viên đang hoạt động';
    END IF;
END$$

CREATE PROCEDURE sp_kiem_tra_bo_test(IN p_bai INT)
READS SQL DATA
BEGIN
    DECLARE v_bai INT;
    DECLARE v_da_nop BIGINT;
    SELECT ma_bai_tap INTO v_bai FROM BaiTap WHERE ma_bai_tap = p_bai FOR UPDATE;
    SELECT ln.ma_lan_nop INTO v_da_nop
    FROM GiaoBai g JOIN LanNop ln USING (ma_giao)
    WHERE g.ma_bai_tap = p_bai LIMIT 1 FOR SHARE OF ln;
    IF v_da_nop IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bộ test đã được dùng. Hãy tạo phiên bản mới';
    END IF;
END$$

CREATE TRIGGER trg_testcase_bi BEFORE INSERT ON TestCase FOR EACH ROW
CALL sp_kiem_tra_bo_test(NEW.ma_bai_tap)$$

CREATE TRIGGER trg_testcase_bu BEFORE UPDATE ON TestCase FOR EACH ROW
BEGIN
    IF NEW.ma_bai_tap <> OLD.ma_bai_tap THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không được chuyển test sang phiên bản bài khác';
    END IF;
    CALL sp_kiem_tra_bo_test(OLD.ma_bai_tap);
END$$

CREATE TRIGGER trg_testcase_bd BEFORE DELETE ON TestCase FOR EACH ROW
CALL sp_kiem_tra_bo_test(OLD.ma_bai_tap)$$

CREATE TRIGGER trg_baitap_bu BEFORE UPDATE ON BaiTap FOR EACH ROW
BEGIN
    DECLARE v_lan BIGINT;
    IF NEW.ma_code <> OLD.ma_code OR NEW.phien_ban <> OLD.phien_ban THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không được đổi mã hoặc số phiên bản của bài tập';
    END IF;
    SELECT ln.ma_lan_nop INTO v_lan FROM GiaoBai g JOIN LanNop ln USING (ma_giao)
    WHERE g.ma_bai_tap = OLD.ma_bai_tap LIMIT 1 FOR SHARE OF ln;
    IF v_lan IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Đề đã có lượt nộp. Hãy tạo phiên bản mới';
    END IF;
END$$

CREATE TRIGGER trg_giaobai_bi BEFORE INSERT ON GiaoBai FOR EACH ROW
BEGIN
    DECLARE v_bai INT;
    DECLARE v_test INT;
    SELECT ma_bai_tap INTO v_bai FROM BaiTap WHERE ma_bai_tap = NEW.ma_bai_tap FOR SHARE;
    SELECT ma_test INTO v_test FROM TestCase WHERE ma_bai_tap = v_bai LIMIT 1 FOR SHARE;
    IF v_test IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bài tập chưa có bộ test'; END IF;
    CALL sp_kiem_tra_bai_hoc(NEW.ma_lop, NEW.ma_bai_hoc);
END$$

CREATE TRIGGER trg_giaobai_bu BEFORE UPDATE ON GiaoBai FOR EACH ROW
BEGIN
    IF NEW.ma_lop <> OLD.ma_lop OR NEW.ma_bai_tap <> OLD.ma_bai_tap THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Muốn đổi lớp hoặc phiên bản bài, hãy tạo đợt giao mới';
    END IF;
    CALL sp_kiem_tra_bai_hoc(NEW.ma_lop, NEW.ma_bai_hoc);
END$$

CREATE TRIGGER trg_lannop_bi BEFORE INSERT ON LanNop FOR EACH ROW
BEGIN
    DECLARE v_lop INT;
    DECLARE v_bai INT;
    DECLARE v_khoa INT;
    DECLARE v_bai_test INT;
    DECLARE v_max INT;
    DECLARE v_giao DATETIME;
    DECLARE v_han DATETIME;
    DECLARE v_dk_tt VARCHAR(20);
    DECLARE v_lop_tt VARCHAR(20);
    -- Khóa bài giao để các lượt nộp đồng thời cùng dùng một giới hạn.
    SELECT ma_lop, ma_bai_tap, so_lan_nop_toi_da, thoi_diem_giao, han_nop
    INTO v_lop, v_bai, v_max, v_giao, v_han FROM GiaoBai WHERE ma_giao = NEW.ma_giao FOR UPDATE;
    SELECT trang_thai INTO v_lop_tt FROM LopHoc WHERE ma_lop = v_lop FOR SHARE;
    SELECT trang_thai INTO v_dk_tt FROM DangKyLop
    WHERE ma_lop = v_lop AND ma_hoc_vien = NEW.ma_hoc_vien FOR SHARE;
    IF v_dk_tt IS NULL OR v_dk_tt <> 'DANG_HOC' OR NOT fn_co_vai_tro(NEW.ma_hoc_vien, 'HOC_VIEN') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ học viên đang học trong lớp mới được nộp bài';
    END IF;
    IF v_lop_tt NOT IN ('MO_DANG_KY', 'DANG_HOC') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lớp đã đóng';
    END IF;
    IF NEW.thoi_diem_nop < v_giao OR NEW.thoi_diem_nop > NOW(3) OR NOW(3) < v_giao OR NOW(3) >= v_han THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bài giao chưa mở hoặc đã hết hạn';
    END IF;
    SELECT ma_bai_tap INTO v_khoa FROM BaiTap WHERE ma_bai_tap = v_bai FOR SHARE;
    SELECT ma_test INTO v_bai_test FROM TestCase WHERE ma_bai_tap = v_bai LIMIT 1 FOR SHARE;
    IF v_bai_test IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bài tập chưa có bộ test'; END IF;
    IF NOT EXISTS (SELECT 1 FROM BaiTapNgonNgu WHERE ma_bai_tap = v_bai AND ma_ngon_ngu = NEW.ma_ngon_ngu) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngôn ngữ không được phép cho bài này';
    END IF;
    IF v_max IS NOT NULL AND (SELECT COUNT(*) FROM LanNop
                               WHERE ma_giao = NEW.ma_giao AND ma_hoc_vien = NEW.ma_hoc_vien) >= v_max THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Đã hết số lần nộp';
    END IF;
    IF NEW.trang_thai_cham <> 'CHO_CHAM' OR NOT REGEXP_LIKE(NEW.ma_nguon, '[^[:space:]]') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lần nộp mới cần có mã nguồn và phải chờ chấm';
    END IF;
END$$

CREATE TRIGGER trg_lannop_bu BEFORE UPDATE ON LanNop FOR EACH ROW
BEGIN
    IF NEW.ma_giao <> OLD.ma_giao OR NEW.ma_hoc_vien <> OLD.ma_hoc_vien
       OR NEW.ma_ngon_ngu <> OLD.ma_ngon_ngu OR NEW.thoi_diem_nop <> OLD.thoi_diem_nop
       OR BINARY NEW.ma_nguon <> BINARY OLD.ma_nguon OR OLD.trang_thai_cham <> 'CHO_CHAM' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không được thay đổi lịch sử lần nộp';
    END IF;
    IF NEW.trang_thai_cham = 'DA_CHAM' AND
       (SELECT COUNT(*) FROM KetQuaTest WHERE ma_lan_nop = OLD.ma_lan_nop) <>
       (SELECT COUNT(*) FROM GiaoBai g JOIN TestCase USING (ma_bai_tap) WHERE g.ma_giao = OLD.ma_giao) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chưa đủ kết quả của bộ test';
    END IF;
    IF NEW.trang_thai_cham = 'LOI_BIEN_DICH' AND
       EXISTS (SELECT 1 FROM KetQuaTest WHERE ma_lan_nop = OLD.ma_lan_nop) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lần nộp đã có kết quả test';
    END IF;
END$$

CREATE TRIGGER trg_ketquatest_bi BEFORE INSERT ON KetQuaTest FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM LanNop ln JOIN GiaoBai g USING (ma_giao) JOIN TestCase t USING (ma_bai_tap)
        WHERE ln.ma_lan_nop = NEW.ma_lan_nop AND t.ma_test = NEW.ma_test AND ln.trang_thai_cham = 'CHO_CHAM'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Test không thuộc bài này hoặc lần nộp đã chấm';
    END IF;
END$$

CREATE TRIGGER trg_danhgia_bi BEFORE INSERT ON DanhGiaLopHoc FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM DangKyLop dk JOIN LopHoc l USING (ma_lop)
        WHERE dk.ma_dang_ky = NEW.ma_dang_ky AND (dk.trang_thai = 'HOAN_THANH'
              OR (dk.trang_thai = 'DANG_HOC' AND l.trang_thai = 'KET_THUC'))
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ học viên đã học xong lớp mới được đánh giá';
    END IF;
END$$

CREATE TRIGGER trg_nhanxet_bi BEFORE INSERT ON NhanXetLanNop FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM LanNop ln JOIN GiaoBai g USING (ma_giao)
        JOIN PhanCongGiangDay p USING (ma_lop)
        WHERE ln.ma_lan_nop = NEW.ma_lan_nop AND p.ma_giang_vien = NEW.ma_giang_vien
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ giảng viên được phân công mới có thể nhận xét';
    END IF;
END$$

CREATE TRIGGER trg_tiendo_bi BEFORE INSERT ON TienDoBaiHoc FOR EACH ROW
CALL sp_kiem_tra_bai_hoc((SELECT ma_lop FROM DangKyLop WHERE ma_dang_ky = NEW.ma_dang_ky), NEW.ma_bai_hoc)$$

CREATE TRIGGER trg_tiendo_bu BEFORE UPDATE ON TienDoBaiHoc FOR EACH ROW
CALL sp_kiem_tra_bai_hoc((SELECT ma_lop FROM DangKyLop WHERE ma_dang_ky = NEW.ma_dang_ky), NEW.ma_bai_hoc)$$

CREATE TRIGGER trg_buoihoc_bi BEFORE INSERT ON BuoiHoc FOR EACH ROW
CALL sp_kiem_tra_bai_hoc(NEW.ma_lop, NEW.ma_bai_hoc)$$

CREATE TRIGGER trg_buoihoc_bu BEFORE UPDATE ON BuoiHoc FOR EACH ROW
CALL sp_kiem_tra_bai_hoc(NEW.ma_lop, NEW.ma_bai_hoc)$$

CREATE TRIGGER trg_diemdanh_bi BEFORE INSERT ON DiemDanh FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM BuoiHoc b JOIN DangKyLop dk ON dk.ma_lop = b.ma_lop
                   WHERE b.ma_buoi = NEW.ma_buoi AND dk.ma_dang_ky = NEW.ma_dang_ky AND dk.trang_thai <> 'DA_HUY') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Buổi học và đăng ký phải cùng lớp, đăng ký còn hiệu lực';
    END IF;
END$$

CREATE TRIGGER trg_diemdanh_bu BEFORE UPDATE ON DiemDanh FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM BuoiHoc b JOIN DangKyLop dk ON dk.ma_lop = b.ma_lop
                   WHERE b.ma_buoi = NEW.ma_buoi AND dk.ma_dang_ky = NEW.ma_dang_ky AND dk.trang_thai <> 'DA_HUY') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Buổi học và đăng ký phải cùng lớp, đăng ký còn hiệu lực';
    END IF;
END$$

CREATE TRIGGER trg_phancong_bi BEFORE INSERT ON PhanCongGiangDay FOR EACH ROW
BEGIN
    IF NOT fn_co_vai_tro(NEW.ma_giang_vien, 'GIANG_VIEN') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Người được phân công phải là giảng viên đang hoạt động';
    END IF;
END$$

CREATE TRIGGER trg_phancong_bu BEFORE UPDATE ON PhanCongGiangDay FOR EACH ROW
BEGIN
    IF NOT fn_co_vai_tro(NEW.ma_giang_vien, 'GIANG_VIEN') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Người được phân công phải là giảng viên đang hoạt động';
    END IF;
END$$

CREATE TRIGGER trg_audit_dangky_i AFTER INSERT ON DangKyLop FOR EACH ROW
INSERT INTO NhatKyHeThong(ten_bang, hanh_dong, khoa_ban_ghi, du_lieu_cu, du_lieu_moi, ma_nguoi_thuc_hien)
VALUES ('DangKyLop', 'INSERT', NEW.ma_dang_ky,
        NULL,
        JSON_OBJECT('ma_lop', NEW.ma_lop, 'ma_hoc_vien', NEW.ma_hoc_vien, 'trang_thai', NEW.trang_thai), @app_user_id)$$

CREATE TRIGGER trg_audit_dangky_u AFTER UPDATE ON DangKyLop FOR EACH ROW
INSERT INTO NhatKyHeThong(ten_bang, hanh_dong, khoa_ban_ghi, du_lieu_cu, du_lieu_moi, ma_nguoi_thuc_hien)
VALUES ('DangKyLop', 'UPDATE', NEW.ma_dang_ky,
        JSON_OBJECT('ma_lop', OLD.ma_lop, 'ma_hoc_vien', OLD.ma_hoc_vien, 'trang_thai', OLD.trang_thai),
        JSON_OBJECT('ma_lop', NEW.ma_lop, 'ma_hoc_vien', NEW.ma_hoc_vien, 'trang_thai', NEW.trang_thai), @app_user_id)$$

CREATE TRIGGER trg_audit_dangky_d AFTER DELETE ON DangKyLop FOR EACH ROW
INSERT INTO NhatKyHeThong(ten_bang, hanh_dong, khoa_ban_ghi, du_lieu_cu, du_lieu_moi, ma_nguoi_thuc_hien)
VALUES ('DangKyLop', 'DELETE', OLD.ma_dang_ky,
        JSON_OBJECT('ma_lop', OLD.ma_lop, 'ma_hoc_vien', OLD.ma_hoc_vien, 'trang_thai', OLD.trang_thai),
        NULL, @app_user_id)$$

CREATE TRIGGER trg_audit_giaobai_i AFTER INSERT ON GiaoBai FOR EACH ROW
INSERT INTO NhatKyHeThong(ten_bang, hanh_dong, khoa_ban_ghi, du_lieu_cu, du_lieu_moi, ma_nguoi_thuc_hien)
VALUES ('GiaoBai', 'INSERT', NEW.ma_giao,
        NULL,
        JSON_OBJECT('ma_lop', NEW.ma_lop, 'ma_bai_tap', NEW.ma_bai_tap, 'han_nop', NEW.han_nop, 'bat_buoc', NEW.bat_buoc), @app_user_id)$$

CREATE TRIGGER trg_audit_giaobai_u AFTER UPDATE ON GiaoBai FOR EACH ROW
INSERT INTO NhatKyHeThong(ten_bang, hanh_dong, khoa_ban_ghi, du_lieu_cu, du_lieu_moi, ma_nguoi_thuc_hien)
VALUES ('GiaoBai', 'UPDATE', NEW.ma_giao,
        JSON_OBJECT('ma_lop', OLD.ma_lop, 'ma_bai_tap', OLD.ma_bai_tap, 'han_nop', OLD.han_nop, 'bat_buoc', OLD.bat_buoc),
        JSON_OBJECT('ma_lop', NEW.ma_lop, 'ma_bai_tap', NEW.ma_bai_tap, 'han_nop', NEW.han_nop, 'bat_buoc', NEW.bat_buoc), @app_user_id)$$

CREATE TRIGGER trg_audit_giaobai_d AFTER DELETE ON GiaoBai FOR EACH ROW
INSERT INTO NhatKyHeThong(ten_bang, hanh_dong, khoa_ban_ghi, du_lieu_cu, du_lieu_moi, ma_nguoi_thuc_hien)
VALUES ('GiaoBai', 'DELETE', OLD.ma_giao,
        JSON_OBJECT('ma_lop', OLD.ma_lop, 'ma_bai_tap', OLD.ma_bai_tap, 'han_nop', OLD.han_nop, 'bat_buoc', OLD.bat_buoc),
        NULL, @app_user_id)$$

DELIMITER ;
