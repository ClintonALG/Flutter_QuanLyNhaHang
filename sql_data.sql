--=======================================================================
--  SCRIPT THÊM DỮ LIỆU MẪU CHO SQL SERVER
--  ĐỒ ÁN: QUẢN LÝ NHÀ HÀNG ĐỒ ĂN THỨC UỐNG
--  Chạy SAU khi đã chạy sql_create.sql
--=======================================================================

USE QuanLyNhaHang
GO

-- Lưu ý: HinhAnh để NULL - bạn sẽ upload ảnh thủ công qua web admin sau

-- ===================================================================
-- 1. DANH MỤC
-- ===================================================================
INSERT INTO DanhMuc (Ten, MoTa) VALUES
(N'Đồ ăn', N'Các món ăn chính'),
(N'Đồ uống', N'Các loại thức uống'),
(N'Tráng miệng', N'Các món tráng miệng')
GO

-- ===================================================================
-- 3. BÀN ĂN
-- ===================================================================
INSERT INTO Ban (TenBan, TrangThai) VALUES
(N'Bàn 1', N'Còn trống'), (N'Bàn 2', N'Còn trống'),
(N'Bàn 3', N'Còn trống'), (N'Bàn 4', N'Còn trống'),
(N'Bàn 5', N'Còn trống'), (N'Bàn 6', N'Còn trống'),
(N'Bàn 7', N'Còn trống'), (N'Bàn 8', N'Còn trống'),
(N'Bàn 9', N'Còn trống'), (N'Bàn 10', N'Còn trống'),
(N'Bàn 11', N'Còn trống'), (N'Bàn 12', N'Còn trống'),
(N'Bàn 13', N'Còn trống'), (N'Bàn 14', N'Còn trống'),
(N'Bàn 15', N'Còn trống')
GO

-- ===================================================================
-- 4. NHÂN VIÊN (mật khẩu: 123456 -> SHA256)
-- ===================================================================
INSERT INTO NhanVien (TenDangNhap, MatKhau, HoTen, VaiTro) VALUES
(N'admin', HASHBYTES('SHA2_256', N'123456'), N'Quản trị viên', N'Quản lý'),
(N'nhanvien1', HASHBYTES('SHA2_256', N'123456'), N'Nguyễn Văn A', N'Nhân viên'),
(N'nhanvien2', HASHBYTES('SHA2_256', N'123456'), N'Trần Thị B', N'Nhân viên')
GO

-- ===================================================================
-- 5. VOUCHER (mã giảm giá)
-- ===================================================================
INSERT INTO Voucher (Ma, PhanTramGiam) VALUES
(N'WELCOME10', 10.00),
(N'GIAM20', 20.00),
(N'FREESHIP', 5.00),
(N'HE2026', 15.00),
(N'NOEL', 25.00)
GO

PRINT N'THÊM DỮ LIỆU MẪU THÀNH CÔNG!'
PRINT N'Tài khoản mẫu: admin/123456, nhanvien1/123456, nhanvien2/123456'
PRINT N'Voucher mẫu: WELCOME10 (-10%), GIAM20 (-20%), FREESHIP (-5%), HE2026 (-15%), NOEL (-25%)'
PRINT N'Món ăn: Thêm thủ công qua giao diện web admin'
GO
