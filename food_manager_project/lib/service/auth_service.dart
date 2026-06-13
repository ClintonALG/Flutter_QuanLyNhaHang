import 'package:food_manager_project/service/api_service.dart';

/// Service xác thực người dùng
/// 
/// Cung cấp các phương thức đăng nhập và đăng ký,
/// gọi API backend để tương tác với SQL Server.
class AuthService {
  /// Đăng nhập với tên đăng nhập và mật khẩu
  /// 
  /// Gọi API backend -> stored procedure sp_DangNhap trên SQL Server.
  /// Trả về thông tin user nếu thành công, ném Exception nếu thất bại.
  static Future<Map<String, dynamic>> login(String username, String password) async {
    return await ApiService.login(username, password);
  }

  /// Đăng ký tài khoản mới
  /// 
  /// Gọi API backend -> stored procedure sp_DangKy.
  /// Trả về userId nếu thành công.
  static Future<int> register(String username, String password, String role) async {
    return await ApiService.register(username, password, username, role: role);
  }
}
