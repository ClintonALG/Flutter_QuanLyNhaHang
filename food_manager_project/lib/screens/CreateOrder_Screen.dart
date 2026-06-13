import 'package:flutter/material.dart';
import 'package:food_manager_project/screens/dsban_screen.dart';
import 'package:food_manager_project/screens/food_menu_screen.dart';
import 'package:food_manager_project/models/order_item.dart' as modelOrder;
import 'package:food_manager_project/service/api_service.dart';

/// Màn hình tạo đơn hàng mới
/// 
/// Cho phép nhân viên chọn bàn, thêm món từ thực đơn,
/// điều chỉnh số lượng và xác nhận đặt hàng.
/// Đơn hàng được tạo qua stored procedure sp_DatHang (có Transaction) trên SQL Server.
class CreateOrderScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CreateOrderScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? selectedTable;
  int? selectedTableId;
  List<modelOrder.OrderItem> orderItems = [];
  bool _isSaving = false;

  /// Tính tổng tiền tự động từ danh sách món đã chọn
  double get totalPrice =>
      orderItems.fold(0, (sum, item) => sum + item.price * item.quantity);

  /// Mở màn hình chọn bàn
  Future<void> _chooseTable() async {
    final table = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BanScreen(user: widget.user)),
    );
    if (table != null && mounted) {
      setState(() { selectedTable = table; });
      // Lấy Id bàn từ tên
      try {
        final tables = await ApiService.getTables();
        final found = tables.firstWhere((t) => t['TenBan'] == table);
        selectedTableId = found['Id'];
      } catch (_) {}
      _chooseMenu();
    }
  }

  /// Mở màn hình chọn món từ thực đơn
  Future<void> _chooseMenu() async {
    if (selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bàn trước!')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          user: widget.user,
          onItemSelected: (item) {
            setState(() {
              final existingIndex = orderItems.indexWhere((e) => e.name == item.name);
              if (existingIndex >= 0) {
                orderItems[existingIndex].quantity += item.quantity;
                if (orderItems[existingIndex].quantity > 99) {
                  orderItems[existingIndex].quantity = 99;
                }
              } else {
                orderItems.add(item);
              }
            });
          },
        ),
      ),
    );
  }

  /// Lưu đơn hàng - gọi stored procedure sp_DatHang (Transaction)
  /// 
  /// Quy trình: Thêm HoaDon -> Thêm ChiTietHoaDon -> Cập nhật trạng thái bàn
  /// Toàn bộ trong 1 transaction trên SQL Server, nếu lỗi sẽ rollback.
  Future<void> _saveOrder() async {
    if (selectedTable == null || selectedTableId == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn bàn và món trước khi đặt hàng!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final employeeId = widget.user['Id'];
      final nhanVienId = employeeId is int ? employeeId : int.tryParse(employeeId.toString()) ?? 0;
      final items = orderItems.map((item) => ({
        'monAnId': item.monAnId,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price.toInt(),
        'ghiChu': item.ghiChu,
      })).toList();

      await ApiService.createOrder(
        banId: selectedTableId!,
        nhanVienId: nhanVienId,
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!')),
      );
      setState(() {
        selectedTable = null;
        selectedTableId = null;
        orderItems.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Xóa món khỏi đơn hàng (có xác nhận)
  void _removeOrderItem(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Xóa món '${orderItems[index].name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Không")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() { orderItems.removeAt(index); });
    }
  }

  /// Cập nhật số lượng món (giới hạn 1-99)
  void _updateQuantity(int index, int newQuantity) {
    setState(() { orderItems[index].quantity = newQuantity.clamp(1, 99); });
  }

  /// Hiển thị dialog nhập ghi chú cho món ăn
  void _showNoteDialog(int index) {
    final controller = TextEditingController(text: orderItems[index].ghiChu);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ghi chú cho ${orderItems[index].name}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'VD: Ít đường, không cay...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              setState(() { orderItems[index].ghiChu = controller.text; });
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo đơn hàng')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chọn bàn
            Text('Bàn:', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTable ?? 'Chưa chọn bàn',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: _chooseTable,
                  child: const Text('Chọn bàn'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Danh sách món đã chọn
            Row(
              children: [
                Text('Món đã chọn:', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ElevatedButton(
                  onPressed: _chooseMenu,
                  child: const Text('Thêm món'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: orderItems.isEmpty
                  ? const Center(child: Text('Chưa có món nào được chọn'))
                  : ListView.separated(
                      itemCount: orderItems.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Row(
                            children: [
                              Text('Đơn giá: ${item.price.toInt()} đ'),
                              const SizedBox(width: 10),
                              const Text('SL:'),
                              const SizedBox(width: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () {
                                      if (item.quantity > 1) _updateQuantity(index, item.quantity - 1);
                                    },
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () {
                                      if (item.quantity < 99) _updateQuantity(index, item.quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.note_add, color: item.ghiChu.isNotEmpty ? Colors.orange : Colors.grey),
                                onPressed: () => _showNoteDialog(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeOrderItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),
            // Tổng tiền
            Text(
              'Tổng tiền: ${totalPrice.toInt()} đ',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Nút xác nhận
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : _saveOrder,
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Xác nhận đặt hàng', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
