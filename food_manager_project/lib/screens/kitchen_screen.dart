import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_manager_project/service/api_service.dart';
import 'package:food_manager_project/widgets/error_helper.dart';

/// Màn hình bếp - hiển thị danh sách món cần chế biến
/// 
/// Lấy các hóa đơn chưa thanh toán từ SQL Server,
/// hiển thị danh sách món ăn cần chế biến theo bàn.
class KitchenScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const KitchenScreen({super.key, required this.user});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);
      final result = await ApiService.getInvoices(status: 'Chưa thanh toán');
      if (!mounted) return;
      setState(() { orders = result; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showApiError(context, e, onRetry: _loadOrders);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bếp - Món cần chế biến'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('Hiện không có đơn hàng nào'))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: ApiService.getInvoiceDetail(order['Id']),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text('Bàn ${order['TenBan'] ?? ''}'),
                                subtitle: Text('Lỗi tải chi tiết: ${snapshot.error}'),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text('Bàn ${order['TenBan'] ?? ''}'),
                                subtitle: const Text('Đang tải...'),
                              ),
                            );
                          }
                          final items = snapshot.data!;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Bàn ${order['TenBan'] ?? ''}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('HH:mm').format(DateTime.parse(order['NgayTao'].toString())),
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  ...items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'x${item['SoLuong']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['TenMonAn'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              if (item['GhiChu'] != null && item['GhiChu'].toString().isNotEmpty)
                                                Text(
                                                  '📝 ${item['GhiChu']}',
                                                  style: const TextStyle(color: Colors.orange, fontSize: 13, fontStyle: FontStyle.italic),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
