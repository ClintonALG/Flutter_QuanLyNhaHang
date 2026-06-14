import 'package:flutter/material.dart';
import 'package:food_manager_project/service/api_service.dart';
import 'package:food_manager_project/widgets/error_helper.dart';

class BanScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool selectMode;

  const BanScreen({super.key, required this.user, this.selectMode = true});

  @override
  State<BanScreen> createState() => _BanScreenState();
}

class _BanScreenState extends State<BanScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> danhSachBan = [];
  bool? _filterStatus;
  bool _isLoading = true;
  bool _swapMode = false;
  Map<String, dynamic>? _swapSource;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadDanhSachBan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) loadDanhSachBan();
  }

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
          'hoaDonId': t['HoaDonId'],
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showApiError(context, e, onRetry: loadDanhSachBan);
      }
    }
  }

  Color layMauBan(String status) {
    return status == 'Đang sử dụng' ? Colors.amber : Colors.grey;
  }

  void _chonBan(Map<String, dynamic> ban) {
    if (ban['status'] == 'Đang sử dụng') {
      for (final b in danhSachBan) {
        if (b['id'] == ban['id']) {
          Navigator.pop(context, b);
          return;
        }
      }
    }
    Navigator.pop(context, ban);
  }

  Future<void> _startSwap(Map<String, dynamic> ban) async {
    setState(() {
      _swapMode = true;
      _swapSource = ban;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chọn bàn muốn đổi với ${ban['names']}')),
    );
  }

  Future<void> _doSwap(Map<String, dynamic> target) async {
    if (_swapSource == null) return;
    if (_swapSource!['id'] == target['id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đổi với chính nó')),
      );
      setState(() { _swapMode = false; _swapSource = null; });
      return;
    }
    try {
      await ApiService.renameTable(_swapSource!['id'], target['names']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đổi ${_swapSource!['names']} với ${target['names']}')),
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
    setState(() { _swapMode = false; _swapSource = null; });
    loadDanhSachBan();
  }

  void _cancelSwap() {
    setState(() { _swapMode = false; _swapSource = null; });
  }

  @override
  Widget build(BuildContext context) {
    final banHienThi = _filterStatus == null
        ? danhSachBan
        : danhSachBan.where((ban) =>
            _filterStatus == true
                ? ban['status'] == 'Đang sử dụng'
                : ban['status'] == 'Còn trống').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_swapMode ? 'Chọn bàn để đổi' : 'Chọn bàn'),
        actions: _swapMode
            ? [TextButton(onPressed: _cancelSwap, child: const Text('Hủy', style: TextStyle(color: Colors.white)))]
            : (widget.selectMode
                ? []
                : [IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Đổi chỗ bàn',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nhấn giữ bàn để chọn đổi chỗ')),
                      );
                    },
                  )]),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                      final bool isTarget = _swapMode && _swapSource != null && _swapSource!['id'] == ban['id'];

                      return GestureDetector(
                        onTap: () {
                          if (_swapMode) {
                            _doSwap(ban);
                          } else {
                            _chonBan(ban);
                          }
                        },
                        onLongPress: widget.selectMode
                            ? null
                            : () => _startSwap(ban),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isTarget ? Colors.blue.shade200 : layMauBan(status),
                            borderRadius: BorderRadius.circular(8),
                            border: isTarget ? Border.all(color: Colors.blue, width: 3) : null,
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