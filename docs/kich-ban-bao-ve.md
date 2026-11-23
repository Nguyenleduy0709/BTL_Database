# Kịch bản bảo vệ CodeLab

**Mở bài trong 30 giây.** An nộp hai lần, Bình nộp một lần và Chi chưa nộp. Với lớp PY01, ai đã hoàn thành và giảng viên nên chữa test nào?

| Phần | Thời lượng | Thao tác |
| --- | --- | --- |
| Mô hình dữ liệu | 2 phút | Trình bày `KhoaHoc → LopHoc → GiaoBai`, sau đó `LanNop → KetQuaTest ← TestCase`. Nhấn mạnh deadline gắn với bài giao, mỗi lượt có kết quả độc lập. |
| Báo cáo | 2 phút | Mở thống kê PY01 và xem 3/2/1/1/1. Đọc bảng điểm An 100%, Bình 80%, Chi trống. Xem biểu đồ có một lỗi ở test 5. Chạy Q07 hoặc Q14 trong MySQL Workbench để đối chiếu. |
| Transaction | 2 phút | Chạy `web/scripts/race_dang_ky.py`. Dừng ở kết quả một đăng ký thành công và một báo lỗi lớp đầy. Cho xem hàng `LopHoc` bị khóa tới COMMIT. |
| Chấm và phiên bản | 2 phút | Cho Dung nộp thử tại PY02, dùng trợ giảng để chấm. Trình bày kiểm thử trả về 0 dòng nếu JSON thiếu test hoặc có test sai bài. Tạo bản sao v2 và mở bộ test mới. |
| Truy vấn và tối ưu | 2 phút | Chạy EXPLAIN Q33 hoặc Q34 trong Workbench hoặc dùng `scripts/benchmark_plans.py`. Đối chiếu kế hoạch có và chưa có chỉ mục ghép, chỉ ra bước sort, số dòng và thời gian thực tế. |

## Câu hỏi thường gặp

**Vì sao điểm tốt nhất và lần chấm gần nhất khác nhau?** Điểm tốt nhất dùng để công nhận kết quả đã từng đạt. Lượt chấm gần nhất phản ánh lỗi cần chữa ở thời điểm hiện tại. Hai kết quả được suy ra từ cùng lịch sử lượt nộp.

**Hai lượt 4/5 mà sai hai test khác nhau có được tính đạt không?** MySQL tính cờ đạt trên từng `ma_lan_nop`, rồi lấy `MAX(dat)` cho từng học viên và bài giao. Phép hợp các test đúng qua nhiều lượt sẽ cho kết quả sai nghiệp vụ.

**Vì sao dùng khóa ghép cho kết quả chấm?** Một test có tối đa một kết quả trong một lượt nộp. Khóa `(ma_lan_nop, ma_test)` thực thi điều đó và bảo vệ lô chấm khỏi test lặp.

**Vì sao Chi vẫn có mặt trong bảng?** Truy vấn bắt đầu từ ghi danh, ghép bài giao cùng lớp và `LEFT JOIN` lượt nộp. Chi có dòng ghi danh và điểm `NULL`.

**Hệ thống chặn hai người tranh chỗ thế nào?** Mỗi lượt đăng ký khóa cùng hàng lớp bằng `FOR UPDATE` trước khi đếm người. Lượt sau đọc sĩ số đã cập nhật khi có khóa. Nếu tách kiểm tra và ghi thành hai thao tác độc lập, cả hai có thể nhìn thấy một chỗ trống rồi cùng ghi.

**Vì sao không lưu sĩ số, tiến độ và điểm?** Giá trị đều được tính từ bản ghi nguồn. Lưu lặp sẽ đòi hỏi cập nhật đồng bộ. `xep_loai` trên chứng chỉ là giá trị lịch sử tại lúc cấp.

**Chấm giả lập bao gồm những gì?** Người chấm chọn mã cho từng test. MySQL kiểm tra đủ, đúng và duy nhất rồi ghi cả lô. Trạng thái lỗi biên dịch cho điểm 0 và không xuất hiện trong thống kê lỗi từng test nếu là kết quả mới nhất.
