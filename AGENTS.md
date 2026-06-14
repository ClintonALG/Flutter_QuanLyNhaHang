# Hướng dẫn thiết lập SQL Server

## Kết nối SSMS
- **Server name**: `localhost`
- **Authentication**: **SQL Server Authentication**
- **Login**: `sa`
- **Password**: `123456`

## Tạo user riêng cho ứng dụng (bắt buộc theo thang điểm)
```sql
USE QuanLyNhaHang
GO

CREATE LOGIN app_user WITH PASSWORD = 'P@ss123';
CREATE USER app_user FOR LOGIN app_user;

-- Cấp quyền tối thiểu cho các bảng
GRANT SELECT, INSERT, UPDATE, DELETE ON Ban TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON MonAn TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON DanhMuc TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON HoaDon TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ChiTietHoaDon TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON NhanVien TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON Voucher TO app_user;

-- Cấp quyền thực thi Stored Procedure
GRANT EXECUTE ON sp_DangNhap TO app_user;
GRANT EXECUTE ON sp_DangKy TO app_user;
GRANT EXECUTE ON sp_DatHang TO app_user;
GRANT EXECUTE ON sp_ThanhToan TO app_user;
GRANT EXECUTE ON sp_KiemTraVoucher TO app_user;
GRANT EXECUTE ON sp_ThongKeDoanhThu TO app_user;
GRANT EXECUTE ON sp_MonBanChay TO app_user;
GRANT EXECUTE ON sp_HoaDonChuaThanhToan TO app_user;
GRANT EXECUTE ON sp_ChiTietHoaDon TO app_user;
GRANT EXECUTE ON sp_ThemMonAn TO app_user;
GRANT EXECUTE ON sp_CapNhatMonAn TO app_user;
GRANT EXECUTE ON sp_XoaMonAn TO app_user;
GRANT EXECUTE ON sp_VoucherList TO app_user;
GRANT EXECUTE ON sp_VoucherAdd TO app_user;
GRANT EXECUTE ON sp_VoucherUpdate TO app_user;
GRANT EXECUTE ON sp_VoucherToggle TO app_user;
GRANT EXECUTE ON sp_VoucherDelete TO app_user;
GRANT EXECUTE ON sp_XoaBan TO app_user;
GRANT EXECUTE ON sp_NhanVienList TO app_user;
GRANT EXECUTE ON sp_NhanVienAdd TO app_user;
GRANT EXECUTE ON sp_NhanVienUpdate TO app_user;
GRANT EXECUTE ON sp_NhanVienDelete TO app_user;

-- Cấp quyền trên Views
GRANT SELECT ON vw_HoaDonChiTiet TO app_user;
GRANT SELECT ON vw_DoanhThuTheoNgay TO app_user;
GRANT SELECT ON vw_MonAn TO app_user;
GO
```

## Cấu trúc Database hiện tại
- Bảng: `DanhMuc`, `MonAn` (trangThai BIT thay SoLuongTon), `Ban`, `NhanVien`, `HoaDon` (có MaGiamGia, TienGiam), `ChiTietHoaDon`, `Voucher` (chỉ có Ma, PhanTramGiam, TrangThai — không có NgayHetHan, SoTienGiamToiDa)
- Đã xóa: `NguyenLieu`, `CongThuc`
- Stored Procedures: `sp_KiemTraVoucher`, `sp_VoucherList`, `sp_VoucherAdd`, `sp_VoucherUpdate`, `sp_VoucherToggle`
- Views: `vw_HoaDonChiTiet`, `vw_DoanhThuTheoNgay`, `vw_MonAn`
- Trigger: `trg_ChiTietHoaDon_UpdateTongTien`

## Cập nhật appsettings.json
Sau khi tạo user, sửa `menu-api/appsettings.json`:
```json
{
  "ConnectionStrings": {
    "QuanLyNhaHang": "Server=localhost;Database=QuanLyNhaHang;User ID=app_user;Password=P@ss123;Encrypt=False;TrustServerCertificate=True"
  }
}
```

> **Lưu ý**: Không hardcode connection string trong code Dart. Chỉ dùng ở backend (Node.js) như hiện tại.

## Thứ tự chạy script
1. `sql_create.sql` — tạo database, bảng, view, SP, trigger
2. `sql_data.sql` — chèn dữ liệu mẫu (DanhMuc, Ban, NhanVien, Voucher — không INSERT món ăn, thêm thủ công sau)
3. Script tạo `app_user` ở trên (nếu muốn đổi từ `sa` sang user hạn chế)
