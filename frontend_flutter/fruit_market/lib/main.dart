import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/review_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/voucher_provider.dart';
import 'providers/order_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'providers/category_provider.dart';

void main() {
  // Bỏ qua SSL certificate cho môi trường development
  HttpOverrides.global = MyHttpOverrides();
  
  runApp(const MyApp());
}

// Class để bỏ qua kiểm tra SSL certificate
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'GreenFruit Market',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
        ),
        // Khai báo tất cả các routes
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
        },
      ),
    );
  }
}
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'providers/auth_provider.dart'; // THÊM AUTH_PROVIDER
// import 'providers/cart_provider.dart';
// import 'providers/product_provider.dart';
// import 'screens/login_screen.dart'; // CHUYỂN THÀNH LOGIN_SCREEN
// import 'screens/register_screen.dart';
// import 'screens/home_screen.dart';

// void main() {
//   // Bỏ qua SSL certificate cho môi trường development
//   HttpOverrides.global = MyHttpOverrides();
  
//   runApp(const MyApp());
// }

// // Class để bỏ qua kiểm tra SSL certificate
// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
//   }
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()), // THÊM AUTH_PROVIDER
//         ChangeNotifierProvider(create: (_) => CartProvider()),
//         ChangeNotifierProvider(create: (_) => ProductProvider()),
//       ],
//       child: MaterialApp(
//         title: 'GreenFruit Market',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           primarySwatch: Colors.green,
//           visualDensity: VisualDensity.adaptivePlatformDensity,
//           fontFamily: 'Roboto',
//           appBarTheme: const AppBarTheme(
//             elevation: 0,
//             centerTitle: true,
//           ),
//         ),
//         // Routes
//         initialRoute: '/login',
//         routes: {
//           '/login': (context) => const LoginScreen(),
//           '/register': (context) => const RegisterScreen(),
//           '/home': (context) => const HomeScreen(),
//         },
//       ),
//     );
//   }
// }