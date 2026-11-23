-- Điểm tốt nhất từng bài của An
-- MAX · GROUP BY
SELECT g.ma_lop_code, g.tieu_de, MAX(d.diem) AS diem_tot_nhat
FROM v_diem_lan_nop d JOIN v_giao_bai g USING (ma_giao)
WHERE d.ma_hoc_vien = 3 GROUP BY g.ma_giao, g.ma_lop_code, g.tieu_de;
