# Mô hình khái niệm Chen

Hình chữ nhật là thực thể. Hình thoi là quan hệ. Nhãn 1, N và 0..1 cho biết số lượng tham gia ở từng đầu. Thực thể kết hợp lưu thông tin của chính quan hệ, ví dụ ghi danh có trạng thái và lần nộp có mã nguồn. Chỉ đưa các thuộc tính định danh tiêu biểu vào hình. Đặc tả đầy đủ nằm trong lược đồ SQL.

## Đào tạo và tổ chức lớp

```mermaid
flowchart LR
    U[NguoiDung] ---|N| UR{Được gán} ---|N| V[VaiTro]
    M[DanhMucKhoaHoc] ---|1| MK{Phân loại} ---|N| K[KhoaHoc]
    K ---|1| KC{Gồm} ---|N| C[Chuong]
    C ---|1| CB{Gồm} ---|N| B[BaiHoc]
    K ---|1| KL{Mở lớp} ---|N| L[LopHoc]
    U ---|1| UP{Giảng dạy} ---|N| P[PhanCongGiangDay]
    L ---|1| LP{Có phân công} ---|N| P
    U ---|1| UD{Đăng ký} ---|N| D[DangKyLop]
    L ---|1| LD{Ghi danh} ---|N| D
    B ---|1| BT{Hoàn thành} ---|N| T[TienDoBaiHoc]
    D ---|1| DT{Theo dõi} ---|N| T
    L ---|1| LS{Lên lịch} ---|N| S[BuoiHoc]
    S ---|1| SX{Điểm danh} ---|N| X[DiemDanh]
    D ---|1| DX{Tham dự} ---|N| X
    L ---|1| LN{Có thông báo} ---|N| N[ThongBaoLop]
```

## Bài thực hành, lượt nộp và chấm điểm

```mermaid
flowchart LR
    L[LopHoc] ---|1| LG{Nhận bài} ---|N| G[GiaoBai]
    E[BaiTap] ---|1| EG{Được giao} ---|N| G
    E ---|N| EC{Thuộc chủ đề} ---|N| C[ChuDe]
    E ---|N| EN{Cho phép} ---|N| A[NgonNguLapTrinh]
    E ---|1| ET{Có bộ test} ---|N| T[TestCase]
    G ---|1| GS{Nhận lượt nộp} ---|N| S[LanNop]
    U[NguoiDung] ---|1| US{Nộp} ---|N| S
    S ---|1| SR{Cho kết quả} ---|N| R[KetQuaTest]
    T ---|1| TR{Được dùng để chấm} ---|N| R
    Z[LoaiKetQua] ---|1| ZR{Phân loại} ---|N| R
    S ---|1| SX{Nhận nhận xét} ---|N| X[NhanXetLanNop]
    E -.- EM([Mã đề, phiên bản])
    G -.- GD([Hạn nộp])
    S -.- SC([Mã nguồn, thời điểm])
    R -.- RK([Mã lượt, mã test])
```

## Học phí, phản hồi và chứng chỉ

```mermaid
flowchart LR
    D[DangKyLop] ---|1| DT{Thanh toán} ---|N| T[ThanhToan]
    D ---|1| DS{Đánh giá} ---|0..1| S[DanhGiaLopHoc]
    D ---|1| DC{Nhận chứng chỉ} ---|0..1| C[ChungChi]
    C -.- CS([Số hiệu, ngày cấp, xếp loại])
    U[NguoiDung] ---|0..1| UA{Thực hiện} ---|N| A[NhatKyHeThong]
```

Hai quan hệ N–N của ngân hàng bài chuyển thành `BaiTapChuDe` và `BaiTapNgonNgu`. Quan hệ gán vai trò chuyển thành `NguoiDungVaiTro`. [Sơ đồ quan hệ](erd-quan-he.md) thể hiện đầy đủ các khóa ngoại và quan hệ phụ.
