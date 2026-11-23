# Lược đồ quan hệ Crow’s Foot

Bội số `|o` ở phía cha biểu diễn khóa ngoại cho phép NULL. Lớp có một phân công chính và có thể thêm trợ giảng. Quan hệ `GiaoBai → PhanCongGiangDay` dùng khóa ghép `(ma_lop, ma_nguoi_giao)`. Quan hệ logic giữa lớp và ghi danh của một lượt nộp được xác minh bằng trigger vì `LanNop` suy ra lớp từ `GiaoBai`.

```mermaid
erDiagram
    NguoiDung ||--o{ NguoiDungVaiTro : nhan_vai_tro
    VaiTro ||--o{ NguoiDungVaiTro : duoc_gan
    DanhMucKhoaHoc |o--o{ DanhMucKhoaHoc : cha_con
    DanhMucKhoaHoc ||--o{ KhoaHoc : phan_loai
    NguoiDung ||--o{ KhoaHoc : tao
    KhoaHoc ||--o{ Chuong : gom
    Chuong ||--o{ BaiHoc : gom
    KhoaHoc ||--o{ LopHoc : mo
    LopHoc ||--|{ PhanCongGiangDay : phan_cong
    NguoiDung ||--o{ PhanCongGiangDay : giang_day
    LopHoc ||--o{ DangKyLop : ghi_danh
    NguoiDung ||--o{ DangKyLop : dang_ky
    DangKyLop ||--o{ TienDoBaiHoc : theo_doi
    BaiHoc ||--o{ TienDoBaiHoc : duoc_hoc
    LopHoc ||--o{ BuoiHoc : lap_lich
    BaiHoc |o--o{ BuoiHoc : noi_dung
    BuoiHoc ||--o{ DiemDanh : diem_danh
    DangKyLop ||--o{ DiemDanh : co_mat
    LopHoc ||--o{ ThongBaoLop : nhan
    NguoiDung ||--o{ ThongBaoLop : dang
    DangKyLop ||--o{ ThanhToan : tra
    DangKyLop ||--o| DanhGiaLopHoc : danh_gia
    DangKyLop ||--o| ChungChi : nhan
    NguoiDung ||--o{ BaiTap : soan
    BaiTap ||--o{ BaiTapChuDe : thuoc
    ChuDe ||--o{ BaiTapChuDe : phan_loai
    BaiTap ||--o{ BaiTapNgonNgu : cho_phep
    NgonNguLapTrinh ||--o{ BaiTapNgonNgu : duoc_dung
    BaiTap ||--o{ TestCase : gom
    LopHoc ||--o{ GiaoBai : nhan_bai
    BaiTap ||--o{ GiaoBai : duoc_giao
    BaiHoc |o--o{ GiaoBai : gan_voi
    PhanCongGiangDay ||--o{ GiaoBai : giao
    GiaoBai ||--o{ LanNop : nhan
    NguoiDung ||--o{ LanNop : nop
    NgonNguLapTrinh ||--o{ LanNop : viet_bang
    LanNop ||--o{ KetQuaTest : co_ket_qua
    TestCase ||--o{ KetQuaTest : kiem_tra
    LoaiKetQua ||--o{ KetQuaTest : phan_loai
    LanNop ||--o{ NhanXetLanNop : duoc_nhan_xet
    NguoiDung ||--o{ NhanXetLanNop : viet
    NguoiDung |o--o{ NhatKyHeThong : thuc_hien
```

Các cột, khóa và kiểu dữ liệu nằm trong [01_schema.sql](../database/01_schema.sql). Các khóa xác định phụ thuộc hàm được liệt kê trong [báo cáo](bao-cao.md).
