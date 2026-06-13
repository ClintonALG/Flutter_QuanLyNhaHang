/// Model đại diện cho một món ăn trong đơn hàng
class OrderItem {
  int monAnId;
  String name;
  double price;
  int quantity;
  String ghiChu;

  OrderItem({
    required this.monAnId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.ghiChu = '',
  });

  Map<String, dynamic> toJson() => {
    'monAnId': monAnId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'ghiChu': ghiChu,
  };
}
