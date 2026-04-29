import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/order_provider.dart';
import 'providers/user_provider.dart';
import 'providers/voucher_provider.dart';
import 'providers/statistics_provider.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Bỏ check SSL (dev only)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminVoucherProvider()),
        ChangeNotifierProvider(create: (_) => AdminStatisticsProvider()),
      ],
      child: MaterialApp(
        title: 'Admin - GreenFruit Market',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'Roboto',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        // QUAN TRỌNG: Sửa lại home thành widget kiểm tra auth
        home: const AuthCheck(),
        routes: {
          '/login': (context) => const GreenFruitAdminLogin(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

// Thêm widget mới để kiểm tra trạng thái đăng nhập khi khởi động
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Kiểm tra token có tồn tại không
      final token = await ApiService.getToken();
      
      if (token != null && token.isNotEmpty) {
        // Kiểm tra token còn hiệu lực và lấy thông tin user
        final user = await AuthService.getCurrentUser();
        
        if (user != null && user.role.toLowerCase() == 'admin') {
          // Cập nhật AuthProvider
          if (mounted) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            authProvider.setAuthenticatedUser(user);
            setState(() {
              _isAuthenticated = true;
              _isChecking = false;
            });
            return;
          }
        }
      }
      
      // Không có token hoặc token không hợp lệ
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint('❌ AuthCheck error: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Hiển thị màn hình loading khi đang kiểm tra
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                'Đang kiểm tra đăng nhập...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Chuyển hướng dựa trên trạng thái đăng nhập
    if (_isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const GreenFruitAdminLogin();
    }
  }
}