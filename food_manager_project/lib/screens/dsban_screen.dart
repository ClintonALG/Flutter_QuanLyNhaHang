import 'package:flutter/material.dart';
import 'package:food_manager_project/service/api_service.dart';

/// Màn hình danh sách bàn ăn
/// 
/// Hiển thị lưới các bàn với trạng thái (Còn trống / Đang sử dụng),
/// cho phép lọc theo trạng thái và chọn bàn để bắt đầu phục vụ.
/// Dữ liệu lấy từ SQL Server qua API backend.
class BanScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const BanScreen({super.key, required this.user});

  @override
  State<BanScreen> createState() => _BanScreenState();
}

class _BanScreenState extends State<BanScreen> {
  List<Map<String, dynamic>> danhSachBan = [];
  bool? _filterStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDanhSachBan();
  }

  /// Tải danh sách bàn từ SQL Server
  Future<void> loadDanhSachBan() async {
    try {
      setState(() => _isLoading = true);
      final tables = await ApiService.getTables();
      if (!mounted) return;
      setState(() {
        danhSachBan = tables.map((t) => {
          'id': t['Id'],
          'names': t['TenBan'] ?? 'Bàn không tên',
          'status': t['TrangThai'] ?? 'Còn trống',
        }).toList();
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

  /// Trả về màu sắc dựa trên trạng thái bàn
  Color layMauBan(String status) {
    return status == 'Đang sử dụng' ? Colors.amber : Colors.grey;
  }

  /// Xử lý khi chọn bàn - chỉ trả về tên bàn, không cập nhật trạng thái
  /// Trạng thái bàn sẽ được cập nhật khi đặt hàng thành công (trong sp_DatHang)
  Future<void> _chonBan(Map<String, dynamic> ban) async {
    if (ban['status'] == 'Đang sử dụng') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bàn đang sử dụng, không thể chọn!')),
      );
      return;
    }

    Navigator.pop(context, ban['names']);
  }

  @override
  Widget build(BuildContext context) {
    // Lọc bàn theo trạng thái
    final banHienThi = _filterStatus == null
        ? danhSachBan
        : danhSachBan.where((ban) =>
            _filterStatus == true
                ? ban['status'] == 'Đang sử dụng'
                : ban['status'] == 'Còn trống').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn bàn')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bộ lọc trạng thái
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _filterStatus = true),
                        child: Row(
                          children: [
                            Container(width: 20, height: 20, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text('Đang sử dụng'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => setState(() => _filterStatus = false),
                        child: Row(
                          children: [
                            Container(width: 20, height: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text('Còn trống'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      TextButton(
                        onPressed: () => setState(() => _filterStatus = null),
                        child: const Text('Hiện tất cả'),
                      ),
                    ],
                  ),
                ),
                // Lưới danh sách bàn
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: banHienThi.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final ban = banHienThi[index];
                      final String status = ban['status'] ?? 'Còn trống';

                      return GestureDetector(
                        onTap: () => _chonBan(ban),
                        child: Container(
                          decoration: BoxDecoration(
                            color: layMauBan(status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              ban['names'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
