-- Công nợ học viên theo lớp
-- LEFT JOIN · COALESCE
SELECT ma_code, ho_ten, hoc_phi, da_thanh_toan, con_no
FROM v_cong_no_hoc_phi WHERE con_no > 0 ORDER BY con_no DESC, ma_code, ho_ten LIMIT 100;
