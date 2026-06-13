# Ứng dụng Quản lý Nhà hàng (Flutter)

## Cài đặt

```bash
flutter pub get
```

## Thay đổi địa chỉ API

Mở file `lib/service/api_service.dart` và sửa `baseUrl`:

```dart
// Android emulator: dùng 10.0.2.2
// iOS simulator: dùng localhost
// Thiết bị thật: dùng IP máy chạy backend
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

## Chạy ứng dụng

Đảm bảo backend `menu-api` đã chạy trước, sau đó:

```bash
flutter run
```

## Cấu trúc thư mục

```
lib/
├── main.dart                    # Entry point
├── service/
│   ├── api_service.dart         # HTTP client - gọi API backend
│   └── auth_service.dart        # Xác thực người dùng
├── models/
│   ├── order_item.dart          # Món ăn trong đơn hàng
│   ├── user.dart                # Người dùng
│   ├── ban_an_model.dart        # Bàn ăn
│   └── table_order.dart         # Đơn hàng
├── screens/
│   ├── login_screen.dart        # Đăng nhập
│   ├── register_screen.dart     # Đăng ký
│   ├── home_screen.dart         # Trang chủ
│   ├── dsban_screen.dart        # Danh sách bàn
│   ├── food_menu_screen.dart    # Thực đơn
│   ├── CreateOrder_Screen.dart  # Tạo đơn hàng
│   ├── Invoices.dart            # Hóa đơn đã thanh toán
│   ├── SavedInvoicesScreen.dart # Phiếu tạm tính
│   └── InvoiceDetailScreen.dart # Chi tiết hóa đơn
└── widgets/
    ├── infor_card.dart          # Thẻ thông tin
    ├── notification_card.dart   # Thẻ thông báo
    └── quick_action_button.dart # Nút chức năng nhanh
```

## Lưu ý

- Ứng dụng kết nối đến SQL Server thông qua API backend Node.js
- Không dùng Firebase (đã loại bỏ hoàn toàn)
- Các stored procedure xử lý Transaction phía SQL Server
