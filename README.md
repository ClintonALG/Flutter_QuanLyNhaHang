# QUẢN LÝ NHÀ HÀNG - AMORE PIZZA

Đồ án Lập trình Di động - Nhóm 3

## Kiến trúc hệ thống

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Flutter App     │────▶│  Node.js API     │────▶│  SQL Server      │
│  (Mobile/Web)    │     │  (Port 3000)     │     │  (Database)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
┌─────────────────┐          ▲
│  Web Admin       │──────────┘
│  (HTML/CSS/JS)   │
└─────────────────┘
```

## Công nghệ sử dụng

| Công nghệ | Mục đích |
|-----------|----------|
| **Flutter (Dart)** | Ứng dụng di động (Android) + Web |
| **Node.js/Express** | Backend API REST (cổng 3000) |
| **SQL Server 2019+** | Cơ sở dữ liệu quan hệ |
| **HTML/CSS/JS** | Web Admin Panel |
| **Chart.js** | Biểu đồ thống kê doanh thu |

## Cài đặt & Chạy (từng bước)

### Bước 1: Tạo Database

1. Mở **SQL Server Management Studio (SSMS)**
2. Đăng nhập với tài khoản `sa`
3. Mở file **`sql_create.sql`** → chạy toàn bộ (tạo database, bảng, view, stored procedure, trigger)
4. Mở file **`sql_data.sql`** → chạy toàn bộ (chèn dữ liệu mẫu: danh mục, bàn, nhân viên, voucher)

### Bước 2: Tạo user riêng (bắt buộc theo thang điểm)

Chạy script sau trong SSMS (thay thế việc dùng tài khoản `sa`):

```sql
USE QuanLyNhaHang
GO

CREATE LOGIN ql_tamthoi WITH PASSWORD = '123456';
CREATE USER quanlytamthoi FOR LOGIN ql_tamthoi;

GRANT SELECT, INSERT, UPDATE, DELETE ON Ban TO quanlytamthoi;
GRANT SELECT, INSERT, UPDATE, DELETE ON MonAn TO quanlytamthoi;
GRANT SELECT, INSERT, UPDATE, DELETE ON DanhMuc TO quanlytamthoi;
GRANT SELECT, INSERT, UPDATE, DELETE ON HoaDon TO quanlytamthoi;
GRANT SELECT, INSERT, UPDATE, DELETE ON ChiTietHoaDon TO quanlytamthoi;
GRANT SELECT, INSERT, UPDATE, DELETE ON NhanVien TO quanlytamthoi;
GRANT SELECT, INSERT, UPDATE, DELETE ON Voucher TO quanlytamthoi;

GRANT EXECUTE ON sp_DangNhap TO quanlytamthoi;
GRANT EXECUTE ON sp_DangKy TO quanlytamthoi;
GRANT EXECUTE ON sp_DatHang TO quanlytamthoi;
GRANT EXECUTE ON sp_ThanhToan TO quanlytamthoi;
GRANT EXECUTE ON sp_KiemTraVoucher TO quanlytamthoi;
GRANT EXECUTE ON sp_ThongKeDoanhThu TO quanlytamthoi;
GRANT EXECUTE ON sp_MonBanChay TO quanlytamthoi;
GRANT EXECUTE ON sp_HoaDonChuaThanhToan TO quanlytamthoi;
GRANT EXECUTE ON sp_ChiTietHoaDon TO quanlytamthoi;
GRANT EXECUTE ON sp_ThemMonAn TO quanlytamthoi;
GRANT EXECUTE ON sp_CapNhatMonAn TO quanlytamthoi;
GRANT EXECUTE ON sp_XoaMonAn TO quanlytamthoi;
GRANT EXECUTE ON sp_VoucherList TO quanlytamthoi;
GRANT EXECUTE ON sp_VoucherAdd TO quanlytamthoi;
GRANT EXECUTE ON sp_VoucherUpdate TO quanlytamthoi;
GRANT EXECUTE ON sp_VoucherToggle TO quanlytamthoi;
GRANT EXECUTE ON sp_NhanVienList TO quanlytamthoi;
GRANT EXECUTE ON sp_NhanVienAdd TO quanlytamthoi;
GRANT EXECUTE ON sp_NhanVienUpdate TO quanlytamthoi;
GRANT EXECUTE ON sp_NhanVienDelete TO quanlytamthoi;

GRANT SELECT ON vw_HoaDonChiTiet TO quanlytamthoi;
GRANT SELECT ON vw_DoanhThuTheoNgay TO quanlytamthoi;
GRANT SELECT ON vw_MonAn TO quanlytamthoi;
GO
```

### Bước 3: Cấu hình kết nối

Sửa file **`menu-api/appsettings.json`**:

```json
{
  "ConnectionStrings": {
    "QuanLyNhaHang": "Server=localhost;Database=QuanLyNhaHang;User ID=ql_tamthoi;Password=123456;Encrypt=False;TrustServerCertificate=True"
  }
}
```

> Nếu muốn dùng `sa` để test nhanh: `Server=localhost;Database=QuanLyNhaHang;User ID=sa;Password=123456;Encrypt=False;TrustServerCertificate=True`

### Bước 4: Chạy Backend (Node.js)

```bash
cd menu-api
npm install
npm start
```

Server chạy tại `http://localhost:3000` — kiểm tra bằng `http://localhost:3000/api/menu`

> Khi sửa code backend (server.js, routes/*.js) → **restart server** (Ctrl+C → `npm start`)

### Bước 5: Chạy Web Admin

Mở trình duyệt: **http://localhost:3000/admin/**

Đăng nhập: `admin` / `123456`

> **Không mở file .html trực tiếp bằng trình duyệt (file://)** — sẽ bị lỗi CORS. Phải dùng URL `http://localhost:3000/admin/`

### Bước 6: Chạy Flutter App

```bash
cd food_manager_project
flutter pub get
flutter run
```

> Android emulator dùng `10.0.2.2:3000`, Web/iOS dùng `localhost:3000`

### Chạy qua LAN/WAN (demo trên điện thoại thật)

1. Tìm IP máy chủ: `ipconfig` → `IPv4 Address` (VD: `192.168.1.10`)
2. Mở port 3000 trên firewall: `netsh advfirewall firewall add rule name="NodeJS" dir=in action=allow protocol=TCP localport=3000`
3. Sửa **Flutter** (`api_service.dart`):
   ```dart
   static const bool useLan = true;
   static const String lanIp = '192.168.1.10'; // IP máy bạn
   ```
4. Sửa **Web Admin** (`js/config.js`):
   ```js
   const USE_LAN = true;
   const LAN_IP = '192.168.1.10';
   ```
5. Điện thoại và PC cùng WiFi → mở app/web là chạy
6. Muốn về local: đổi `true` → `false` ở cả 2 file

## Tài khoản mẫu

| Tài khoản | Mật khẩu | Vai trò |
|-----------|----------|---------|
| admin | 123456 | Quản lý |
| nhanvien1 | 123456 | Nhân viên |
| nhanvien2 | 123456 | Nhân viên |

## Mã Voucher mẫu

| Mã | Giảm |
|----|------|
| WELCOME10 | 10% |
| GIAM20 | 20% |
| FREESHIP | 5% |
| HE2026 | 15% |
| NOEL | 25% |

## Cấu trúc thư mục

```
Nhom3_DT2/
├── sql_create.sql                  # Script tạo CSDL (bảng, SP, view, trigger)
├── sql_data.sql                    # Dữ liệu mẫu (danh mục, bàn, nhân viên, voucher)
├── AGENTS.md                       # Hướng dẫn setup SQL + lưu ý kỹ thuật
├── THANG ĐIỂM CHẤM ĐỒ ÁN.txt       # Rubric chấm điểm đồ án
├── DANH_SACH_CHUC_NANG.md          # Danh sách chi tiết các chức năng
│
├── food_manager_project/           # Flutter App (Mobile + Web)
│   └── lib/
│       ├── main.dart
│       ├── screens/
│       │   ├── login_screen.dart
│       │   ├── home_screen.dart
│       │   ├── food_menu_screen.dart
│       │   ├── dsban_screen.dart
│       │   ├── CreateOrder_Screen.dart
│       │   ├── SavedInvoicesScreen.dart
│       │   └── kitchen_screen.dart
│       ├── service/
│       │   └── api_service.dart    # HTTP client gọi API backend
│       └── models/
│           └── order_item.dart     # Model món ăn trong giỏ hàng
│
├── menu-api/                       # Backend Node.js
│   ├── server.js                   # Entry point + tất cả API routes
│   ├── db.js                       # Kết nối SQL Server (connection pool)
│   ├── appsettings.json            # Chuỗi kết nối database
│   └── routes/
│       ├── menuRoutes.js           # CRUD món ăn
│       └── analyticsRoutes.js      # Thống kê doanh thu
│
└── Project_Food_Admin/             # Web Admin Panel
    ├── login.html                  # Đăng nhập
    ├── index.html                  # Trang chủ
    ├── functions/
    │   ├── DisplayFood.html        # Quản lý món ăn
    │   ├── TableManagement.html    # Quản lý bàn
    │   ├── Analytics.html          # Thống kê
    │   ├── VoucherManagement.html  # Quản lý voucher
    │   └── EmployeeManagement.html # Quản lý nhân viên
    └── js/
        ├── config.js               # Cấu hình LAN/local
        ├── auth.js                 # Xác thực web
        ├── sidebar.js              # Sidebar navigation
        ├── Analytics/
        │   ├── detailAnalytics.js  # Biểu đồ + chi tiết
        │   ├── totalProduct.js     # Tổng món
        │   └── totalSold.js        # Tổng đã bán
        └── DisplayFood/
            ├── loadMenu.js         # Load danh sách món
            ├── search.js           # Tìm kiếm
            ├── category.js         # Lọc danh mục
            ├── selectAll.js        # Chọn tất cả
            ├── addProduct.js       # Thêm/sửa món
            └── deleteProduct.js    # Xóa món
```

## Database Schema

### Bảng
| Bảng | Mô tả |
|------|-------|
| **DanhMuc** | Phân loại món (Đồ ăn, Đồ uống, Tráng miệng) |
| **MonAn** | Thực đơn (liên kết DanhMuc, có TrangThai BIT) |
| **Ban** | Bàn ăn (có TrangThai: Còn trống / Đang sử dụng) |
| **NhanVien** | Nhân viên (mật khẩu SHA-256) |
| **HoaDon** | Hóa đơn (có MaGiamGia, TienGiam, TrangThai) |
| **ChiTietHoaDon** | Chi tiết hóa đơn (liên kết HoaDon, MonAn) |
| **Voucher** | Mã giảm giá (Ma, PhanTramGiam, TrangThai) |

### Stored Procedures (20 SP)
| SP | Chức năng |
|----|-----------|
| sp_DangNhap / sp_DangKy | Đăng nhập / Đăng ký |
| sp_DatHang | Đặt hàng (có Transaction) — hỗ trợ thêm món vào hóa đơn đang có |
| sp_ThanhToan | Thanh toán + voucher (có Transaction) |
| sp_KiemTraVoucher | Kiểm tra mã giảm giá |
| sp_ThongKeDoanhThu | Thống kê doanh thu |
| sp_MonBanChay | Món bán chạy |
| sp_HoaDonChuaThanhToan | Hóa đơn chưa thanh toán |
| sp_ChiTietHoaDon | Chi tiết hóa đơn |
| sp_ThemMonAn / CapNhat / Xoa | CRUD món ăn |
| sp_VoucherList / Add / Update / Toggle | CRUD voucher |
| sp_NhanVienList / Add / Update / Delete | CRUD nhân viên |

### Views
| View | Chức năng |
|------|-----------|
| vw_HoaDonChiTiet | Hóa đơn kèm KhachTra |
| vw_DoanhThuTheoNgay | Doanh thu theo ngày |
| vw_MonAn | Danh sách món (kèm tên danh mục) |

### Trigger
| Trigger | Chức năng |
|---------|-----------|
| trg_ChiTietHoaDon_UpdateTongTien | Tự động tính tổng khi thêm/xóa/sửa ChiTietHoaDon |

## API Endpoints

### Thực đơn
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/menu` | Danh sách món ăn |
| POST | `/api/menu` | Thêm món ăn |
| PUT | `/api/menu/:id` | Sửa món ăn |
| DELETE | `/api/menu/:id` | Xóa món ăn (hard-delete) |
| POST | `/api/menu/upload` | Upload ảnh món ăn |

### Xác thực
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/login` | Đăng nhập |
| POST | `/api/register` | Đăng ký |

### Bàn ăn
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/tables` | Danh sách bàn |
| POST | `/api/tables` | Thêm bàn |
| PUT | `/api/tables/:id` | Cập nhật trạng thái bàn |
| PUT | `/api/tables/:id/rename` | Đổi chỗ 2 bàn (swap tên + trạng thái + hóa đơn) |
| DELETE | `/api/tables/:id` | Xóa bàn (kiểm tra hóa đơn tồn tại) |

### Đặt hàng & Thanh toán
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/orders` | Đặt hàng (Transaction) |
| POST | `/api/payment` | Thanh toán (Transaction) |
| POST | `/api/vouchers/check` | Kiểm tra mã giảm giá |

### Hóa đơn
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/invoices?status=` | Danh sách hóa đơn (lọc theo trạng thái) |
| GET | `/api/invoices/:id` | Chi tiết hóa đơn |

### Voucher
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/vouchers` | Danh sách voucher |
| POST | `/api/vouchers` | Thêm voucher |
| PUT | `/api/vouchers/:id` | Sửa voucher |
| PUT | `/api/vouchers/:id/toggle` | Bật/tắt voucher |
| DELETE | `/api/vouchers/:id` | Xóa voucher |

### Nhân viên
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/employees` | Danh sách nhân viên |
| POST | `/api/employees` | Thêm nhân viên |
| PUT | `/api/employees/:id` | Sửa nhân viên |
| DELETE | `/api/employees/:id` | Xóa nhân viên |

### Thống kê
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/revenue` | Doanh thu theo khoảng ngày |
| GET | `/api/revenue-all` | Tất cả doanh thu (không filter) |
| GET | `/api/products-sold` | Tổng số món đã bán |
| GET | `/api/detail-revenue` | Chi tiết doanh thu theo ngày/tháng |
| GET | `/api/best-selling` | Món bán chạy |

### Danh mục
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/categories` | Danh sách danh mục |

## Lưu ý cuối

- **Đã fix**: SQL injection (dùng parameterized query thay string interpolation)
- **Đã fix**: `sp_DatHang` cho phép thêm món vào hóa đơn đang có (không cần tạo đơn mới)
- **Đã fix**: Kết nối bảo mật (dùng user `ql_tamthoi`, không dùng `sa`)

## Tổng số chức năng: ~21 chức năng

Xem chi tiết tại [DANH_SACH_CHUC_NANG.md](DANH_SACH_CHUC_NANG.md)
