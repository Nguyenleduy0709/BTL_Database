# Đo kế hoạch thực thi trên PY-BENCH

Lớp `PY-BENCH` dùng 200 học viên, mỗi người 50 lượt nộp và mỗi lượt 5 test. Kịch bản PY01 vẫn có 3 lượt. Dữ liệu benchmark được sinh theo CTE đệ quy và lưu đúng các bảng nghiệp vụ.

| Truy vấn | Chi phí cần quan sát | Chỉ mục liên quan |
| --- | --- | --- |
| Q33 · lỗi lượt chấm gần nhất | Lọc bài giao, sắp xếp để đánh số theo học viên, nối kết quả từng test | `ix_lannop_bai_cham_hv`, `ix_kqt_test_loai` và khóa chính của `KetQuaTest` |
| Q34 · bảng điểm tốt nhất | Nối người ghi danh với lượt nộp và tổng hợp tất cả kết quả đủ điều kiện | `ix_lannop_bai_hv_nop`, `ix_dangky_lop_tt` và khóa chính của `KetQuaTest` |

Để đo đối chứng, dùng **hai MySQL demo trống và độc lập**. Nạp bản đối chứng bằng `scripts/init_db.py --without-secondary-indexes --port <cổng A>` và bản đầy đủ bằng `scripts/init_db.py --port <cổng B>`. Dùng `scripts/benchmark_plans.py --port <cổng>` trên từng bản. Nếu dùng bản A cho bước tiếp theo, có thể nạp riêng `database/02_indexes.sql` vào bản A sau khi ghi kết quả ban đầu.

Script chạy `EXPLAIN ANALYZE` một lần làm nóng, lấy trung vị của năm lần đo sau đó (có thể đổi bằng `--runs`) và in kế hoạch cuối cho mỗi câu. So sánh số hàng đọc, cách tra cứu và vòng lặp ở từng bước. Chỉ mục có thể đổi kế hoạch và tăng chi phí ghi. Nếu MySQL vẫn sắp xếp để chạy window hoặc chọn quét nhiều hàng, ghi nhận kết quả thực tế thay vì suy ra mọi truy vấn đều nhanh hơn.

## Kết quả trên MySQL 8.0.46

| Truy vấn | Chưa có chỉ mục phụ | Có chỉ mục phụ |
| --- | ---: | ---: |
| Q33 | 45,8 ms | 33,5 ms |
| Q34 | 269 ms | 249 ms |

Q33 vẫn sắp xếp 10.003 lượt ở bước cấp số thứ tự và tra kết quả từng test qua khóa chính của `KetQuaTest`. Q34 sử dụng `ix_lannop_bai_hv_nop` để tra lượt theo cặp bài giao và học viên. Các thời gian là trung vị của một lần đo trên máy demo và thay đổi theo tải. [Kế hoạch trước khi thêm chỉ mục](explain-truoc.txt), [kế hoạch sau khi thêm chỉ mục](explain-sau.txt).

Nguồn kỹ thuật [MySQL EXPLAIN](https://dev.mysql.com/doc/refman/8.0/en/explain.html), [MySQL chỉ mục nhiều cột](https://dev.mysql.com/doc/refman/8.0/en/multiple-column-indexes.html).
