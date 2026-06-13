# Danh sách chức năng

> Cập nhật lần cuối: 10/06/2026

---

## 🟢 A. Quản lý bàn ăn (Web Admin + Mobile)

### 1. Hiển thị danh sách bàn — Mobile (`dsban_screen.dart`)
- Hiển thị tất cả bàn dạng lưới, mỗi bàn có tên + trạng thái (`Còn trống` / `Đang sử dụng`)
- Tự động refresh danh sách sau khi đặt món hoặc thanh toán
- Lọc theo trạng thái

### 2. Đặt món theo bàn — Mobile (`CreateOrder_Screen.dart`)
- Chọn bàn → chọn món từ menu → thêm vào giỏ hàng
- Tự động tính tổng tiền
- Lưu đơn hàng xuống SQL Server qua `sp_DatHang` (Transaction)
- Sau khi lưu, bàn tự động chuyển sang `Đang sử dụng`

### 3. Quản lý bàn (thêm/xóa/đổi chỗ) — Web Admin (`TableManagement.html`)
- Thêm bàn mới
- Xóa bàn (kiểm tra không còn hóa đơn chưa thanh toán mới cho xóa)
- Đổi chỗ 2 bàn: swap tên + trạng thái + hóa đơn chưa thanh toán
- Lọc, tìm kiếm bàn

---

## 🟢 B. Quản lý thực đơn (Web Admin)

### 4. CRUD món ăn — Web Admin (`DisplayFood.html`)
- Thêm món mới (tên, giá, danh mục, mô tả, hình ảnh)
- Sửa món (cùng form với thêm)
- Xóa món (hard-delete: xóa ChiTietHoaDon → xóa MonAn)
- Toggle trạng thái món (Active/Disable) không cần reload
- Tìm kiếm + lọc theo danh mục (All/Food/Drink/Combo)

### 5. Quản lý danh mục — API (`menuRoutes.js`)
- CRUD danh mục qua API

---

## 🟢 C. Đặt hàng & Thanh toán (Mobile)

### 6. Tạo đơn hàng — Mobile (`CreateOrder_Screen.dart`)
- Chọn bàn (dropdown)
- Duyệt menu, tìm kiếm, lọc danh mục
- Thêm món vào giỏ, chỉnh số lượng (+/-), xóa món
- Tự động tính tổng tiền
- Gọi `sp_DatHang` (Transaction SQL — vừa tạo HoaDon, vừa thêm ChiTietHoaDon, vừa cập nhật Ban.TrangThai)

### 7. Phiếu tạm tính — Mobile (`SavedInvoicesScreen.dart`)
- Danh sách hóa đơn chưa thanh toán (tab 1)
- Danh sách hóa đơn đã thanh toán (tab 2) — hiển thị Tổng tiền + Giảm + Thành tiền
- Tìm kiếm theo bàn/nhân viên
- Xem biên lai (receipt) chi tiết từng món
- Thanh toán: nhập mã voucher → kiểm tra → hiển thị giảm giá → xác nhận

### 8. Thanh toán — API (`server.js` + `sp_ThanhToan`)
- Gọi `sp_ThanhToan` (Transaction): cập nhật HoaDon.TrangThai = 'Đã thanh toán', reset Ban.TrangThai = 'Còn trống'
- Hỗ trợ voucher: tự động tính giảm giá và lưu MaGiamGia, TienGiam
- Xử lý lỗi: rollback nếu voucher không hợp lệ

### 9. Kiểm tra Voucher — API (`sp_KiemTraVoucher`)
- Kiểm tra mã hợp lệ: tồn tại + TrangThai = 1 (đang bật)
- Trả về phần trăm giảm và số tiền giảm
- Gọi từ Flutter trước khi thanh toán

---

## 🟢 D. Quản lý Voucher (Web Admin)

### 10. CRUD Voucher — Web Admin (`VoucherManagement.html`)
- Thêm voucher (mã + phần trăm giảm)
- Sửa voucher
- Bật/tắt voucher (toggle TrangThai)
- Xóa voucher
- Tìm kiếm voucher

---

## 🟢 E. Quản lý Nhân viên (Web Admin)

### 11. CRUD Nhân viên — Web Admin (`EmployeeManagement.html`)
- Thêm nhân viên (tên đăng nhập, mật khẩu, họ tên, vai trò)
- Sửa nhân viên
- Xóa nhân viên
- Tìm kiếm nhân viên

---

## 🟢 F. Đăng nhập & Phân quyền

### 12. Đăng nhập Web Admin (`login.html` + `auth.js`)
- Form đăng nhập → gọi `sp_DangNhap`
- Lưu thông tin user vào localStorage
- `checkAuth()` bảo vệ tất cả trang admin (chuyển hướng về login nếu chưa đăng nhập)
- `logout()` xóa localStorage + redirect

### 13. Đăng nhập Mobile (`login_screen.dart`)
- Form đăng nhập → gọi `sp_DangNhap` qua API
- Phân quyền: vai trò (Quản lý / Nhân viên) dùng để hiển thị chức năng phù hợp
- Lưu thông tin user để dùng xuyên suốt app

---

## 🟢 G. Thống kê Doanh thu (Web Admin)

### 14. Biểu đồ doanh thu — Web Admin (`Analytics.html` + `detailAnalytics.js`)
- Hai chế độ xem: **Theo tháng** và **Theo ngày**
- Tải toàn bộ dữ liệu từ quá khứ đến hiện tại (không cần chọn khoảng ngày)
- Biểu đồ cột (Chart.js)
- Click vào cột → xem chi tiết món ăn đã bán trong tháng/ngày đó
- Hiển thị 2 dòng: **Tổng tiền (trước giảm)** + **Thành tiền (sau giảm)**

### 15. Thống kê tổng quan — Web Admin
- Tổng số món ăn trong menu
- Tổng số món đã bán

---

## 🟢 H. Cơ sở dữ liệu & Backend

### 16. SQL Server — Stored Procedures (16 SP)
| SP | Chức năng |
|----|-----------|
| `sp_DangNhap` | Đăng nhập (SHA-256 hash) |
| `sp_DangKy` | Đăng ký tài khoản |
| `sp_DatHang` | Đặt hàng (Transaction) |
| `sp_ThanhToan` | Thanh toán + voucher (Transaction) |
| `sp_KiemTraVoucher` | Kiểm tra mã giảm giá |
| `sp_ThongKeDoanhThu` | Thống kê doanh thu theo ngày |
| `sp_MonBanChay` | Món bán chạy |
| `sp_HoaDonChuaThanhToan` | Hóa đơn chưa thanh toán |
| `sp_ChiTietHoaDon` | Chi tiết hóa đơn |
| `sp_ThemMonAn` | Thêm món ăn |
| `sp_CapNhatMonAn` | Cập nhật món ăn |
| `sp_XoaMonAn` | Xóa món ăn |
| `sp_VoucherList` / Add / Update / Toggle | Quản lý voucher |
| `sp_NhanVienList` / Add / Update / Delete | Quản lý nhân viên |

### 17. SQL Server — Views (3 views)
| View | Chức năng |
|------|-----------|
| `vw_HoaDonChiTiet` | Hóa đơn chi tiết (kèm KhachTra) |
| `vw_DoanhThuTheoNgay` | Doanh thu theo ngày |
| `vw_MonAn` | Danh sách món ăn |

### 18. SQL Server — Trigger
- `trg_ChiTietHoaDon_UpdateTongTien`: tự động cập nhật tổng tiền khi thêm/xóa/sửa chi tiết hóa đơn

### 19. Node.js API
- 20+ endpoints RESTful
- Kết nối SQL Server qua connection pool (`mssql`)
- Upload hình ảnh món ăn (multer)
- Phục vụ web admin tĩnh tại `/admin`
- CORS cho phép mọi origin (phát triển)

---

## 🟢 I. Giao diện người dùng

### 20. Màn hình Mobile (Flutter)
| Màn hình | File |
|----------|------|
| Splash | `SplashScreen.dart` |
| Đăng nhập | `login_screen.dart` |
| Trang chủ | `home_screen.dart` |
| Menu món ăn | `food_menu_screen.dart` |
| Danh sách bàn | `dsban_screen.dart` |
| Tạo đơn hàng | `CreateOrder_Screen.dart` |
| Phiếu tạm tính | `SavedInvoicesScreen.dart` |
| Bếp | `kitchen_screen.dart` |

### 21. Giao diện Web Admin
| Trang | File |
|-------|------|
| Đăng nhập | `login.html` |
| Trang chủ | `index.html` |
| Danh sách món | `DisplayFood.html` |
| Quản lý bàn | `TableManagement.html` |
| Thống kê | `Analytics.html` |
| Voucher | `VoucherManagement.html` |
| Nhân viên | `EmployeeManagement.html` |

---

## ✅ Đã hoàn thiện

| STT | Chức năng | Trạng thái |
|-----|-----------|------------|
| 1 | **Tạo user riêng + phân quyền** | ✅ Đã tạo `ql_tamthoi` + GRANT đầy đủ |
| 2 | Ghi chú món ăn khi gọi món | ✅ Đã có trong `CreateOrder_Screen` (ghiChu) |
| 3 | Thêm món vào hóa đơn đang có | ✅ Đã sửa `sp_DatHang` |
| 4 | Bảo mật SQL injection | ✅ Đã chuyển sang parameterized query |
| 5 | LAN/WAN toggle | ✅ `config.js` + `api_service.dart` |

---

## Tổng hợp

- **Tổng số chức năng đã làm: ~21 chức năng** (chi tiết 19 mục trên + 2 màn hình phụ)
- **Còn thiếu:** (quan trọng nhất: tạo `app_user` để đạt điểm tối đa phần bảo mật)
