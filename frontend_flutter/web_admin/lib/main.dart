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

void main() {
  runApp(const MyApp());
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
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (authProvider.isAuthenticated && authProvider.currentUser?.role == 'admin') {
              return const DashboardScreen();
            }
            return const GreenFruitAdminLogin();
          },
        ),
        routes: {
          '/login': (context) => const GreenFruitAdminLogin(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}