# Web Admin - Quản lý Nhà hàng

## Cài đặt

Mở file HTML trong thư mục `functions/` bằng Live Server (VS Code - port 5500)
hoặc mở trực tiếp từ trình duyệt.

## API Backend

Web admin gọi API tại `http://localhost:3000/api` (Node.js backend kết nối SQL Server).

## Các trang

| Trang | File | Chức năng |
|-------|------|-----------|
| Quản lý món ăn | DisplayFood.html | CRUD thực đơn |
| Thống kê | Analytics.html | Biểu đồ doanh thu, nguyên liệu |
| Tồn kho món | Inventory.html | Số lượng tồn kho món ăn |
| Tồn kho nguyên liệu | IngredientsInventory.html | Nguyên liệu tồn kho |
