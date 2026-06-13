import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_manager_project/models/order_item.dart';
import 'package:food_manager_project/service/api_service.dart';

/// Màn hình thực đơn món ăn
/// 
/// Hiển thị danh sách món ăn dạng lưới với hình ảnh, giá tiền,
/// cho phép tìm kiếm và lọc theo danh mục (Đồ ăn, Đồ uống, Tráng miệng).
/// Dữ liệu lấy từ SQL Server qua API backend.
class MenuScreen extends StatefulWidget {
  final Function(OrderItem newItem)? onItemSelected;
  final Map<String, dynamic> user;

  const MenuScreen({
    super.key,
    this.onItemSelected,
    required this.user,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String searchText = '';
  String selectedCategory = 'All';
  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Tải danh sách món ăn và danh mục từ API
  Future<void> _loadData() async {
    try {
      final items = await ApiService.getMenu();
      final cats = await ApiService.getCategories();
      if (!mounted) return;
      setState(() {
        menuItems = items;
        categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    }
  }

  /// Chuyển đổi giá từ các kiểu dữ liệu khác nhau về double
  double parsePrice(dynamic price) {
    if (price is int) return price.toDouble();
    if (price is double) return price;
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  /// Định dạng giá tiền theo VND
  String formatPrice(double price) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(price);
  }

  /// Xử lý khi chọn món ăn
  void _selectItem(Map<String, dynamic> itemData) {
    final item = OrderItem(
      monAnId: itemData['Id'] is int ? itemData['Id'] : int.tryParse(itemData['Id'].toString()) ?? 0,
      name: itemData['Ten']?.toString() ?? 'Món không tên',
      price: parsePrice(itemData['Gia']),
      quantity: 1,
    );
    widget.onItemSelected?.call(item);
    Navigator.pop(context);
  }

  /// Xây dựng chip lọc danh mục
  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: selectedCategory == value,
      onSelected: (selected) {
        setState(() { selectedCategory = value; });
        _filterByCategory(value);
      },
    );
  }

  /// Lọc món ăn theo danh mục qua API
  Future<void> _filterByCategory(String category) async {
    try {
      setState(() => _isLoading = true);
      final items = await ApiService.getMenu(category: category == 'All' ? null : category);
      if (!mounted) return;
      setState(() {
        menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Tìm kiếm món ăn theo tên
  Future<void> _search(String query) async {
    try {
      setState(() => _isLoading = true);
      final items = await ApiService.getMenu(
        category: selectedCategory == 'All' ? null : selectedCategory,
        search: query.isEmpty ? null : query,
      );
      if (!mounted) return;
      setState(() {
        menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thực đơn'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm tên món...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                searchText = value;
                _search(value);
              },
            ),
          ),

          // Bộ lọc danh mục
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 8,
              children: [
                _buildFilterChip("Tất cả", 'All'),
                _buildFilterChip("Đồ ăn", 'Đồ ăn'),
                _buildFilterChip("Đồ uống", 'Đồ uống'),
                _buildFilterChip("Tráng miệng", 'Tráng miệng'),
              ],
            ),
          ),

          // Danh sách món ăn
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : menuItems.isEmpty
                    ? const Center(child: Text('Không có món ăn phù hợp'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3 / 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final item = menuItems[index];
                          final priceDouble = parsePrice(item['Gia']);
                          final imageUrl = item['HinhAnh']?.toString() ?? '';
                          final base = kIsWeb ? 'http://localhost:3000' : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000');
                          final fullImageUrl = imageUrl.isNotEmpty ? '$base$imageUrl' : '';

                          return GestureDetector(
                            onTap: () => _selectItem(item),
                            child: Card(
                              elevation: 4,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: fullImageUrl.isNotEmpty
                                        ? Image.network(
                                            fullImageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(child: Icon(Icons.fastfood, size: 50));
                                            },
                                          )
                                        : const Center(child: Icon(Icons.fastfood, size: 50)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item['Ten'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Text(
                                    formatPrice(priceDouble),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
