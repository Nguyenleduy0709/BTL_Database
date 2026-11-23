CREATE DATABASE IF NOT EXISTS btlcsdl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE btlcsdl;
SET NAMES utf8mb4;

CREATE TABLE VaiTro (
    ma_vai_tro TINYINT UNSIGNED PRIMARY KEY,
    ten_vai_tro VARCHAR(30) NOT NULL UNIQUE,
    mo_ta VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE NguoiDung (
    ma_nguoi_dung INT PRIMARY KEY AUTO_INCREMENT,
    ten_dang_nhap VARCHAR(64) NOT NULL UNIQUE,
    email VARCHAR(254) NOT NULL UNIQUE,
    mat_khau_hash CHAR(60) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    ho_ten VARCHAR(120) NOT NULL,
    ngay_sinh DATE,
    so_dien_thoai VARCHAR(20) UNIQUE,
    trang_thai ENUM('HOAT_DONG','KHOA') NOT NULL DEFAULT 'HOAT_DONG',
    ngay_tao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (email LIKE '%_@_%._%')
) ENGINE=InnoDB;

CREATE TABLE NguoiDungVaiTro (
    ma_nguoi_dung INT NOT NULL,
    ma_vai_tro TINYINT UNSIGNED NOT NULL,
    ngay_gan DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ma_nguoi_dung, ma_vai_tro),
    FOREIGN KEY (ma_nguoi_dung) REFERENCES NguoiDung(ma_nguoi_dung),
    FOREIGN KEY (ma_vai_tro) REFERENCES VaiTro(ma_vai_tro)
) ENGINE=InnoDB;

CREATE TABLE DanhMucKhoaHoc (
    ma_danh_muc INT PRIMARY KEY AUTO_INCREMENT,
    ten_danh_muc VARCHAR(100) NOT NULL UNIQUE,
    ma_danh_muc_cha INT,
    FOREIGN KEY (ma_danh_muc_cha) REFERENCES DanhMucKhoaHoc(ma_danh_muc)
) ENGINE=InnoDB;

CREATE TABLE KhoaHoc (
    ma_khoa_hoc INT PRIMARY KEY AUTO_INCREMENT,
    ma_code VARCHAR(20) NOT NULL UNIQUE,
    ten_khoa_hoc VARCHAR(160) NOT NULL,
    ma_danh_muc INT NOT NULL,
    mo_ta TEXT,
    trinh_do ENUM('CO_BAN','TRUNG_CAP','NANG_CAO') NOT NULL DEFAULT 'CO_BAN',
    ma_nguoi_tao INT NOT NULL,
    trang_thai ENUM('NHAP','CONG_BO','NGUNG') NOT NULL DEFAULT 'NHAP',
    ngay_tao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ma_danh_muc) REFERENCES DanhMucKhoaHoc(ma_danh_muc),
    FOREIGN KEY (ma_nguoi_tao) REFERENCES NguoiDung(ma_nguoi_dung)
) ENGINE=InnoDB;

CREATE TABLE Chuong (
    ma_chuong INT PRIMARY KEY AUTO_INCREMENT,
    ma_khoa_hoc INT NOT NULL,
    thu_tu SMALLINT UNSIGNED NOT NULL CHECK (thu_tu > 0),
    ten_chuong VARCHAR(160) NOT NULL,
    UNIQUE (ma_khoa_hoc, thu_tu),
    FOREIGN KEY (ma_khoa_hoc) REFERENCES KhoaHoc(ma_khoa_hoc) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE BaiHoc (
    ma_bai_hoc INT PRIMARY KEY AUTO_INCREMENT,
    ma_chuong INT NOT NULL,
    thu_tu SMALLINT UNSIGNED NOT NULL CHECK (thu_tu > 0),
    tieu_de VARCHAR(160) NOT NULL,
    noi_dung MEDIUMTEXT NOT NULL,
    thoi_luong_phut SMALLINT UNSIGNED NOT NULL CHECK (thoi_luong_phut > 0),
    UNIQUE (ma_chuong, thu_tu),
    FOREIGN KEY (ma_chuong) REFERENCES Chuong(ma_chuong) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE LopHoc (
    ma_lop INT PRIMARY KEY AUTO_INCREMENT,
    ma_code VARCHAR(20) NOT NULL UNIQUE,
    ma_khoa_hoc INT NOT NULL,
    ngay_bat_dau DATE NOT NULL,
    ngay_ket_thuc DATE NOT NULL,
    si_so_toi_da SMALLINT UNSIGNED NOT NULL CHECK (si_so_toi_da > 0),
    hoc_phi DECIMAL(12,0) NOT NULL DEFAULT 0 CHECK (hoc_phi >= 0),
    trang_thai ENUM('MO_DANG_KY','DANG_HOC','KET_THUC','HUY') NOT NULL DEFAULT 'MO_DANG_KY',
    CHECK (ngay_ket_thuc >= ngay_bat_dau),
    FOREIGN KEY (ma_khoa_hoc) REFERENCES KhoaHoc(ma_khoa_hoc)
) ENGINE=InnoDB;

CREATE TABLE PhanCongGiangDay (
    ma_lop INT NOT NULL,
    ma_giang_vien INT NOT NULL,
    vai_tro_day ENUM('CHINH','TRO_GIANG') NOT NULL,
    ngay_phan_cong DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    la_chinh TINYINT GENERATED ALWAYS AS (CASE WHEN vai_tro_day = 'CHINH' THEN 1 END) VIRTUAL,
    PRIMARY KEY (ma_lop, ma_giang_vien),
    UNIQUE (ma_lop, la_chinh),
    FOREIGN KEY (ma_lop) REFERENCES LopHoc(ma_lop),
    FOREIGN KEY (ma_giang_vien) REFERENCES NguoiDung(ma_nguoi_dung)
) ENGINE=InnoDB;

CREATE TABLE DangKyLop (
    ma_dang_ky INT PRIMARY KEY AUTO_INCREMENT,
    ma_lop INT NOT NULL,
    ma_hoc_vien INT NOT NULL,
    thoi_diem_dang_ky DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    trang_thai ENUM('DANG_HOC','DA_HUY','HOAN_THANH') NOT NULL DEFAULT 'DANG_HOC',
    UNIQUE (ma_lop, ma_hoc_vien),
    FOREIGN KEY (ma_lop) REFERENCES LopHoc(ma_lop),
    FOREIGN KEY (ma_hoc_vien) REFERENCES NguoiDung(ma_nguoi_dung)
) ENGINE=InnoDB;

CREATE TABLE TienDoBaiHoc (
    ma_dang_ky INT NOT NULL,
    ma_bai_hoc INT NOT NULL,
    thoi_diem_hoan_thanh DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ma_dang_ky, ma_bai_hoc),
    FOREIGN KEY (ma_dang_ky) REFERENCES DangKyLop(ma_dang_ky),
    FOREIGN KEY (ma_bai_hoc) REFERENCES BaiHoc(ma_bai_hoc)
) ENGINE=InnoDB;

CREATE TABLE BuoiHoc (
    ma_buoi INT PRIMARY KEY AUTO_INCREMENT,
    ma_lop INT NOT NULL,
    so_thu_tu SMALLINT UNSIGNED NOT NULL CHECK (so_thu_tu > 0),
    bat_dau DATETIME NOT NULL,
    ket_thuc DATETIME NOT NULL,
    hinh_thuc ENUM('TRUC_TIEP','ONLINE') NOT NULL,
    dia_diem VARCHAR(255),
    ma_bai_hoc INT,
    UNIQUE (ma_lop, so_thu_tu),
    CHECK (ket_thuc > bat_dau),
    FOREIGN KEY (ma_lop) REFERENCES LopHoc(ma_lop),
    FOREIGN KEY (ma_bai_hoc) REFERENCES BaiHoc(ma_bai_hoc)
) ENGINE=InnoDB;

CREATE TABLE DiemDanh (
    ma_buoi INT NOT NULL,
    ma_dang_ky INT NOT NULL,
    trang_thai ENUM('CO_MAT','MUON','VANG_CO_PHEP','VANG') NOT NULL,
    ghi_chu VARCHAR(255),
    PRIMARY KEY (ma_buoi, ma_dang_ky),
    FOREIGN KEY (ma_buoi) REFERENCES BuoiHoc(ma_buoi),
    FOREIGN KEY (ma_dang_ky) REFERENCES DangKyLop(ma_dang_ky)
) ENGINE=InnoDB;

CREATE TABLE ThongBaoLop (
    ma_thong_bao INT PRIMARY KEY AUTO_INCREMENT,
    ma_lop INT NOT NULL,
    ma_nguoi_dang INT NOT NULL,
    tieu_de VARCHAR(160) NOT NULL,
    noi_dung TEXT NOT NULL,
    thoi_diem_dang DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ghim BOOLEAN NOT NULL DEFAULT 0 CHECK (ghim IN (0,1)),
    FOREIGN KEY (ma_lop) REFERENCES LopHoc(ma_lop),
    FOREIGN KEY (ma_nguoi_dang) REFERENCES NguoiDung(ma_nguoi_dung)
) ENGINE=InnoDB;

CREATE TABLE ThanhToan (
    ma_thanh_toan INT PRIMARY KEY AUTO_INCREMENT,
    ma_dang_ky INT NOT NULL,
    so_tien DECIMAL(12,0) NOT NULL CHECK (so_tien > 0),
    phuong_thuc ENUM('TIEN_MAT','CHUYEN_KHOAN') NOT NULL,
    ma_giao_dich VARCHAR(64) UNIQUE,
    thoi_diem DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    trang_thai ENUM('THANH_CONG','HOAN_TIEN') NOT NULL DEFAULT 'THANH_CONG',
    FOREIGN KEY (ma_dang_ky) REFERENCES DangKyLop(ma_dang_ky)
) ENGINE=InnoDB;

CREATE TABLE DanhGiaLopHoc (
    ma_dang_ky INT PRIMARY KEY,
    so_sao TINYINT UNSIGNED NOT NULL CHECK (so_sao BETWEEN 1 AND 5),
    nhan_xet TEXT,
    thoi_diem DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ma_dang_ky) REFERENCES DangKyLop(ma_dang_ky)
) ENGINE=InnoDB;

CREATE TABLE ChungChi (
    ma_chung_chi INT PRIMARY KEY AUTO_INCREMENT,
    ma_dang_ky INT NOT NULL UNIQUE,
    so_hieu VARCHAR(48) NOT NULL UNIQUE,
    ngay_cap DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    xep_loai ENUM('DAT','XUAT_SAC') NOT NULL,
    FOREIGN KEY (ma_dang_ky) REFERENCES DangKyLop(ma_dang_ky)
) ENGINE=InnoDB;

CREATE TABLE ChuDe (
    ma_chu_de INT PRIMARY KEY AUTO_INCREMENT,
    ten_chu_de VARCHAR(120) NOT NULL UNIQUE,
    mo_ta TEXT
) ENGINE=InnoDB;

CREATE TABLE BaiTap (
    ma_bai_tap INT PRIMARY KEY AUTO_INCREMENT,
    ma_code VARCHAR(30) NOT NULL,
    phien_ban SMALLINT UNSIGNED NOT NULL DEFAULT 1 CHECK (phien_ban > 0),
    tieu_de VARCHAR(160) NOT NULL,
    de_bai MEDIUMTEXT NOT NULL,
    muc_do ENUM('DE','TRUNG_BINH','KHO') NOT NULL,
    gioi_han_thoi_gian_ms INT UNSIGNED NOT NULL DEFAULT 1000 CHECK (gioi_han_thoi_gian_ms > 0),
    gioi_han_bo_nho_mb SMALLINT UNSIGNED NOT NULL DEFAULT 128 CHECK (gioi_han_bo_nho_mb > 0),
    ma_tac_gia INT NOT NULL,
    ngay_tao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (ma_code, phien_ban),
    FOREIGN KEY (ma_tac_gia) REFERENCES NguoiDung(ma_nguoi_dung)
) ENGINE=InnoDB;

CREATE TABLE BaiTapChuDe (
    ma_bai_tap INT NOT NULL,
    ma_chu_de INT NOT NULL,
    PRIMARY KEY (ma_bai_tap, ma_chu_de),
    FOREIGN KEY (ma_bai_tap) REFERENCES BaiTap(ma_bai_tap),
    FOREIGN KEY (ma_chu_de) REFERENCES ChuDe(ma_chu_de)
) ENGINE=InnoDB;

CREATE TABLE NgonNguLapTrinh (
    ma_ngon_ngu INT PRIMARY KEY AUTO_INCREMENT,
    ten VARCHAR(60) NOT NULL,
    phien_ban VARCHAR(30) NOT NULL,
    UNIQUE (ten, phien_ban)
) ENGINE=InnoDB;

CREATE TABLE BaiTapNgonNgu (
    ma_bai_tap INT NOT NULL,
    ma_ngon_ngu INT NOT NULL,
    ma_khung MEDIUMTEXT,
    PRIMARY KEY (ma_bai_tap, ma_ngon_ngu),
    FOREIGN KEY (ma_bai_tap) REFERENCES BaiTap(ma_bai_tap),
    FOREIGN KEY (ma_ngon_ngu) REFERENCES NgonNguLapTrinh(ma_ngon_ngu)
) ENGINE=InnoDB;

CREATE TABLE TestCase (
    ma_test INT PRIMARY KEY AUTO_INCREMENT,
    ma_bai_tap INT NOT NULL,
    thu_tu SMALLINT UNSIGNED NOT NULL CHECK (thu_tu > 0),
    mo_ta VARCHAR(255) NOT NULL,
    du_lieu_vao TEXT NOT NULL,
    ket_qua_mong_doi TEXT NOT NULL,
    trong_so DECIMAL(5,2) NOT NULL DEFAULT 1 CHECK (trong_so > 0),
    la_test_mau BOOLEAN NOT NULL DEFAULT 0 CHECK (la_test_mau IN (0,1)),
    UNIQUE (ma_bai_tap, thu_tu),
    FOREIGN KEY (ma_bai_tap) REFERENCES BaiTap(ma_bai_tap)
) ENGINE=InnoDB;

CREATE TABLE GiaoBai (
    ma_giao INT PRIMARY KEY AUTO_INCREMENT,
    ma_lop INT NOT NULL,
    ma_bai_tap INT NOT NULL,
    ma_bai_hoc INT,
    ma_nguoi_giao INT NOT NULL,
    thoi_diem_giao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    han_nop DATETIME NOT NULL,
    bat_buoc BOOLEAN NOT NULL DEFAULT 1 CHECK (bat_buoc IN (0,1)),
    so_lan_nop_toi_da SMALLINT UNSIGNED CHECK (so_lan_nop_toi_da > 0),
    UNIQUE (ma_lop, ma_bai_tap),
    CHECK (han_nop > thoi_diem_giao),
    FOREIGN KEY (ma_lop) REFERENCES LopHoc(ma_lop),
    FOREIGN KEY (ma_bai_tap) REFERENCES BaiTap(ma_bai_tap),
    FOREIGN KEY (ma_bai_hoc) REFERENCES BaiHoc(ma_bai_hoc),
    FOREIGN KEY (ma_lop, ma_nguoi_giao) REFERENCES PhanCongGiangDay(ma_lop, ma_giang_vien)
) ENGINE=InnoDB;

CREATE TABLE LanNop (
    ma_lan_nop BIGINT PRIMARY KEY AUTO_INCREMENT,
    ma_giao INT NOT NULL,
    ma_hoc_vien INT NOT NULL,
    ma_ngon_ngu INT NOT NULL,
    ma_nguon MEDIUMTEXT NOT NULL,
    thoi_diem_nop DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    trang_thai_cham ENUM('CHO_CHAM','DA_CHAM','LOI_BIEN_DICH') NOT NULL DEFAULT 'CHO_CHAM',
    thoi_diem_cham DATETIME(3),
    CHECK ((trang_thai_cham = 'CHO_CHAM' AND thoi_diem_cham IS NULL)
           OR (trang_thai_cham <> 'CHO_CHAM' AND thoi_diem_cham >= thoi_diem_nop
               AND thoi_diem_cham IS NOT NULL)),
    FOREIGN KEY (ma_giao) REFERENCES GiaoBai(ma_giao),
    FOREIGN KEY (ma_hoc_vien) REFERENCES NguoiDung(ma_nguoi_dung),
    FOREIGN KEY (ma_ngon_ngu) REFERENCES NgonNguLapTrinh(ma_ngon_ngu)
) ENGINE=InnoDB;

CREATE TABLE LoaiKetQua (
    ma_loai CHAR(3) PRIMARY KEY,
    ten VARCHAR(60) NOT NULL,
    mo_ta VARCHAR(255),
    la_dung BOOLEAN NOT NULL DEFAULT 0 CHECK (la_dung IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE KetQuaTest (
    ma_lan_nop BIGINT NOT NULL,
    ma_test INT NOT NULL,
    ma_loai CHAR(3) NOT NULL,
    thoi_gian_chay_ms INT UNSIGNED,
    bo_nho_kb INT UNSIGNED,
    dau_ra_thuc_te TEXT,
    PRIMARY KEY (ma_lan_nop, ma_test),
    FOREIGN KEY (ma_lan_nop) REFERENCES LanNop(ma_lan_nop),
    FOREIGN KEY (ma_test) REFERENCES TestCase(ma_test),
    FOREIGN KEY (ma_loai) REFERENCES LoaiKetQua(ma_loai)
) ENGINE=InnoDB;

CREATE TABLE NhanXetLanNop (
    ma_nhan_xet INT PRIMARY KEY AUTO_INCREMENT,
    ma_lan_nop BIGINT NOT NULL,
    ma_giang_vien INT NOT NULL,
    dong_code INT UNSIGNED CHECK (dong_code > 0),
    noi_dung TEXT NOT NULL,
    thoi_diem DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ma_lan_nop) REFERENCES LanNop(ma_lan_nop),
    FOREIGN KEY (ma_giang_vien) REFERENCES NguoiDung(ma_nguoi_dung)
) ENGINE=InnoDB;

CREATE TABLE NhatKyHeThong (
    ma_nhat_ky BIGINT PRIMARY KEY AUTO_INCREMENT,
    ten_bang VARCHAR(40) NOT NULL,
    hanh_dong ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    khoa_ban_ghi BIGINT NOT NULL,
    du_lieu_cu JSON,
    du_lieu_moi JSON,
    ma_nguoi_thuc_hien INT,
    thoi_diem DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    FOREIGN KEY (ma_nguoi_thuc_hien) REFERENCES NguoiDung(ma_nguoi_dung) ON DELETE SET NULL
) ENGINE=InnoDB;
