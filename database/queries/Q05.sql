-- Lớp có chỗ trống nhiều nhất
-- Biểu thức · ORDER BY
SELECT ma_code, ten_khoa_hoc, si_so_hien_tai, si_so_toi_da, si_so_toi_da - si_so_hien_tai AS cho_con
FROM v_lop_hoc WHERE trang_thai = 'MO_DANG_KY' ORDER BY cho_con DESC, ma_code LIMIT 5;
