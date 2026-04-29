import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/order_provider.dart';
import '../providers/voucher_provider.dart';
import 'shop_screen.dart';
import 'vouchers_screen.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'favorite_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    const ShopScreen(),
    const VouchersScreen(),
    const CartScreen(),
    const ChatScreen(),
    const FavoriteScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    
    // Load tất cả dữ liệu cần thiết ngay từ đầu
    await Future.wait([
      _loadUserData(authProvider),
      _loadProducts(productProvider),
      _loadCategories(categoryProvider),
      _loadFavorites(favoriteProvider, authProvider),
      _loadOrders(orderProvider, authProvider),
      _loadCart(cartProvider, authProvider),
      _loadVouchers(voucherProvider, authProvider),
    ]);
    
    _isInitialized = true;
  }

  Future<void> _loadUserData(AuthProvider authProvider) async {
    if (!authProvider.hasLoaded) {
      await authProvider.ensureAuthLoaded();
    }
  }

  Future<void> _loadProducts(ProductProvider productProvider) async {
    if (!productProvider.hasLoaded) {
      await productProvider.loadProducts();
    }
  }

  Future<void> _loadCategories(CategoryProvider categoryProvider) async {
    if (!categoryProvider.hasLoaded) {
      await categoryProvider.fetchCategories();
    }
  }

  Future<void> _loadFavorites(FavoriteProvider favoriteProvider, AuthProvider authProvider) async {
    if (authProvider.isAuthenticated && !favoriteProvider.hasLoaded) {
      await favoriteProvider.ensureFavoritesLoaded();
    }
  }

  Future<void> _loadOrders(OrderProvider orderProvider, AuthProvider authProvider) async {
    if (authProvider.isAuthenticated && !orderProvider.hasLoaded) {
      await orderProvider.fetchMyOrders();
    }
  }

  Future<void> _loadCart(CartProvider cartProvider, AuthProvider authProvider) async {
    if (authProvider.isAuthenticated && !cartProvider.hasLoaded) {
      await cartProvider.loadCart();
    }
  }

  Future<void> _loadVouchers(VoucherProvider voucherProvider, AuthProvider authProvider) async {
    // Load available vouchers
    if (!voucherProvider.hasLoadedAvailable) {
      await voucherProvider.loadAvailableVouchers();
    }
    
    // Load saved vouchers nếu đã đăng nhập
    if (authProvider.isAuthenticated && !voucherProvider.hasLoadedSaved) {
      await voucherProvider.loadSavedVouchers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    // final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        items: [
          // Shop
          BottomNavigationBarItem(
            icon: _buildIconWithCircle(
              icon: Icons.store_outlined,
              isSelected: _selectedIndex == 0,
            ),
            activeIcon: _buildIconWithCircle(
              icon: Icons.store,
              isSelected: _selectedIndex == 0,
            ),
            label: 'Shop',
          ),
          
          // Vouchers
          BottomNavigationBarItem(
            icon: _buildIconWithCircle(
              icon: Icons.local_offer_outlined,
              isSelected: _selectedIndex == 1,
            ),
            activeIcon: _buildIconWithCircle(
              icon: Icons.local_offer,
              isSelected: _selectedIndex == 1,
            ),
            label: 'Vouchers',
          ),
          
          // Cart với badge
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildIconWithCircle(
                  icon: Icons.shopping_cart_outlined,
                  isSelected: _selectedIndex == 2,
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildIconWithCircle(
                  icon: Icons.shopping_cart,
                  isSelected: _selectedIndex == 2,
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          
          // Chat
          BottomNavigationBarItem(
            icon: _buildIconWithCircle(
              icon: Icons.chat_outlined,
              isSelected: _selectedIndex == 3,
            ),
            activeIcon: _buildIconWithCircle(
              icon: Icons.chat,
              isSelected: _selectedIndex == 3,
            ),
            label: 'Chat',
          ),
          
          // Favorite
          BottomNavigationBarItem(
            icon: _buildIconWithCircle(
              icon: Icons.favorite_outlined,
              isSelected: _selectedIndex == 4,
            ),
            activeIcon: _buildIconWithCircle(
              icon: Icons.favorite,
              isSelected: _selectedIndex == 4,
            ),
            label: 'Favorite',
          ),
          
          // Account
          BottomNavigationBarItem(
            icon: _buildIconWithCircle(
              icon: Icons.person_outlined,
              isSelected: _selectedIndex == 5,
            ),
            activeIcon: _buildIconWithCircle(
              icon: Icons.person,
              isSelected: _selectedIndex == 5,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildIconWithCircle({
    required IconData icon,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Colors.green.withOpacity(0.15) : Colors.transparent,
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.green : Colors.grey,
        size: 22,
      ),
    );
  }
}