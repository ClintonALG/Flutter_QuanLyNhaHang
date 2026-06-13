import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service gọi API backend Node.js kết nối SQL Server
/// 
/// Tất cả các request đều qua HTTP để tương tác với backend,
/// backend sẽ kết nối đến SQL Server và thực thi stored procedure.
class ApiService {
  // Đổi true để chạy qua LAN/WAN, false để chạy local
  static const bool useLan = true;
  static const String lanIp = '192.168.1.10';

  static String get baseUrl {
    if (useLan) return 'http://$lanIp:3000/api';
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  // ============================================================
  // Xác thực (Authentication)
  // ============================================================

  /// Đăng nhập - gọi API backend -> stored procedure sp_DangNhap
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['user'];
        } else {
          throw Exception(data['message'] ?? 'Sai thông tin đăng nhập');
        }
      } else {
        throw Exception('Đăng nhập thất bại');
      }
    } on SocketException {
      throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra mạng.');
    } on HttpException {
      throw Exception('Lỗi kết nối HTTP');
    }
  }

  /// Đăng ký tài khoản mới - gọi sp_DangKy
  static Future<int> register(String username, String password, String fullName, {String role = 'Nhân viên'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'fullName': fullName,
          'role': role
        }),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['userId'];
      } else {
        throw Exception(data['message'] ?? 'Đăng ký thất bại');
      }
    } on SocketException {
      throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra mạng.');
    }
  }

  // ============================================================
  // Bàn ăn (Tables)
  // ============================================================

  /// Lấy danh sách tất cả bàn
  static Future<List<Map<String, dynamic>>> getTables() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tables'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Không thể lấy danh sách bàn');
    } on SocketException {
      throw Exception('Mất kết nối server');
    }
  }

  /// Cập nhật trạng thái bàn
  static Future<void> updateTableStatus(int tableId, String status) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/tables/$tableId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'trangThai': status}),
      ).timeout(const Duration(seconds: 5));
    } on SocketException {
      throw Exception('Mất kết nối server');
    }
  }

  // ============================================================
  // Thực đơn (Menu)
  // ============================================================

  /// Lấy danh sách món ăn (có thể lọc theo danh mục và tìm kiếm)
  static Future<List<Map<String, dynamic>>> getMenu({String? category, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'All') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      final uri = Uri.parse('$baseUrl/menu').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Không thể lấy thực đơn');
    } on SocketException {
      throw Exception('Mất kết nối server');
    }
  }

  /// Lấy danh sách danh mục (Đồ ăn, Đồ uống, Tráng miệng)
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Không thể lấy danh mục');
    } on SocketException {
      throw Exception('Mất kết nối server');
    }
  }

  // ============================================================
  // Đặt hàng (Orders)
  // ============================================================

  /// Tạo đơn hàng mới - gọi stored procedure sp_DatHang (có Transaction)
  static Future<Map<String, dynamic>> createOrder({
    required int banId,
    required int nhanVienId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'banId': banId,
          'nhanVienId': nhanVienId,
          'items': items,
        }),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Đặt hàng thất bại');
      }
    } on SocketException {
      throw Exception('Mất kết nối server. Vui lòng thử lại.');
    }
  }

  /// Thanh toán hóa đơn - gọi stored procedure sp_ThanhToan
  static Future<void> payInvoice(int hoaDonId, {String? maGiamGia}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hoaDonId': hoaDonId,
          'maGiamGia': maGiamGia
        }),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Thanh toán thất bại');
      }
    } on SocketException {
      throw Exception('Mất kết nối server');
    }
  }

  // ============================================================
  // Hóa đơn (Invoices)
  // ============================================================

  /// Lấy danh sách hóa đơn theo trạng thái
  static Future<List<Map<String, dynamic>>> getInvoices({String? status}) async {
    try {
      final queryParams = status != null ? '?status=$status' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/invoices$queryParams'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Không thể lấy hóa đơn');
    } on SocketException {
      throw Exception('Mất kết nối server');
    }
  }

  /// Lấy chi tiết hóa đơn theo ID
  static Future<List<Map<String, dynamic>>> getInvoiceDetail(int hoaDonId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/$hoaDonId'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Không thể lấy chi tiết hóa đơn');
    } on SocketException {
      throw Exception('Mất kết nối server');
    }
  }

  /// Kiểm tra mã giảm giá - gọi sp_KiemTraVoucher
  static Future<Map<String, dynamic>> checkVoucher(String ma, {int tongTien = 0}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vouchers/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ma': ma, 'tongTien': tongTien}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Không thể kiểm tra mã giảm giá');
    } on SocketException {
      throw Exception('Mất kết nối server');
    }
  }
}
