-- Các lớp còn chỗ đăng ký
-- View · bộ lọc
SELECT ma_code, ten_khoa_hoc, si_so_toi_da - si_so_hien_tai AS cho_con, hoc_phi
FROM v_lop_hoc WHERE trang_thai = 'MO_DANG_KY' AND si_so_hien_tai < si_so_toi_da ORDER BY ma_code;
