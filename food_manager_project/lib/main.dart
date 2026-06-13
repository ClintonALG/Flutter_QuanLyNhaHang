import 'package:flutter/material.dart';
import 'package:food_manager_project/screens/login_screen.dart';

/// Điểm vào chính của ứng dụng
/// 
/// Khởi tạo Flutter và chạy MaterialApp với màn hình đăng nhập đầu tiên.
/// Ứng dụng kết nối đến SQL Server thông qua API backend Node.js.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Widget gốc của ứng dụng
/// 
/// Cấu hình MaterialApp với theme và route mặc định.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Nhà Hàng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const LoginScreen(),
    );
  }
}
