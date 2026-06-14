import 'package:flutter/material.dart';
import 'package:food_manager_project/screens/dsban_screen.dart';
import 'package:food_manager_project/screens/food_menu_screen.dart';
import 'package:food_manager_project/models/order_item.dart' as modelOrder;
import 'package:food_manager_project/service/api_service.dart';
import 'package:food_manager_project/widgets/error_helper.dart';

class CreateOrderScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final int? editHoaDonId;

  const CreateOrderScreen({Key? key, required this.user, this.editHoaDonId}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  Map<String, dynamic>? _selectedTableInfo;
  List<modelOrder.OrderItem> orderItems = [];
  bool _isSaving = false;
  bool _isLoadingExisting = false;

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  modelOrder.OrderItem _orderItemFromDetail(Map<String, dynamic> i) {
    final chiTietId = _parseInt(i['Id']);
    return modelOrder.OrderItem(
      monAnId: _parseInt(i['MonAnId']),
      name: i['TenMonAn'] ?? '',
      price: (i['DonGia'] is num) ? (i['DonGia'] as num).toDouble() : 0,
      quantity: (i['SoLuong'] is num) ? (i['SoLuong'] as num).toInt() : 1,
      ghiChu: i['GhiChu']?.toString() ?? '',
      chiTietId: chiTietId > 0 ? chiTietId : null,
    );
  }

  String? get selectedTable => _selectedTableInfo?['names'];
  int? get selectedTableId => _selectedTableInfo?['id'];
  int? get hoaDonId => _selectedTableInfo?['hoaDonId'];

  @override
  void initState() {
    super.initState();
    if (widget.editHoaDonId != null) {
      _loadInvoiceForEdit(widget.editHoaDonId!);
    }
  }

  Future<void> _loadInvoiceForEdit(int hdId) async {
    setState(() => _isLoadingExisting = true);
    try {
      final hdList = await ApiService.getInvoices(status: 'Chưa thanh toán');
      final inv = hdList.firstWhere((i) => i['Id'] == hdId);
      if (!mounted) return;
      setState(() {
        _selectedTableInfo = {
          'id': inv['BanId'],
          'names': inv['TenBan'] ?? '',
          'hoaDonId': hdId,
        };
      });
      final items = await ApiService.getInvoiceDetail(hdId);
      if (!mounted) return;
      setState(() {
        orderItems = items.map(_orderItemFromDetail).toList();
        _isLoadingExisting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingExisting = false);
        showApiError(context, e, onRetry: () => _loadInvoiceForEdit(hdId));
      }
    }
  }

  double get totalPrice =>
      orderItems.fold(0, (sum, item) => sum + item.price * item.quantity);

  Future<void> _chooseTable() async {
    final table = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BanScreen(user: widget.user)),
    );
    if (table != null && mounted) {
      setState(() { _selectedTableInfo = table as Map<String, dynamic>; });
      if (table['hoaDonId'] != null) {
        await _loadExistingItems(table['hoaDonId']);
      } else {
        orderItems.clear();
      }
      _chooseMenu();
    }
  }

  Future<void> _loadExistingItems(int hdId) async {
    try {
      final items = await ApiService.getInvoiceDetail(hdId);
      if (!mounted) return;
      setState(() {
        orderItems = items.map(_orderItemFromDetail).toList();
      });
    } catch (e) {
      showApiError(context, e);
    }
  }

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
              final existingIndex = orderItems.indexWhere((e) => e.monAnId == item.monAnId);
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

  Future<void> _saveOrder() async {
    final isEditing = widget.editHoaDonId != null || hoaDonId != null;
    final itemsToSend = isEditing
        ? orderItems.where((item) => item.chiTietId == null).toList()
        : orderItems;

    if (selectedTable == null || (selectedTableId == null && hoaDonId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn bàn trước khi đặt hàng!')),
      );
      return;
    }

    if (itemsToSend.isEmpty) {
      if (isEditing) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hóa đơn thành công!')),
        );
        Navigator.pop(context, true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn bàn và món trước khi đặt hàng!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final employeeId = widget.user['Id'];
      final nhanVienId = employeeId is int ? employeeId : int.tryParse(employeeId.toString()) ?? 0;
      final items = itemsToSend.map((item) => ({
        'monAnId': item.monAnId,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price.toInt(),
        'ghiChu': item.ghiChu,
      })).toList();

      await ApiService.createOrder(
        banId: selectedTableId ?? 0,
        nhanVienId: nhanVienId,
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removeOrderItem(int index) async {
    final item = orderItems[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Xóa món '${item.name}'?"),
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
      if (item.chiTietId != null && hoaDonId != null) {
        try {
          await ApiService.deleteOrderItem(hoaDonId!, item.chiTietId!);
        } catch (e) {
          showApiError(context, e);
        }
      }
      setState(() { orderItems.removeAt(index); });
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() { orderItems[index].quantity = newQuantity.clamp(1, 99); });
  }

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
      appBar: AppBar(title: Text(widget.editHoaDonId != null ? 'Sửa hóa đơn' : 'Tạo đơn hàng')),
      body: _isLoadingExisting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.editHoaDonId == null) ...[
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
                  ] else ...[
                    Text('Bàn: $selectedTable', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                  ],

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
                              return SizedBox(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text('Đơn giá: ${item.price.toInt()} đ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('SL: ', style: TextStyle(fontSize: 13)),
                                              GestureDetector(
                                                onTap: () {
                                                  if (item.quantity > 1) _updateQuantity(index, item.quantity - 1);
                                                },
                                                child: Container(
                                                  width: 28, height: 28,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Icon(Icons.remove, size: 16),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  '${item.quantity}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  if (item.quantity < 99) _updateQuantity(index, item.quantity + 1);
                                                },
                                                child: Container(
                                                  width: 28, height: 28,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Icon(Icons.add, size: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showNoteDialog(index),
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(Icons.note_add, size: 22, color: item.ghiChu.isNotEmpty ? Colors.orange : Colors.grey),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _removeOrderItem(index),
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: const Icon(Icons.delete, size: 22, color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Tổng tiền: ${totalPrice.toInt()} đ',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

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