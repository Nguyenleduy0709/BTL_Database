-- Tài liệu bổ sung cho hai khóa mẫu. Chạy lại được trên bản cài hiện có.
USE btlcsdl;
SET NAMES utf8mb4;
START TRANSACTION;

UPDATE KhoaHoc SET mo_ta = 'Viết chương trình Python với biến, vòng lặp, danh sách và hàm. Thực hành từ xử lý đầu vào đến bài toán tìm phần tử lớn thứ hai phân biệt.'
WHERE ma_code = 'PY-CB' AND ten_khoa_hoc = 'Python cơ bản'
  AND BINARY mo_ta = 'Học Python qua bài tập về vòng lặp, danh sách và thuật toán.';

UPDATE KhoaHoc SET mo_ta = 'Truy vấn dữ liệu với MySQL. Luyện JOIN, nhóm kết quả và hàm cửa sổ qua ví dụ về học viên và lượt nộp bài.'
WHERE ma_code = 'SQL-CB' AND ten_khoa_hoc = 'SQL thực hành'
  AND BINARY mo_ta = 'Luyện truy vấn quan hệ trên MySQL.';

UPDATE BaiHoc b JOIN Chuong c USING (ma_chuong) JOIN KhoaHoc k USING (ma_khoa_hoc)
SET b.noi_dung = '## Giá trị và kiểu dữ liệu
Biến đặt tên cho giá trị. Số nguyên dùng int, số có phần thập phân dùng float, văn bản dùng str, và giá trị đúng hoặc sai dùng bool. Hàm input() luôn trả về chuỗi, nên cần chuyển kiểu trước khi tính toán. Hàm type() giúp bạn kiểm tra kiểu khi kết quả khác kỳ vọng.

```python
ten = "Mai"
so_bai = int("3")
tong_bai = 5
ty_le = so_bai / tong_bai
da_xong = so_bai == tong_bai

print(f"{ten} đã học {so_bai}/{tong_bai} bài ({ty_le:.0%})")
print(da_xong)
print(type(so_bai).__name__)
```

## Thực hành
Chạy ví dụ rồi thay giá trị của so_bai bằng 5. Đọc một số từ input() và in ra số đó nhân đôi. Sau đó thử với dữ liệu 12, 0 và -3.

## Tự kiểm tra
Với so_bai = 5, tỷ lệ là 100% và da_xong là True. Biểu thức int("3") + 2 là 5. Biểu thức "3" + "2" là chuỗi "32".'
WHERE k.ma_code = 'PY-CB' AND k.ten_khoa_hoc = 'Python cơ bản' AND c.ten_chuong = 'Nhập môn Python'
  AND b.thu_tu = 1 AND b.tieu_de = 'Biến và kiểu dữ liệu'
  AND BINARY b.noi_dung = 'Khai báo biến và chuyển đổi giữa các kiểu dữ liệu Python.';

UPDATE BaiHoc b JOIN Chuong c USING (ma_chuong) JOIN KhoaHoc k USING (ma_khoa_hoc)
SET b.noi_dung = '## Rẽ nhánh và duyệt dữ liệu
if kiểm tra một điều kiện. elif kiểm tra thêm khi điều kiện trước đó sai. else xử lý các trường hợp còn lại. Dùng for khi đã có một tập dữ liệu hoặc khoảng lặp. Dùng while khi số vòng chưa biết trước và bạn có điều kiện dừng cụ thể.

```python
diem = [80, 45, 60, 90]
so_dat = 0

for gia_tri in diem:
    if gia_tri >= 60:
        so_dat += 1

print(f"Số bài đạt: {so_dat}")

so_luot = 3
while so_luot > 0:
    print(so_luot)
    so_luot -= 1
```

## Thực hành
In số điểm nhỏ hơn 60 và số điểm từ 60 trở lên. Chạy với danh sách rỗng và với một danh sách chỉ có điểm 60. Sửa vòng while để dừng khi so_luot bằng 1.

## Tự kiểm tra
Ví dụ đếm được 3 điểm đạt và in lần lượt 3, 2, 1. Khi dùng >= 60, điểm 60 được tính đạt. Vòng while cần thay đổi biến điều kiện ở mỗi lượt.'
WHERE k.ma_code = 'PY-CB' AND k.ten_khoa_hoc = 'Python cơ bản' AND c.ten_chuong = 'Nhập môn Python'
  AND b.thu_tu = 2 AND b.tieu_de = 'Điều kiện và vòng lặp'
  AND BINARY b.noi_dung = 'Sử dụng if, for và while để điều khiển luồng chương trình.';

UPDATE BaiHoc b JOIN Chuong c USING (ma_chuong) JOIN KhoaHoc k USING (ma_khoa_hoc)
SET b.noi_dung = '## Duyệt một lần và giữ hai ứng viên
Với danh sách số, hãy giữ giá trị lớn nhất và lớn thứ hai phân biệt trong hai biến. Ban đầu cả hai đều là None. Khi gặp giá trị lớn nhất mới, đẩy giá trị lớn nhất cũ xuống vị trí thứ hai. Khi gặp giá trị bằng lớn nhất, bỏ qua để bảo toàn yêu cầu phân biệt.

```python
gia_tri = [-8, -3, -6, -9, -3]
lon_nhat = None
thu_hai = None

for so in gia_tri:
    if lon_nhat is None or so > lon_nhat:
        thu_hai, lon_nhat = lon_nhat, so
    elif so < lon_nhat and (thu_hai is None or so > thu_hai):
        thu_hai = so

print("NONE" if thu_hai is None else thu_hai)
```

## Thực hành
Thử các danh sách [], [4, 4], [9, 1, 9, 7] và [-3, -8]. Sau mỗi lượt, ghi lại hai giá trị đang giữ. Giải thích vì sao gán giá trị khởi đầu là 0 gây lỗi khi danh sách chứa toàn số âm.

## Tự kiểm tra
Kết quả lần lượt là NONE, NONE, 7 và -8. Thuật toán đọc mỗi phần tử một lần và dùng hai biến theo dõi.'
WHERE k.ma_code = 'PY-CB' AND k.ten_khoa_hoc = 'Python cơ bản' AND c.ten_chuong = 'Mảng và danh sách'
  AND b.thu_tu = 1 AND b.tieu_de = 'Duyệt danh sách'
  AND BINARY b.noi_dung = 'Duyệt một danh sách bằng for. Theo dõi hai giá trị lớn nhất phân biệt sau mỗi bước.';

UPDATE BaiHoc b JOIN Chuong c USING (ma_chuong) JOIN KhoaHoc k USING (ma_khoa_hoc)
SET b.noi_dung = '## Loại trùng trước khi sắp xếp
set giữ một bản của mỗi giá trị phân biệt. sorted tạo danh sách có thứ tự từ dữ liệu đầu vào. Với một danh sách đã tăng dần, phần tử lớn thứ hai nằm ở vị trí -2, nếu có ít nhất hai giá trị.

```python
def lon_thu_hai(cac_so):
    phan_biet = sorted(set(cac_so))
    return phan_biet[-2] if len(phan_biet) >= 2 else None

for mau in ([7, 9, 9, 4], [4, 4], [-8, -3, -6]):
    ket_qua = lon_thu_hai(mau)
    print("NONE" if ket_qua is None else ket_qua)
```

## Thực hành
Đổi hàm để trả về phần tử lớn thứ ba phân biệt. Thử một danh sách có ba phần tử và một danh sách có ba giá trị nhưng chỉ hai giá trị phân biệt. So sánh cách làm với thuật toán duyệt một lần.

## Tự kiểm tra
Ví dụ in 7, NONE, -6. Cách sắp xếp ngắn gọn và dễ kiểm tra. Khi cần đúng một ứng viên thứ hai trên tập dữ liệu lớn, có thể duyệt một lần mà không phải sắp xếp.'
WHERE k.ma_code = 'PY-CB' AND k.ten_khoa_hoc = 'Python cơ bản' AND c.ten_chuong = 'Mảng và danh sách'
  AND b.thu_tu = 2 AND b.tieu_de = 'Sắp xếp và tập hợp'
  AND BINARY b.noi_dung = 'Dùng set để loại trùng, sau đó dùng sorted để xếp thứ tự các phần tử.';

UPDATE BaiHoc b JOIN Chuong c USING (ma_chuong) JOIN KhoaHoc k USING (ma_khoa_hoc)
SET b.noi_dung = '## Ghép hai bảng và đếm theo khóa
SELECT chọn cột cần đọc. JOIN ghép các hàng có khóa liên quan. GROUP BY gom những hàng có cùng khóa để tính COUNT, SUM hoặc AVG. Sau khi ghép khóa học với lớp, mỗi lớp tạo một hàng, nên COUNT(*) có thể đếm số lớp của từng khóa.

```sql
WITH khoa AS (
    SELECT 1 AS ma_khoa, ''Python'' AS ten
    UNION ALL SELECT 2, ''SQL''
),
lop AS (
    SELECT ''PY01'' AS ma_lop, 1 AS ma_khoa
    UNION ALL SELECT ''PY02'', 1
    UNION ALL SELECT ''SQL01'', 2
)
SELECT k.ten, COUNT(*) AS so_lop
FROM khoa AS k
JOIN lop AS l ON l.ma_khoa = k.ma_khoa
GROUP BY k.ma_khoa, k.ten
ORDER BY so_lop DESC, k.ten;
```

## Thực hành
Chạy ví dụ trong MySQL. Thêm lớp SQL02 vào biểu thức lop rồi kiểm tra số lớp. Tiếp theo, thêm một khóa chưa có lớp vào biểu thức khoa và giải thích vì sao khóa đó vắng mặt trong kết quả.

## Tự kiểm tra
Ban đầu Python có 2 lớp và SQL có 1 lớp. Sau khi thêm SQL02, cả hai khóa có 2 lớp. INNER JOIN chỉ giữ những hàng có đối tượng tương ứng ở cả hai phía.'
WHERE k.ma_code = 'SQL-CB' AND k.ten_khoa_hoc = 'SQL thực hành' AND c.ten_chuong = 'Truy vấn dữ liệu'
  AND b.thu_tu = 1 AND b.tieu_de = 'JOIN và GROUP BY'
  AND BINARY b.noi_dung = 'Ghép dữ liệu theo khóa ngoại rồi tổng hợp theo nhóm.';

INSERT INTO Chuong(ma_khoa_hoc, thu_tu, ten_chuong)
SELECT k.ma_khoa_hoc, 3, 'Hàm và thực hành' FROM KhoaHoc k
WHERE k.ma_code = 'PY-CB' AND k.ten_khoa_hoc = 'Python cơ bản'
 AND NOT EXISTS (SELECT 1 FROM Chuong c WHERE c.ma_khoa_hoc = k.ma_khoa_hoc
                 AND (c.thu_tu = 3 OR c.ten_chuong = 'Hàm và thực hành'))
ON DUPLICATE KEY UPDATE thu_tu = Chuong.thu_tu;

INSERT INTO Chuong(ma_khoa_hoc, thu_tu, ten_chuong)
SELECT k.ma_khoa_hoc, 2, 'Phân tích kết quả học tập' FROM KhoaHoc k
WHERE k.ma_code = 'SQL-CB' AND k.ten_khoa_hoc = 'SQL thực hành'
 AND NOT EXISTS (SELECT 1 FROM Chuong c WHERE c.ma_khoa_hoc = k.ma_khoa_hoc
                 AND (c.thu_tu = 2 OR c.ten_chuong = 'Phân tích kết quả học tập'))
ON DUPLICATE KEY UPDATE thu_tu = Chuong.thu_tu;

INSERT INTO BaiHoc(ma_chuong, thu_tu, tieu_de, thoi_luong_phut, noi_dung)
SELECT c.ma_chuong, 1, 'Viết hàm và kiểm tra trường hợp biên', 40, '## Biến yêu cầu thành hàm có đầu vào và đầu ra
Hàm nhận tham số và có thể trả dữ liệu bằng return. Đặt phần tính toán vào hàm riêng giúp thử được nhiều bộ dữ liệu mà không cần nhập tay. Kiểm tra các trường hợp bình thường, danh sách rỗng và các giá trị lặp.

```python
def dem_dat(danh_sach, nguong=60):
    dem = 0
    for diem in danh_sach:
        if diem >= nguong:
            dem += 1
    return dem

assert dem_dat([59, 60, 100]) == 2
assert dem_dat([]) == 0
assert dem_dat([40, 40], 40) == 2
```

## Thực hành
Viết hàm tra_ve_ty_le_dat. Dùng dem_dat để đếm bài đạt và trả về None khi không có điểm. Tự viết ba kiểm thử có ít nhất một trường hợp rỗng.

## Tự kiểm tra
Một hàm trả None trên đầu vào rỗng tránh chia cho 0. Danh sách [59, 60, 100] có 2 trong 3 điểm đạt khi ngưỡng là 60.'
FROM Chuong c JOIN KhoaHoc k USING (ma_khoa_hoc)
WHERE k.ma_code = 'PY-CB' AND k.ten_khoa_hoc = 'Python cơ bản' AND c.ten_chuong = 'Hàm và thực hành'
  AND NOT EXISTS (SELECT 1 FROM BaiHoc b WHERE b.ma_chuong = c.ma_chuong
                  AND (b.thu_tu = 1 OR b.tieu_de = 'Viết hàm và kiểm tra trường hợp biên'))
ON DUPLICATE KEY UPDATE thu_tu = BaiHoc.thu_tu;

INSERT INTO BaiHoc(ma_chuong, thu_tu, tieu_de, thoi_luong_phut, noi_dung)
SELECT c.ma_chuong, 2, 'Bài tập tổng hợp về danh sách', 45, '## Tách tính toán, định dạng và nhập xuất
Viết chương trình đọc các số nguyên trên một dòng và in phần tử lớn thứ hai phân biệt hoặc NONE. Tách hàm tính toán khỏi input() và print() để kiểm thử độc lập.

```python
def giai(cac_so):
    # TODO: triển khai thuật toán từ các bài trước.
    return None

def hien_thi(ket_qua):
    return "NONE" if ket_qua is None else str(ket_qua)

du_lieu = list(map(int, input().split()))
print(hien_thi(giai(du_lieu)))
```

## Thực hành
Hoàn thiện giai() theo hai cách. Một cách dùng set và sorted. Cách còn lại chỉ duyệt danh sách một lần. So sánh cả hai với đầu vào có giá trị lớn nhất lặp lại, toàn số âm và chỉ có một giá trị phân biệt. Nếu lớp có bài thực hành được giao, mở lớp để nộp lời giải.

## Tự kiểm tra
Với 7 9 9 4, chương trình in 7. Với -8 -3 -6 -9, chương trình in -6. Với 4 4 4, chương trình in NONE.'
FROM Chuong c JOIN KhoaHoc k USING (ma_khoa_hoc)
WHERE k.ma_code = 'PY-CB' AND k.ten_khoa_hoc = 'Python cơ bản' AND c.ten_chuong = 'Hàm và thực hành'
  AND NOT EXISTS (SELECT 1 FROM BaiHoc b WHERE b.ma_chuong = c.ma_chuong
                  AND (b.thu_tu = 2 OR b.tieu_de = 'Bài tập tổng hợp về danh sách'))
ON DUPLICATE KEY UPDATE thu_tu = BaiHoc.thu_tu;

INSERT INTO BaiHoc(ma_chuong, thu_tu, tieu_de, thoi_luong_phut, noi_dung)
SELECT c.ma_chuong, 2, 'Lọc dữ liệu với WHERE và HAVING', 45, '## Lọc hàng trước hay sau khi gom nhóm
WHERE giữ những hàng thỏa điều kiện trước GROUP BY. HAVING lọc kết quả đã tổng hợp. Nếu cần xem các lớp có ít nhất hai bài đạt, hãy lọc bài đạt trước và dùng HAVING kiểm tra số đếm.

```sql
WITH ket_qua AS (
    SELECT ''PY01'' AS lop, 80 AS diem
    UNION ALL SELECT ''PY01'', 100
    UNION ALL SELECT ''PY02'', 40
    UNION ALL SELECT ''PY02'', 75
)
SELECT lop, COUNT(*) AS so_bai_dat
FROM ket_qua
WHERE diem >= 60
GROUP BY lop
HAVING COUNT(*) >= 2;
```

## Thực hành
Đổi ngưỡng điểm thành 90. Sau đó giữ ngưỡng 60 và đổi HAVING để hiển thị các lớp có ít nhất một bài đạt. Dự đoán kết quả trước khi chạy.

## Tự kiểm tra
Truy vấn gốc trả PY01 với 2 bài. Ở ngưỡng 90, chỉ một hàng đạt nên không có nhóm nào vượt qua HAVING.'
FROM Chuong c JOIN KhoaHoc k USING (ma_khoa_hoc)
WHERE k.ma_code = 'SQL-CB' AND k.ten_khoa_hoc = 'SQL thực hành' AND c.ten_chuong = 'Truy vấn dữ liệu'
  AND NOT EXISTS (SELECT 1 FROM BaiHoc b WHERE b.ma_chuong = c.ma_chuong
                  AND (b.thu_tu = 2 OR b.tieu_de = 'Lọc dữ liệu với WHERE và HAVING'))
ON DUPLICATE KEY UPDATE thu_tu = BaiHoc.thu_tu;

INSERT INTO BaiHoc(ma_chuong, thu_tu, tieu_de, thoi_luong_phut, noi_dung)
SELECT c.ma_chuong, 1, 'LEFT JOIN và dữ liệu chưa có kết quả', 45, '## Giữ hàng ở phía trái
LEFT JOIN giữ mọi hàng từ bảng bên trái. Nếu bên phải không có bản ghi khớp, các cột bên phải là NULL. Dùng COUNT(mã lượt) để đếm lượt nộp, vì COUNT(*) tính cả hàng được ghép với NULL.

```sql
WITH hoc_vien AS (
    SELECT 1 AS id, ''An'' AS ten
    UNION ALL SELECT 2, ''Chi''
),
luot_nop AS (
    SELECT 101 AS ma_luot, 1 AS hoc_vien_id
    UNION ALL SELECT 102, 1
)
SELECT h.ten, COUNT(n.ma_luot) AS so_luot
FROM hoc_vien AS h
LEFT JOIN luot_nop AS n ON n.hoc_vien_id = h.id
GROUP BY h.id, h.ten
ORDER BY h.id;
```

## Thực hành
Chạy truy vấn rồi so sánh kết quả khi thay COUNT(n.ma_luot) bằng COUNT(*). Thay LEFT JOIN bằng JOIN và quan sát học viên nào biến mất.

## Tự kiểm tra
LEFT JOIN kết hợp COUNT(n.ma_luot) trả An 2 và Chi 0. COUNT(*) trả Chi 1 vì vẫn có hàng được giữ từ tập học viên.'
FROM Chuong c JOIN KhoaHoc k USING (ma_khoa_hoc)
WHERE k.ma_code = 'SQL-CB' AND k.ten_khoa_hoc = 'SQL thực hành' AND c.ten_chuong = 'Phân tích kết quả học tập'
  AND NOT EXISTS (SELECT 1 FROM BaiHoc b WHERE b.ma_chuong = c.ma_chuong
                  AND (b.thu_tu = 1 OR b.tieu_de = 'LEFT JOIN và dữ liệu chưa có kết quả'))
ON DUPLICATE KEY UPDATE thu_tu = BaiHoc.thu_tu;

INSERT INTO BaiHoc(ma_chuong, thu_tu, tieu_de, thoi_luong_phut, noi_dung)
SELECT c.ma_chuong, 2, 'ROW_NUMBER và lần nộp gần nhất', 50, '## Đánh số trong từng nhóm
ROW_NUMBER đánh số các hàng theo PARTITION BY và ORDER BY. Để lấy lượt mới nhất của từng học viên, sắp xếp thời gian giảm dần. Thêm mã lượt giảm dần để thứ tự ổn định khi hai lượt trùng thời gian.

```sql
WITH luot AS (
    SELECT 1 AS id, ''An'' AS ten, ''2026-01-01'' AS ngay, 100 AS diem
    UNION ALL SELECT 2, ''An'', ''2026-01-02'', 80
    UNION ALL SELECT 3, ''Bình'', ''2026-01-01'', 60
),
xep AS (
    SELECT luot.*, ROW_NUMBER() OVER (
        PARTITION BY ten ORDER BY ngay DESC, id DESC
    ) AS hang
    FROM luot
)
SELECT ten, diem FROM xep WHERE hang = 1 ORDER BY ten;
```

## Thực hành
Viết thêm một truy vấn MAX(diem) GROUP BY ten. So sánh điểm cao nhất với điểm lần gần nhất. Trong hệ thống có nhiều bài tập, hãy phân vùng theo cả mã học viên và mã bài giao.

## Tự kiểm tra
Lượt gần nhất của An đạt 80, còn điểm cao nhất là 100. Lượt gần nhất phản ánh trạng thái mới nhất, điểm cao nhất ghi nhận thành tích tốt nhất.'
FROM Chuong c JOIN KhoaHoc k USING (ma_khoa_hoc)
WHERE k.ma_code = 'SQL-CB' AND k.ten_khoa_hoc = 'SQL thực hành' AND c.ten_chuong = 'Phân tích kết quả học tập'
  AND NOT EXISTS (SELECT 1 FROM BaiHoc b WHERE b.ma_chuong = c.ma_chuong
                  AND (b.thu_tu = 2 OR b.tieu_de = 'ROW_NUMBER và lần nộp gần nhất'))
ON DUPLICATE KEY UPDATE thu_tu = BaiHoc.thu_tu;

INSERT INTO BaiHoc(ma_chuong, thu_tu, tieu_de, thoi_luong_phut, noi_dung)
SELECT c.ma_chuong, 3, 'Bài tập tổng hợp kết quả theo lớp', 50, '## Từ dữ liệu ghi danh đến bảng điểm
Mỗi lượt nộp có mã riêng. Khi lập báo cáo, gom kết quả theo học viên chỉ sau khi đã có một điểm cho từng lượt. Giữ tập ghi danh bên trái để còn thấy những người chưa nộp. Bài tập này dùng điểm mỗi lượt đã được tính sẵn.

```sql
WITH hoc_vien AS (
    SELECT 1 AS id, ''An'' AS ten
    UNION ALL SELECT 2, ''Bình''
    UNION ALL SELECT 3, ''Chi''
),
luot AS (
    SELECT 101 AS id, 1 AS hoc_vien_id, 60 AS diem
    UNION ALL SELECT 102, 1, 100
    UNION ALL SELECT 103, 2, 80
)
SELECT h.ten, COUNT(n.id) AS so_luot, MAX(n.diem) AS diem_tot_nhat
FROM hoc_vien AS h
LEFT JOIN luot AS n ON n.hoc_vien_id = h.id
GROUP BY h.id, h.ten
ORDER BY h.id;
```

## Thực hành
Thêm cột trạng thái với CASE. Quy ước CHUA_NOP nếu số lượt bằng 0, DAT nếu có một lượt đạt 100, còn lại là CHUA_DAT. Tổng hợp lần nữa để đếm số lượt toàn lớp và số người theo từng trạng thái.

## Tự kiểm tra
An có 2 lượt và đạt 100. Bình có 1 lượt, cao nhất 80. Chi có 0 lượt và điểm NULL. Tổng cộng có 3 lượt, 1 người đạt, 1 người chưa đạt và 1 người chưa nộp.'
FROM Chuong c JOIN KhoaHoc k USING (ma_khoa_hoc)
WHERE k.ma_code = 'SQL-CB' AND k.ten_khoa_hoc = 'SQL thực hành' AND c.ten_chuong = 'Phân tích kết quả học tập'
  AND NOT EXISTS (SELECT 1 FROM BaiHoc b WHERE b.ma_chuong = c.ma_chuong
                  AND (b.thu_tu = 3 OR b.tieu_de = 'Bài tập tổng hợp kết quả theo lớp'))
ON DUPLICATE KEY UPDATE thu_tu = BaiHoc.thu_tu;

COMMIT;
