import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final bool isConnectionError;
  final int? statusCode;

  ApiException(this.message, {this.isConnectionError = false, this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const bool useLan = false;
  static const String lanIp = '192.168.1.10';
  static const Duration defaultTimeout = Duration(seconds: 10);

  static const String _connectionHelp =
      'Vui lòng kiểm tra:\n'
      '(1) Chạy API backend: npm run dev trong menu-api\n'
      '(2) SQL Server đang hoạt động\n'
      '(3) Địa chỉ IP/port đúng\n'
      '(4) Thiết bị và server cùng mạng (nếu dùng LAN)';

  static String get baseUrl {
    if (useLan) return 'http://$lanIp:3000/api';
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  static Future<dynamic> _get(String path, {Duration? timeout}) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.get(uri).timeout(timeout ?? defaultTimeout);
    return _handleResponse(res);
  }

  static List<Map<String, dynamic>> _asMapList(dynamic data) {
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw ApiException('Dữ liệu từ server không đúng định dạng (expected List).');
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Dữ liệu từ server không đúng định dạng (expected Map).');
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {Duration? timeout}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(timeout ?? defaultTimeout);
    return _asMap(_handleResponse(res));
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body, {Duration? timeout}) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(timeout ?? defaultTimeout);
    return _asMap(_handleResponse(res));
  }

  static Future<Map<String, dynamic>> _delete(String path, {Duration? timeout}) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
    ).timeout(timeout ?? defaultTimeout);
    return _asMap(_handleResponse(res));
  }

  static dynamic _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isNotEmpty ? jsonDecode(res.body) : {'success': true};
    }
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body);
    } catch (_) {}
    final msg = data['message'] as String? ?? 'Lỗi không xác định từ server';
    final isConnErr = data['isConnectionError'] == true || res.statusCode == 503;
    throw ApiException(msg, isConnectionError: isConnErr, statusCode: res.statusCode);
  }

  static Future<T> _request<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Quá thời gian chờ kết nối API.\n$_connectionHelp',
          isConnectionError: true);
    } on SocketException {
      throw ApiException('Mất kết nối đến API backend.\n$_connectionHelp',
          isConnectionError: true);
    } on http.ClientException {
      throw ApiException('Mất kết nối đến API backend.\n$_connectionHelp',
          isConnectionError: true);
    } on HttpException {
      throw ApiException('Lỗi giao tiếp HTTP với server.', isConnectionError: true);
    } on FormatException {
      throw ApiException('Dữ liệu từ server không đúng định dạng.');
    } catch (e) {
      throw ApiException('Lỗi không xác định: $e');
    }
  }

  // ========== Auth ==========

  static Future<Map<String, dynamic>> login(String username, String password) {
    return _request(() => _post('/login', {
      'username': username,
      'password': password,
    }, timeout: const Duration(seconds: 10)).then((data) {
      if (data['success'] == true) return data['user'];
      throw ApiException(data['message'] ?? 'Sai thông tin đăng nhập');
    }));
  }

  static Future<int> register(String username, String password, String fullName, {String role = 'Nhân viên'}) {
    return _request(() => _post('/register', {
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
    }, timeout: const Duration(seconds: 10)).then((data) {
      if (data['success'] == true) return data['userId'];
      throw ApiException(data['message'] ?? 'Đăng ký thất bại');
    }));
  }

  // ========== Tables ==========

  static Future<List<Map<String, dynamic>>> getTables() {
    return _request(() => _get('/tables').then(_asMapList));
  }

  static Future<void> updateTableStatus(int tableId, String status) {
    return _request(() => _put('/tables/$tableId', {'trangThai': status}, timeout: const Duration(seconds: 5)).then((_) {}));
  }

  static Future<void> renameTable(int tableId, String tenBan) {
    return _request(() => _put('/tables/$tableId/rename', {'tenBan': tenBan}).then((data) {
      if (data['success'] != true) throw ApiException(data['message'] ?? 'Không thể dồn bàn');
    }));
  }

  // ========== Menu ==========

  static Future<List<Map<String, dynamic>>> getMenu({String? category, String? search}) {
    return _request(() {
      final q = <String, String>{};
      if (category != null && category != 'All') q['category'] = category;
      if (search != null && search.isNotEmpty) q['search'] = search;
      final query = q.isNotEmpty ? '?${q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}' : '';
      return _get('/menu$query').then(_asMapList);
    });
  }

  static Future<List<Map<String, dynamic>>> getCategories() {
    return _request(() => _get('/categories').then(_asMapList));
  }

  // ========== Orders ==========

  static Future<Map<String, dynamic>> createOrder({
    required int banId,
    required int nhanVienId,
    required List<Map<String, dynamic>> items,
  }) {
    return _request(() => _post('/orders', {
      'banId': banId,
      'nhanVienId': nhanVienId,
      'items': items,
    }, timeout: const Duration(seconds: 15)).then((data) {
      if (data['success'] != true) throw ApiException(data['message'] ?? 'Đặt hàng thất bại');
      return data;
    }));
  }

  static Future<void> payInvoice(int hoaDonId, {String? maGiamGia}) {
    return _request(() => _post('/payment', {
      'hoaDonId': hoaDonId,
      'maGiamGia': maGiamGia,
    }).then((data) {
      if (data['success'] != true) throw ApiException(data['message'] ?? 'Thanh toán thất bại');
    }));
  }

  // ========== Invoices ==========

  static Future<List<Map<String, dynamic>>> getInvoices({String? status}) {
    return _request(() {
      final query = status != null ? '?${Uri(queryParameters: {'status': status}).query}' : '';
      return _get('/invoices$query').then(_asMapList);
    });
  }

  static Future<List<Map<String, dynamic>>> getInvoiceDetail(int hoaDonId) {
    return _request(() => _get('/invoices/$hoaDonId').then(_asMapList));
  }

  static Future<void> deleteOrderItem(int hoaDonId, int chiTietId) {
    return _request(() => _delete('/orders/$hoaDonId/items/$chiTietId').then((data) {
      if (data['success'] != true) throw ApiException(data['message'] ?? 'Không thể xóa món');
    }));
  }

  static Future<Map<String, dynamic>> checkVoucher(String ma, {int tongTien = 0}) {
    return _request(() => _post('/vouchers/check', {'ma': ma, 'tongTien': tongTien}));
  }
}
