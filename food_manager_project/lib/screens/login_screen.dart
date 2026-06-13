import 'package:flutter/material.dart';
import 'package:food_manager_project/screens/home_screen.dart';
import 'package:food_manager_project/service/api_service.dart';

/// Màn hình đăng nhập
/// 
/// Cho phép nhân viên đăng nhập bằng tên tài khoản và mật khẩu.
/// Kết nối đến SQL Server thông qua API backend để xác thực.
/// Có validation đầu vào trước khi gửi request.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  /// Xử lý đăng nhập
  /// 
  /// Kiểm tra validation đầu vào, gọi API đăng nhập,
  /// nếu thành công thì chuyển đến HomeScreen.
  /// Nếu lỗi mạng hoặc sai thông tin, hiển thị thông báo lỗi.
  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Validation: kiểm tra không được để trống
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ tài khoản và mật khẩu');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final user = await ApiService.login(username, password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      // Xử lý timeout và lỗi mạng: hiển thị dialog hướng dẫn
      if (e.toString().contains('kết nối') || e.toString().contains('timed out')) {
        if (mounted) _showConnectionErrorDialog();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Hiển thị dialog khi mất kết nối server
  void _showConnectionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mất kết nối'),
        content: const Text('Không thể kết nối đến SQL Server.\n'
            'Vui lòng kiểm tra:\n'
            '1. Server backend đã chạy (npm start)\n'
            '2. SQL Server đang hoạt động\n'
            '3. Kết nối mạng giữa thiết bị và server'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Hình nền
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images_foods/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Lớp phủ tối
          Container(color: Colors.black.withValues(alpha: 0.5)),
          // Nội dung chính
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images_foods/logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Amore Pizza',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên tài khoản',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
