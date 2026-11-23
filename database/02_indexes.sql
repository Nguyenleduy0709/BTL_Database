USE btlcsdl;

CREATE INDEX ix_lannop_bai_hv_nop ON LanNop(ma_giao, ma_hoc_vien, thoi_diem_nop);
CREATE INDEX ix_lannop_bai_cham_hv ON LanNop(ma_giao, trang_thai_cham, ma_hoc_vien, thoi_diem_cham DESC, ma_lan_nop DESC);
CREATE INDEX ix_kqt_test_loai ON KetQuaTest(ma_test, ma_loai);
CREATE INDEX ix_dangky_lop_tt ON DangKyLop(ma_lop, trang_thai);
CREATE INDEX ix_thanhtoan_dk_tt ON ThanhToan(ma_dang_ky, trang_thai);
CREATE INDEX ix_audit_thoi_diem ON NhatKyHeThong(thoi_diem);
