--=======================================================================
  --SCRIPT TẠO CƠ SỞ DỮ LIỆU SQL SERVER
  --ĐỒ ÁN: QUẢN LÝ NHÀ HÀNG ĐỒ ĂN THỨC UỐNG
  --Chạy file này TRƯỚC, sau đó chạy sql_data.sql
--=======================================================================

--YÊU CẦU: SQL Server 2019+, SSMS

--=======================================================================
--PHẦN 1: TẠO DATABASE
--=======================================================================

CREATE DATABASE QuanLyNhaHang
GO

USE QuanLyNhaHang
GO

--=======================================================================
--PHẦN 2: TẠO BẢNG (CHUẨN 3NF)
--=======================================================================

-- 2.1. DanhMuc: Phân loại món ăn (Đồ ăn, Đồ uống, Tráng miệng)
CREATE TABLE DanhMuc (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(500) NULL
)
GO

-- 2.2. MonAn: Thực đơn
CREATE TABLE MonAn (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(200) NOT NULL,
    Gia DECIMAL(18,0) NOT NULL CHECK (Gia > 0),
    MoTa NVARCHAR(500) NULL,
    HinhAnh NVARCHAR(500) NULL,
    DanhMucId INT NOT NULL,
    TrangThai BIT NOT NULL DEFAULT 1,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (DanhMucId) REFERENCES DanhMuc(Id)
)
GO

-- 2.3. Ban: Bàn ăn
CREATE TABLE Ban (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TenBan NVARCHAR(50) NOT NULL,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Còn trống'
)
GO

-- 2.4. NhanVien: Nhân viên
CREATE TABLE NhanVien (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TenDangNhap NVARCHAR(50) NOT NULL UNIQUE,
    MatKhau VARBINARY(32) NOT NULL,
    HoTen NVARCHAR(100) NOT NULL,
    VaiTro NVARCHAR(50) NOT NULL DEFAULT N'Nhân viên'
)
GO

-- 2.5. HoaDon: Hóa đơn
CREATE TABLE HoaDon (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    BanId INT NOT NULL,
    NhanVienId INT NOT NULL,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    TongTien DECIMAL(18,0) NOT NULL DEFAULT 0,
    MaGiamGia NVARCHAR(50) NULL,
    TienGiam DECIMAL(18,0) NOT NULL DEFAULT 0,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chưa thanh toán',
    FOREIGN KEY (BanId) REFERENCES Ban(Id),
    FOREIGN KEY (NhanVienId) REFERENCES NhanVien(Id)
)
GO

-- 2.6. ChiTietHoaDon: Chi tiết hóa đơn
CREATE TABLE ChiTietHoaDon (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    HoaDonId INT NOT NULL,
    MonAnId INT NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGia DECIMAL(18,0) NOT NULL CHECK (DonGia > 0),
    GhiChu NVARCHAR(500) NULL,
    ThanhTien AS (SoLuong * DonGia),
    FOREIGN KEY (HoaDonId) REFERENCES HoaDon(Id),
    FOREIGN KEY (MonAnId) REFERENCES MonAn(Id)
)
GO

-- 2.7. Voucher: Mã giảm giá
CREATE TABLE Voucher (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Ma NVARCHAR(50) NOT NULL UNIQUE,
    PhanTramGiam DECIMAL(5,2) NOT NULL CHECK (PhanTramGiam > 0 AND PhanTramGiam <= 100),
    TrangThai BIT NOT NULL DEFAULT 1
)
GO

--=======================================================================
--PHẦN 3: TẠO VIEW
--=======================================================================

-- 3.1. vw_HoaDonChiTiet: Chi tiết hóa đơn (dùng subquery thay JOIN)
CREATE VIEW vw_HoaDonChiTiet AS
SELECT
    hd.Id AS HoaDonId,
    hd.NgayTao,
    (SELECT TenBan FROM Ban WHERE Id = hd.BanId) AS TenBan,
    (SELECT HoTen FROM NhanVien WHERE Id = hd.NhanVienId) AS TenNhanVien,
    (SELECT Ten FROM MonAn WHERE Id = cthd.MonAnId) AS TenMonAn,
    cthd.SoLuong,
    cthd.DonGia,
    cthd.ThanhTien,
    hd.TongTien,
    hd.MaGiamGia,
    hd.TienGiam,
    (hd.TongTien - hd.TienGiam) AS KhachTra,
    hd.TrangThai
FROM HoaDon hd, ChiTietHoaDon cthd
WHERE hd.Id = cthd.HoaDonId
GO

-- 3.2. vw_DoanhThuTheoNgay: Doanh thu theo ngày
CREATE VIEW vw_DoanhThuTheoNgay AS
SELECT
    CAST(NgayTao AS DATE) AS Ngay,
    COUNT(DISTINCT Id) AS SoHoaDon,
    SUM(TongTien - TienGiam) AS DoanhThuThucTe
FROM HoaDon
WHERE TrangThai = N'Đã thanh toán'
GROUP BY CAST(NgayTao AS DATE)
GO

-- 3.3. vw_MonAn: Danh sách món ăn (dùng subquery thay JOIN)
CREATE VIEW vw_MonAn AS
SELECT
    ma.Id, ma.Ten AS TenMonAn,
    (SELECT Ten FROM DanhMuc WHERE Id = ma.DanhMucId) AS DanhMuc,
    ma.Gia, ma.TrangThai, ma.MoTa, ma.HinhAnh, ma.NgayTao
FROM MonAn ma
GO

--======================================================================
--PHẦN 4: TẠO STORED PROCEDURE
--=======================================================================

-- 4.1. sp_DangNhap: Xác thực đăng nhập
CREATE PROCEDURE sp_DangNhap
    @TenDangNhap NVARCHAR(50),
    @MatKhau NVARCHAR(256)
AS
BEGIN
    SELECT Id, TenDangNhap, HoTen, VaiTro
    FROM NhanVien
    WHERE TenDangNhap = @TenDangNhap AND MatKhau = HASHBYTES('SHA2_256', @MatKhau)
END
GO

-- 4.2. sp_DangKy: Đăng ký nhân viên
CREATE PROCEDURE sp_DangKy
    @TenDangNhap NVARCHAR(50),
    @MatKhau NVARCHAR(256),
    @HoTen NVARCHAR(100),
    @VaiTro NVARCHAR(50) = N'Nhân viên'
AS
BEGIN
    IF EXISTS (SELECT 1 FROM NhanVien WHERE TenDangNhap = @TenDangNhap)
    BEGIN
        RAISERROR(N'Tên đăng nhập đã tồn tại', 16, 1)
        RETURN
    END
    INSERT INTO NhanVien (TenDangNhap, MatKhau, HoTen, VaiTro)
    VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @HoTen, @VaiTro)
    SELECT SCOPE_IDENTITY() AS Id
END
GO

-- 4.3. sp_DatHang: Đặt hàng (Transaction)
CREATE PROCEDURE sp_DatHang
    @BanId INT,
    @NhanVienId INT,
    @Items NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        BEGIN TRANSACTION

        DECLARE @HoaDonId INT, @TongTien DECIMAL(18,0) = 0
        DECLARE @TrangThaiBan NVARCHAR(50)

        SELECT @TrangThaiBan = TrangThai FROM Ban WHERE Id = @BanId

        IF @TrangThaiBan = N'Còn trống'
        BEGIN
            INSERT INTO HoaDon (BanId, NhanVienId, NgayTao, TongTien, TrangThai)
            VALUES (@BanId, @NhanVienId, GETDATE(), 0, N'Chưa thanh toán')
            SET @HoaDonId = SCOPE_IDENTITY()
            UPDATE Ban SET TrangThai = N'Đang sử dụng' WHERE Id = @BanId
        END
        ELSE
        BEGIN
            SELECT TOP 1 @HoaDonId = Id FROM HoaDon
            WHERE BanId = @BanId AND TrangThai = N'Chưa thanh toán'
            ORDER BY NgayTao DESC

            IF @HoaDonId IS NULL
            BEGIN
                RAISERROR(N'Bàn đang được sử dụng nhưng không có hóa đơn nào', 16, 1)
                ROLLBACK RETURN
            END
        END

        DECLARE @Index INT = 0
        DECLARE @Count INT
        SELECT @Count = COUNT(*) FROM OPENJSON(@Items)

        WHILE @Index < @Count
        BEGIN
            DECLARE @MonAnId INT, @SoLuong INT, @DonGia DECIMAL(18,0), @TenMon NVARCHAR(200), @GhiChu NVARCHAR(500)
            SELECT
                @MonAnId = JSON_VALUE(value, '$.monAnId'),
                @SoLuong = JSON_VALUE(value, '$.soLuong'),
                @DonGia = JSON_VALUE(value, '$.donGia'),
                @GhiChu = JSON_VALUE(value, '$.ghiChu')
            FROM OPENJSON(@Items) WHERE [key] = @Index

            SELECT @TenMon = Ten FROM MonAn WHERE Id = @MonAnId AND TrangThai = 1
            IF @TenMon IS NULL
            BEGIN RAISERROR(N'Món ăn không tồn tại hoặc đã ngừng bán', 16, 1) ROLLBACK RETURN END

            INSERT INTO ChiTietHoaDon (HoaDonId, MonAnId, SoLuong, DonGia, GhiChu)
            VALUES (@HoaDonId, @MonAnId, @SoLuong, @DonGia, @GhiChu)

            SET @TongTien = @TongTien + (@SoLuong * @DonGia)
            SET @Index = @Index + 1
        END

        -- Trigger trg_ChiTietHoaDon_UpdateTongTien tự cập nhật TongTien

        COMMIT TRANSACTION
        SELECT @HoaDonId AS HoaDonId, @TongTien AS TongTien, N'Đặt hàng thành công' AS Message
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- 4.4. sp_ThanhToan: Thanh toán hóa đơn (Transaction)
CREATE PROCEDURE sp_ThanhToan
    @HoaDonId INT,
    @MaGiamGia NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        BEGIN TRANSACTION
        IF NOT EXISTS (SELECT 1 FROM HoaDon WHERE Id = @HoaDonId AND TrangThai = N'Chưa thanh toán')
        BEGIN RAISERROR(N'Hóa đơn không tồn tại hoặc đã thanh toán', 16, 1) ROLLBACK RETURN END

        DECLARE @TienGiam DECIMAL(18,0) = 0

        -- Kiểm tra voucher nếu có mã giảm giá
        IF @MaGiamGia IS NOT NULL AND @MaGiamGia <> N''
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM Voucher
                WHERE Ma = @MaGiamGia AND TrangThai = 1
            )
            BEGIN RAISERROR(N'Mã giảm giá không hợp lệ hoặc đã bị tắt', 16, 1) ROLLBACK RETURN END

            DECLARE @PhanTramGiam DECIMAL(5,2), @TongTienHD DECIMAL(18,0)
            SELECT @PhanTramGiam = PhanTramGiam FROM Voucher WHERE Ma = @MaGiamGia
            SELECT @TongTienHD = TongTien FROM HoaDon WHERE Id = @HoaDonId

            SET @TienGiam = @TongTienHD * @PhanTramGiam / 100
        END

        DECLARE @BanId INT
        SELECT @BanId = BanId FROM HoaDon WHERE Id = @HoaDonId
        UPDATE HoaDon SET TrangThai = N'Đã thanh toán', MaGiamGia = @MaGiamGia, TienGiam = @TienGiam
        WHERE Id = @HoaDonId
        UPDATE Ban SET TrangThai = N'Còn trống' WHERE Id = @BanId
        COMMIT TRANSACTION
        SELECT N'Thanh toán thành công' AS Message, @TienGiam AS TienGiam
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- 4.5. sp_KiemTraVoucher: Kiểm tra mã giảm giá
CREATE PROCEDURE sp_KiemTraVoucher
    @Ma NVARCHAR(50),
    @TongTien DECIMAL(18,0)
AS
BEGIN
    SET NOCOUNT ON
    IF NOT EXISTS (SELECT 1 FROM Voucher WHERE Ma = @Ma AND TrangThai = 1)
    BEGIN
        SELECT N'Không hợp lệ' AS TrangThai, NULL AS PhanTramGiam, NULL AS TienGiam
        RETURN
    END
    DECLARE @PhanTramGiam DECIMAL(5,2), @TienGiam DECIMAL(18,0)
    SELECT @PhanTramGiam = PhanTramGiam FROM Voucher WHERE Ma = @Ma
    SET @TienGiam = @TongTien * @PhanTramGiam / 100
    SELECT N'Hợp lệ' AS TrangThai, @PhanTramGiam AS PhanTramGiam, @TienGiam AS TienGiam
END
GO

-- 4.6. sp_ThongKeDoanhThu: Thống kê doanh thu (dùng subquery thay JOIN)
CREATE PROCEDURE sp_ThongKeDoanhThu
    @TuNgay DATE,
    @DenNgay DATE
AS
BEGIN
    SELECT
        Ngay,
        COUNT(*) AS SoHoaDon,
        SUM(TongTien) AS DoanhThu,
        SUM(SoMonDaBan) AS SoMonDaBan
    FROM (
        SELECT
            CAST(hd.NgayTao AS DATE) AS Ngay,
            hd.TongTien,
            (SELECT SUM(SoLuong) FROM ChiTietHoaDon WHERE HoaDonId = hd.Id) AS SoMonDaBan
        FROM HoaDon hd
        WHERE hd.TrangThai = N'Đã thanh toán'
            AND CAST(hd.NgayTao AS DATE) BETWEEN @TuNgay AND @DenNgay
    ) sub
    GROUP BY Ngay
    ORDER BY Ngay
END
GO

-- 4.7. sp_MonBanChay: Top món bán chạy (dùng subquery thay JOIN)
CREATE PROCEDURE sp_MonBanChay
    @TuNgay DATE,
    @DenNgay DATE
AS
BEGIN
    SELECT TOP 10
        ma.Id, ma.Ten,
        (SELECT Ten FROM DanhMuc WHERE Id = ma.DanhMucId) AS DanhMuc,
        SUM(cthd.SoLuong) AS TongSoLuong,
        SUM(cthd.ThanhTien) AS TongDoanhThu
    FROM ChiTietHoaDon cthd, HoaDon hd, MonAn ma
    WHERE cthd.HoaDonId = hd.Id
        AND cthd.MonAnId = ma.Id
        AND hd.TrangThai = N'Đã thanh toán'
        AND CAST(hd.NgayTao AS DATE) BETWEEN @TuNgay AND @DenNgay
    GROUP BY ma.Id, ma.Ten, ma.DanhMucId
    ORDER BY TongSoLuong DESC
END
GO

-- 4.8. sp_HoaDonChuaThanhToan: DS hóa đơn chưa thanh toán (dùng subquery thay JOIN)
CREATE PROCEDURE sp_HoaDonChuaThanhToan
AS
BEGIN
    SELECT
        hd.Id, hd.NgayTao,
        (SELECT TenBan FROM Ban WHERE Id = hd.BanId) AS TenBan,
        (SELECT HoTen FROM NhanVien WHERE Id = hd.NhanVienId) AS TenNhanVien,
        hd.TongTien, hd.MaGiamGia, hd.TienGiam, hd.TrangThai
    FROM HoaDon hd
    WHERE hd.TrangThai = N'Chưa thanh toán'
    ORDER BY hd.NgayTao DESC
END
GO

-- 4.9. sp_ChiTietHoaDon: Chi tiết hóa đơn (dùng subquery thay JOIN)
CREATE PROCEDURE sp_ChiTietHoaDon
    @HoaDonId INT
AS
BEGIN
    SELECT
        cthd.Id,
        cthd.MonAnId,
        (SELECT Ten FROM MonAn WHERE Id = cthd.MonAnId) AS TenMonAn,
        cthd.SoLuong, cthd.DonGia, cthd.ThanhTien, cthd.GhiChu
    FROM ChiTietHoaDon cthd
    WHERE cthd.HoaDonId = @HoaDonId
END
GO

-- 4.10. sp_ThemMonAn: Thêm món ăn
CREATE PROCEDURE sp_ThemMonAn
    @Ten NVARCHAR(200), @Gia DECIMAL(18,0),
    @MoTa NVARCHAR(500) = NULL, @HinhAnh NVARCHAR(500) = NULL,
    @DanhMucId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM MonAn WHERE Ten = @Ten)
    BEGIN RAISERROR(N'Tên món ăn đã tồn tại', 16, 1) RETURN END
    INSERT INTO MonAn (Ten, Gia, MoTa, HinhAnh, DanhMucId)
    VALUES (@Ten, @Gia, @MoTa, @HinhAnh, @DanhMucId)
    SELECT SCOPE_IDENTITY() AS Id
END
GO

-- 4.11. sp_CapNhatMonAn: Cập nhật món ăn
CREATE PROCEDURE sp_CapNhatMonAn
    @Id INT, @Ten NVARCHAR(200) = NULL, @Gia DECIMAL(18,0) = NULL,
    @MoTa NVARCHAR(500) = NULL, @HinhAnh NVARCHAR(500) = NULL,
    @DanhMucId INT = NULL, @TrangThai BIT = NULL
AS
BEGIN
    IF @Ten IS NOT NULL AND EXISTS (SELECT 1 FROM MonAn WHERE Ten = @Ten AND Id <> @Id)
    BEGIN RAISERROR(N'Tên món ăn đã tồn tại', 16, 1) RETURN END
    UPDATE MonAn SET
        Ten = ISNULL(@Ten, Ten), Gia = ISNULL(@Gia, Gia),
        MoTa = ISNULL(@MoTa, MoTa), HinhAnh = ISNULL(@HinhAnh, HinhAnh),
        DanhMucId = ISNULL(@DanhMucId, DanhMucId),
        TrangThai = ISNULL(@TrangThai, TrangThai)
    WHERE Id = @Id
END
GO

-- 4.12. sp_XoaMonAn: Xóa món ăn (xóa thật)
CREATE PROCEDURE sp_XoaMonAn
    @Id INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM ChiTietHoaDon cthd
        WHERE cthd.MonAnId = @Id
        AND EXISTS (SELECT 1 FROM HoaDon hd WHERE hd.Id = cthd.HoaDonId AND hd.TrangThai = N'Chưa thanh toán'))
    BEGIN RAISERROR(N'Không thể xóa món đang có trong hóa đơn chưa thanh toán', 16, 1) RETURN END
    DELETE FROM ChiTietHoaDon WHERE MonAnId = @Id
    DELETE FROM MonAn WHERE Id = @Id
END
GO

-- 4.13. sp_VoucherList: Danh sách voucher
CREATE PROCEDURE sp_VoucherList
AS
BEGIN
    SELECT Id, Ma, PhanTramGiam, TrangThai
    FROM Voucher ORDER BY Id DESC
END
GO

-- 4.14. sp_VoucherAdd: Thêm voucher
CREATE PROCEDURE sp_VoucherAdd
    @Ma NVARCHAR(50), @PhanTramGiam DECIMAL(5,2)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Voucher WHERE Ma = @Ma)
    BEGIN RAISERROR(N'Mã voucher đã tồn tại', 16, 1) RETURN END
    INSERT INTO Voucher (Ma, PhanTramGiam) VALUES (@Ma, @PhanTramGiam)
    SELECT SCOPE_IDENTITY() AS Id
END
GO

-- 4.15. sp_VoucherUpdate: Cập nhật voucher
CREATE PROCEDURE sp_VoucherUpdate
    @Id INT, @Ma NVARCHAR(50), @PhanTramGiam DECIMAL(5,2)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Voucher WHERE Ma = @Ma AND Id <> @Id)
    BEGIN RAISERROR(N'Mã voucher đã tồn tại', 16, 1) RETURN END
    UPDATE Voucher SET Ma = @Ma, PhanTramGiam = @PhanTramGiam WHERE Id = @Id
END
GO

-- 4.16. sp_VoucherToggle: Bật/tắt voucher
CREATE PROCEDURE sp_VoucherToggle
    @Id INT
AS
BEGIN
    UPDATE Voucher SET TrangThai = CASE WHEN TrangThai = 1 THEN 0 ELSE 1 END WHERE Id = @Id
END
GO

-- 4.17. sp_VoucherDelete: Xóa voucher
CREATE PROCEDURE sp_VoucherDelete
    @Id INT
AS
BEGIN
    DELETE FROM Voucher WHERE Id = @Id
END
GO

-- 4.18. sp_XoaBan: Xóa bàn (có transaction, xóa HoaDon + ChiTietHoaDon trước)
CREATE PROCEDURE sp_XoaBan
    @Id INT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        BEGIN TRANSACTION
        IF EXISTS (SELECT 1 FROM HoaDon WHERE BanId = @Id AND TrangThai = N'Chưa thanh toán')
        BEGIN
            RAISERROR(N'Không thể xóa bàn đang có hóa đơn chưa thanh toán', 16, 1)
            ROLLBACK RETURN
        END
        DELETE FROM ChiTietHoaDon WHERE HoaDonId IN (SELECT Id FROM HoaDon WHERE BanId = @Id)
        DELETE FROM HoaDon WHERE BanId = @Id
        DELETE FROM Ban WHERE Id = @Id
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrMsg, 16, 1)
    END CATCH
END
GO

-- 4.19. sp_NhanVienList: Danh sách nhân viên (không trả về mật khẩu)
CREATE PROCEDURE sp_NhanVienList
AS
BEGIN
    SELECT Id, TenDangNhap, HoTen, VaiTro FROM NhanVien ORDER BY Id
END
GO

-- 4.20. sp_NhanVienAdd: Thêm nhân viên
CREATE PROCEDURE sp_NhanVienAdd
    @TenDangNhap NVARCHAR(50), @MatKhau NVARCHAR(256),
    @HoTen NVARCHAR(100), @VaiTro NVARCHAR(50) = N'Nhân viên'
AS
BEGIN
    IF EXISTS (SELECT 1 FROM NhanVien WHERE TenDangNhap = @TenDangNhap)
    BEGIN RAISERROR(N'Tên đăng nhập đã tồn tại', 16, 1) RETURN END
    INSERT INTO NhanVien (TenDangNhap, MatKhau, HoTen, VaiTro)
    VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @HoTen, @VaiTro)
    SELECT SCOPE_IDENTITY() AS Id
END
GO

-- 4.21. sp_NhanVienUpdate: Cập nhật nhân viên
CREATE PROCEDURE sp_NhanVienUpdate
    @Id INT, @TenDangNhap NVARCHAR(50),
    @MatKhau NVARCHAR(256) = NULL,
    @HoTen NVARCHAR(100), @VaiTro NVARCHAR(50)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM NhanVien WHERE TenDangNhap = @TenDangNhap AND Id <> @Id)
    BEGIN RAISERROR(N'Tên đăng nhập đã tồn tại', 16, 1) RETURN END
    IF @MatKhau IS NOT NULL AND @MatKhau <> N''
        UPDATE NhanVien SET TenDangNhap = @TenDangNhap, MatKhau = HASHBYTES('SHA2_256', @MatKhau),
            HoTen = @HoTen, VaiTro = @VaiTro WHERE Id = @Id
    ELSE
        UPDATE NhanVien SET TenDangNhap = @TenDangNhap, HoTen = @HoTen, VaiTro = @VaiTro WHERE Id = @Id
END
GO

-- 4.22. sp_NhanVienDelete: Xóa nhân viên
CREATE PROCEDURE sp_NhanVienDelete
    @Id INT
AS
BEGIN
    IF @Id = 1 BEGIN RAISERROR(N'Không thể xóa tài khoản admin', 16, 1) RETURN END
    DELETE FROM NhanVien WHERE Id = @Id
END
GO

--=======================================================================
--PHẦN 5: TẠO TRIGGER
--=======================================================================

CREATE TRIGGER trg_ChiTietHoaDon_UpdateTongTien
ON ChiTietHoaDon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @HoaDonId INT
    SELECT TOP 1 @HoaDonId = HoaDonId FROM inserted
    IF @HoaDonId IS NULL SELECT TOP 1 @HoaDonId = HoaDonId FROM deleted
    UPDATE HoaDon SET TongTien = ISNULL(
        (SELECT SUM(SoLuong * DonGia) FROM ChiTietHoaDon WHERE HoaDonId = @HoaDonId), 0)
    WHERE Id = @HoaDonId
END
GO

--=======================================================================
--PHẦN 6: HƯỚNG DẪN TẠO USER
--=======================================================================

-- Chạy sau khi tạo xong database: 
 USE QuanLyNhaHang
 GO
 CREATE LOGIN ql_tamthoi WITH PASSWORD = '123456'
 GO
 CREATE USER  quanlytamthoi FOR LOGIN ql_tamthoi
 GO
-- Cấp quyền tối thiểu
 GRANT SELECT, INSERT, UPDATE, DELETE ON DanhMuc TO quanlytamthoi
 GRANT SELECT, INSERT, UPDATE, DELETE ON MonAn TO quanlytamthoi
 GRANT SELECT, INSERT, UPDATE ON Ban TO quanlytamthoi
 GRANT SELECT, INSERT, UPDATE ON NhanVien TO quanlytamthoi
 GRANT SELECT, INSERT, UPDATE ON HoaDon TO quanlytamthoi
 GRANT SELECT, INSERT, DELETE ON ChiTietHoaDon TO quanlytamthoi
 GRANT SELECT, INSERT, UPDATE ON Voucher TO quanlytamthoi
-- Cấp quyền thực thi SP
 GRANT EXECUTE ON sp_DangNhap TO quanlytamthoi
 GRANT EXECUTE ON sp_DangKy TO quanlytamthoi
 GRANT EXECUTE ON sp_DatHang TO quanlytamthoi
 GRANT EXECUTE ON sp_ThanhToan TO quanlytamthoi
 GRANT EXECUTE ON sp_KiemTraVoucher TO quanlytamthoi
 GRANT EXECUTE ON sp_ThongKeDoanhThu TO quanlytamthoi
 GRANT EXECUTE ON sp_MonBanChay TO quanlytamthoi
 GRANT EXECUTE ON sp_HoaDonChuaThanhToan TO quanlytamthoi
 GRANT EXECUTE ON sp_ChiTietHoaDon TO quanlytamthoi
 GRANT EXECUTE ON sp_ThemMonAn TO quanlytamthoi
 GRANT EXECUTE ON sp_CapNhatMonAn TO quanlytamthoi
 GRANT EXECUTE ON sp_XoaMonAn TO quanlytamthoi
 GRANT EXECUTE ON sp_VoucherList TO quanlytamthoi
 GRANT EXECUTE ON sp_VoucherAdd TO quanlytamthoi
 GRANT EXECUTE ON sp_VoucherUpdate TO quanlytamthoi
 GRANT EXECUTE ON sp_VoucherToggle TO quanlytamthoi
 GRANT EXECUTE ON sp_VoucherDelete TO quanlytamthoi
 GRANT EXECUTE ON sp_XoaBan TO quanlytamthoi
 GRANT EXECUTE ON sp_NhanVienList TO quanlytamthoi
 GRANT EXECUTE ON sp_NhanVienAdd TO quanlytamthoi
 GRANT EXECUTE ON sp_NhanVienUpdate TO quanlytamthoi
 GRANT EXECUTE ON sp_NhanVienDelete TO quanlytamthoi
-- Cấp quyền View
 GRANT SELECT ON vw_HoaDonChiTiet TO quanlytamthoi
 GRANT SELECT ON vw_DoanhThuTheoNgay TO quanlytamthoi
 GRANT SELECT ON vw_MonAn TO quanlytamthoi
 GO

PRINT N'TẠO DATABASE THÀNH CÔNG!'
PRINT N'Database: QuanLyNhaHang'
PRINT N'Tiếp theo: Chạy file sql_data.sql để thêm dữ liệu mẫu'
GO
