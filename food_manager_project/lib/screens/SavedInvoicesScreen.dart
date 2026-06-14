import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_manager_project/screens/CreateOrder_Screen.dart';
import 'package:food_manager_project/service/api_service.dart';
import 'package:food_manager_project/widgets/error_helper.dart';

/// Màn hình phiếu tạm tính (hóa đơn chưa thanh toán)
/// 
/// Hiển thị danh sách hóa đơn chưa thanh toán từ SQL Server,
/// cho phép xem chi tiết và xác nhận thanh toán.
/// Khi thanh toán, gọi stored procedure sp_ThanhToan (có Transaction).
class SavedInvoicesScreen extends StatefulWidget {
  const SavedInvoicesScreen({super.key});

  @override
  State<SavedInvoicesScreen> createState() => _SavedInvoicesScreenState();
}

class _SavedInvoicesScreenState extends State<SavedInvoicesScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> unpaidInvoices = [];
  List<Map<String, dynamic>> paidInvoices = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = chua thanh toan, 1 = da thanh toan

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInvoices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      setState(() => _isLoading = true);
      final results = await Future.wait([
        ApiService.getInvoices(status: 'Chưa thanh toán'),
        ApiService.getInvoices(status: 'Đã thanh toán'),
      ]);
      if (!mounted) return;
      setState(() {
        unpaidInvoices = results[0];
        paidInvoices = results[1];
        _isLoading = false;
      });
      _filterList();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showApiError(context, e, onRetry: _loadInvoices);
      }
    }
  }

  List<Map<String, dynamic>> get _currentList =>
      _selectedTab == 0 ? unpaidInvoices : paidInvoices;

  Future<void> _payInvoice(int hoaDonId, {int tongTien = 0}) async {
    String? maGiamGia;
    int? thanhTien;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final voucherCtrl = TextEditingController();
        String? voucherMsg;
        bool checking = false;
        bool validated = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Xác nhận thanh toán'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền:', style: TextStyle(fontSize: 16)),
                    Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(tongTien),
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                if (thanhTien != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giảm:', style: TextStyle(fontSize: 14, color: Colors.green)),
                      Text('-${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(tongTien - thanhTien!)}',
                          style: const TextStyle(fontSize: 14, color: Colors.green)),
                    ],
                  ),
                if (thanhTien != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thành tiền:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(thanhTien!),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: voucherCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Mã giảm giá (VD: WELCOME10)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: checking ? null : () async {
                        final ma = voucherCtrl.text.trim();
                        if (ma.isEmpty) return;
                        setDialogState(() { checking = true; voucherMsg = null; validated = false; });
                        try {
                          final result = await ApiService.checkVoucher(ma, tongTien: tongTien);
                          setDialogState(() {
                            checking = false;
                            if (result['TrangThai'] == 'Hợp lệ') {
                              maGiamGia = ma;
                              final tienGiam = (result['TienGiam'] as num?)?.toDouble() ?? 0;
                              thanhTien = (tongTien - tienGiam.toInt());
                              voucherMsg = 'Giảm ${(result['PhanTramGiam'] as num?)?.toStringAsFixed(0) ?? '0'}%';
                              validated = true;
                            } else {
                              maGiamGia = null;
                              thanhTien = null;
                              voucherMsg = 'Mã không hợp lệ!';
                              validated = false;
                            }
                          });
                        } catch (e) {
                          setDialogState(() {
                            checking = false;
                            voucherMsg = 'Lỗi kiểm tra mã';
                            validated = false;
                          });
                        }
                      },
                      child: checking
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Kiểm tra'),
                    ),
                  ],
                ),
                if (voucherMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(voucherMsg!,
                      style: TextStyle(
                        color: validated ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  if (voucherCtrl.text.trim().isNotEmpty && !validated) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Vui lòng kiểm tra mã trước khi thanh toán')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Thanh toán', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ApiService.payInvoice(hoaDonId, maGiamGia: maGiamGia);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: Colors.green),
      );
      _loadInvoices();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showApiError(context, e, onRetry: () => _payInvoice(hoaDonId, tongTien: tongTien));
      }
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return date.toString().split('T')[0];
    }
  }

  String formatMoney(dynamic amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final value = (amount is num) ? amount.toDouble() : double.tryParse(amount?.toString() ?? '0') ?? 0;
    return formatter.format(value);
  }

  void _filterList() {
    setState(() {
      _filteredList = _currentList.where((inv) {
        return _searchQuery.isEmpty ||
            (inv['TenBan']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (inv['TenNhanVien']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    });
  }

  void _switchTab(int tab) {
    setState(() => _selectedTab = tab);
    _filterList();
  }

  void _showReceipt(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) {
    final thanhTien = ((invoice['TongTien'] as num?)?.toInt() ?? 0) - ((invoice['TienGiam'] as num?)?.toInt() ?? 0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HÓA ĐƠN', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              Text('Bàn: ${invoice['TenBan'] ?? ''}'),
              Text('Nhân viên: ${invoice['TenNhanVien'] ?? ''}'),
              Text('Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(invoice['NgayTao'].toString()))}'),
              const Divider(),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(item['TenMonAn'] ?? '')),
                    Expanded(flex: 1, child: Text('x${item['SoLuong']}', textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('${formatMoney(item['DonGia'])}', textAlign: TextAlign.right)),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TỔNG CỘNG:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${formatMoney(invoice['TongTien'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if ((invoice['TienGiam'] as num? ?? 0) > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Giảm (${invoice['MaGiamGia'] ?? ''}):',
                        style: const TextStyle(color: Colors.green)),
                    Text('-${formatMoney(invoice['TienGiam'])}',
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('THÀNH TIỀN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${formatMoney(thanhTien)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                  ],
                ),
              ],
              const Divider(),
              const Center(child: Text('Cảm ơn quý khách!')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 0 ? Colors.orange : Colors.grey.shade300,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'Chưa thanh toán (${unpaidInvoices.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                        color: _selectedTab == 0 ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 1 ? Colors.orange : Colors.grey.shade300,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'Đã thanh toán (${paidInvoices.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                        color: _selectedTab == 1 ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm bàn, nhân viên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _filterList();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterList();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? Center(
                        child: Text(
                          _selectedTab == 0 ? 'Không có phiếu tạm tính nào' : 'Chưa có hóa đơn nào',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInvoices,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final inv = _filteredList[index];
                            final tongTien = (inv['TongTien'] as num?)?.toInt() ?? 0;
                            final tienGiam = (inv['TienGiam'] as num?)?.toInt() ?? 0;
                            final thanhTien = tongTien - tienGiam;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  'Bàn ${inv['TenBan'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('NV: ${inv['TenNhanVien'] ?? 'N/A'}'),
                                    Text('Ngày: ${formatDate(inv['NgayTao'])}'),
                                    if (_selectedTab == 0 || (tienGiam) == 0)
                                      Text('Tổng: ${formatMoney(tongTien)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
                                    else ...[
                                      Text('Tổng: ${formatMoney(tongTien)}',
                                          style: const TextStyle(color: Colors.grey)),
                                      Text('Giảm: -${formatMoney(tienGiam)} (${inv['MaGiamGia'] ?? ''})',
                                          style: const TextStyle(color: Colors.green)),
                                      Text('Thành tiền: ${formatMoney(thanhTien)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.receipt_long, color: Colors.orange),
                                      onPressed: () async {
                                        final items = await ApiService.getInvoiceDetail(inv['Id']);
                                        if (mounted) _showReceipt(inv, items);
                                      },
                                    ),
                                    if (_selectedTab == 0) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreateOrderScreen(
                                                user: {'Id': inv['NhanVienId'] ?? 0},
                                                editHoaDonId: inv['Id'],
                                              ),
                                            ),
                                          );
                                          if (result == true) _loadInvoices();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.payment, color: Colors.green),
                                        onPressed: () => _payInvoice(inv['Id'], tongTien: tongTien),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
