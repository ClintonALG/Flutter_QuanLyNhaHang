import 'package:flutter/material.dart';
import 'package:food_manager_project/screens/CreateOrder_Screen.dart';
import 'package:food_manager_project/screens/SavedInvoicesScreen.dart';
import 'package:food_manager_project/screens/dsban_screen.dart';
import 'package:food_manager_project/screens/food_menu_screen.dart';
import 'package:food_manager_project/screens/kitchen_screen.dart';
import 'package:food_manager_project/screens/login_screen.dart';
import 'package:food_manager_project/service/api_service.dart';

/// Màn hình chính sau khi đăng nhập
/// 
/// Hiển thị thông tin nhân viên, thống kê bàn trống,
/// và các chức năng nhanh: tạo đơn, danh sách bàn, quản lý món, hóa đơn.
/// Dữ liệu được lấy từ SQL Server thông qua API backend.
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int soBanTrong = 0;
  int tongSoBan = 15;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSoBanTrong();
  }

  /// Tải số lượng bàn trống từ SQL Server qua API
  Future<void> _loadSoBanTrong() async {
    try {
      final tables = await ApiService.getTables();
      if (!mounted) return;
      setState(() {
        soBanTrong = tables.where((t) => t['TrangThai'] == 'Còn trống').length;
        tongSoBan = tables.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi tải số bàn trống: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Hiển thị dialog xác nhận đăng xuất
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.w600)),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              child: const Text('Hủy', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Amore Pizza',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lời chào
              Text(
                'Xin chào, ${widget.user['HoTen'] ?? widget.user['TenDangNhap'] ?? 'Người dùng'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ thống kê bàn trống
              _buildStatsCard(context),
              const SizedBox(height: 24),

              // Tiêu đề chức năng nhanh
              const Text(
                'CHỨC NĂNG NHANH',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Lưới chức năng nhanh
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildQuickAction(
                    context,
                    Icons.add_shopping_cart,
                    'Tạo đơn mới',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateOrderScreen(user: widget.user)),
                    ).then((_) => _loadSoBanTrong()),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.table_chart,
                    'Danh sách bàn',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BanScreen(user: widget.user)),
                    ).then((_) => _loadSoBanTrong()),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.fastfood,
                    'Quản lý món',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MenuScreen(user: widget.user)),
                    ).then((_) => _loadSoBanTrong()),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.receipt,
                    'Phiếu tạm tính',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SavedInvoicesScreen()),
                    ).then((_) => _loadSoBanTrong()),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.kitchen,
                    'Bếp',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => KitchenScreen(user: widget.user)),
                    ).then((_) => _loadSoBanTrong()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng thẻ thống kê số bàn trống
  Widget _buildStatsCard(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else
              Column(
                children: [
                  const Text('🍽️ Bàn trống', style: TextStyle(fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    '$soBanTrong / $tongSoBan',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng nút chức năng nhanh
  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
