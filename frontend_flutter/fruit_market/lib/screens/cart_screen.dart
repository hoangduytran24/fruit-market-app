import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/Cart.dart';
import '../models/CartItem.dart';
import 'login_screen.dart';
import 'checkout_screen.dart';
import 'package:flutter/services.dart';

// Hàm định dạng tiền Việt Nam Đồng
String _formatCurrency(double amount) {
  int roundedAmount = amount.round();
  String formatted = roundedAmount.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]}.',
  );
  return '$formatted₫';
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isInitialLoad = true;
  final Map<String, int> _itemOrder = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCartData();
    });
  }

  Future<void> _loadCartData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      if (!cartProvider.hasLoaded) {
        await cartProvider.loadCart();
      }
      
      // ✅ Luôn refresh stock khi vào màn hình giỏ hàng
      await cartProvider.refreshCartStock(showWarning: false);
      
      if (cartProvider.cart != null && mounted) {
        setState(() {
          _itemOrder.clear();
          for (var i = 0; i < cartProvider.cart!.items.length; i++) {
            _itemOrder[cartProvider.cart!.items[i].cartItemId] = i;
          }
        });
      }
      
      // ✅ Hiển thị cảnh báo nếu có auto-corrected
      if (cartProvider.hasAutoCorrected && mounted) {
        _showStockAutoCorrectedWarning(cartProvider);
      }
    }
    
    if (mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }
  }
  
  void _showStockAutoCorrectedWarning(CartProvider cartProvider) {
    final overStockItems = cartProvider.cart?.items
        .where((item) => item.quantity > item.stockQuantity)
        .toList() ?? [];
    
    if (overStockItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng đã được cập nhật theo số lượng tồn kho mới nhất'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Cập nhật tồn kho'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Một số sản phẩm đã thay đổi số lượng tồn kho:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...overStockItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${item.productName}: ${item.quantity} -> ${item.stockQuantity}',
                  style: const TextStyle(fontSize: 14),
                ),
              )),
              const SizedBox(height: 12),
              const Text('Số lượng trong giỏ đã được cập nhật tự động.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cartProvider.clearAutoCorrectedFlag();
                Navigator.pop(context);
              },
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _refreshCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.refreshCartStock(showWarning: true);
    
    if (cartProvider.cart != null && mounted) {
      setState(() {
        _itemOrder.clear();
        for (var i = 0; i < cartProvider.cart!.items.length; i++) {
          _itemOrder[cartProvider.cart!.items[i].cartItemId] = i;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final cart = cartProvider.cart;

    if (!authProvider.isAuthenticated) {
      return _buildLoginRequired();
    }

    if (_isInitialLoad && (cartProvider.isLoading || !cartProvider.hasLoaded)) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    if (cartProvider.error != null && cart == null) {
      return _buildErrorView(cartProvider.error!);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          if (cart != null && cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.green),
              onPressed: _refreshCart,
              tooltip: 'Cập nhật tồn kho',
            ),
          if (cart != null && 
              cart.items.isNotEmpty && 
              cartProvider.selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(context, cartProvider),
            ),
        ],
      ),
      body: cart == null || cart.items.isEmpty
          ? buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshCart,
                    color: Colors.green,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final sortedItems = List<CartItem>.from(cart.items);
                        sortedItems.sort((a, b) {
                          final orderA = _itemOrder[a.cartItemId] ?? 999;
                          final orderB = _itemOrder[b.cartItemId] ?? 999;
                          return orderA.compareTo(orderB);
                        });
                        
                        final item = sortedItems[i];
                        return CartItemCard(
                          key: ValueKey(item.cartItemId),
                          item: item,
                          onQuantityChanged: () {
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
                buildCheckoutBar(cartProvider, cart),
              ],
            ),
    );
  }

  Widget _buildLoginRequired() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Vui lòng đăng nhập',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để xem giỏ hàng của bạn',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ).then((_) => _loadCartData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.replaceAll('Exception: ', ''),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  cartProvider.clearError();
                  cartProvider.loadCart();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 30,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Xác nhận xóa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có chắc muốn xóa ${cartProvider.selectedItems.length} sản phẩm đã chọn?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          cartProvider.removeSelectedItems();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 50,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Giỏ hàng trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm sản phẩm vào giỏ hàng nhé!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 45,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mua sắm ngay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCheckoutBar(CartProvider cartProvider, Cart cart) {
    // ✅ Kiểm tra sản phẩm ngừng kinh doanh
    final hasInactiveItem = cart.items.any((item) => !item.isActive);
    final hasOverStockItem = cart.items.any((item) => item.quantity > item.stockQuantity);
    
    String? checkoutError;
    if (hasInactiveItem) {
      checkoutError = 'Có sản phẩm đã ngừng kinh doanh, vui lòng xóa khỏi giỏ hàng';
    } else if (hasOverStockItem) {
      checkoutError = 'Có sản phẩm vượt quá số lượng tồn kho';
    }
    
    final isValidCheckout = cartProvider.totalSelectedAmount > 0 && checkoutError == null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (checkoutError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkoutError,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: cartProvider.isAllSelected,
                      onChanged: (value) => cartProvider.selectAll(),
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chọn tất cả',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Consumer<CartProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          _formatCurrency(provider.totalSelectedAmount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Consumer<CartProvider>(
                    builder: (context, provider, child) {
                      return Tooltip(
                        message: checkoutError ?? 'Tiến hành thanh toán',
                        child: ElevatedButton(
                          onPressed: isValidCheckout
                              ? () => _handleCheckout(context, provider)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isValidCheckout 
                                ? Colors.green 
                                : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isValidCheckout ? 3 : 0,
                          ),
                          child: const Text(
                            'Thanh toán',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cartProvider) async {
    if (cartProvider.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn sản phẩm để thanh toán'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // ✅ Kiểm tra sản phẩm ngừng kinh doanh trước khi thanh toán
    final cart = cartProvider.cart;
    if (cart != null) {
      final inactiveItems = cart.items.where((item) => !item.isActive).toList();
      if (inactiveItems.isNotEmpty) {
        final productNames = inactiveItems.map((item) => item.productName).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sản phẩm "$productNames" đã ngừng kinh doanh, không thể thanh toán'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    final selectedCartItems = cartProvider.cart!.items
        .where((item) => cartProvider.selectedItems.contains(item.cartItemId))
        .toList();
    
    // ✅ Kiểm tra lại stock trước khi thanh toán
    await cartProvider.refreshCartStock(showWarning: true);
    
    // Kiểm tra lại sau khi refresh
    final hasOverStock = selectedCartItems.any((item) => item.quantity > item.stockQuantity);
    if (hasOverStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có sản phẩm trong giỏ đã thay đổi số lượng tồn kho. Vui lòng kiểm tra lại.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: selectedCartItems.map((item) => CheckoutItem.fromCartItem(item)).toList(),
          isBuyNow: false,
        ),
      ),
    );
  }
}

class CartItemCard extends StatefulWidget {
  final CartItem item;
  final VoidCallback? onQuantityChanged;

  const CartItemCard({
    super.key,
    required this.item,
    this.onQuantityChanged,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  bool _isUpdating = false;
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.item.quantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  String? _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http')) return imageUrl;
    if (imageUrl.startsWith('/')) {
      return 'http://10.0.2.2:5280$imageUrl';
    }
    return 'http://10.0.2.2:5280/$imageUrl';
  }

  void _showMaxQuantityWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Số lượng bạn chọn đã đạt mức tối đa của sản phẩm này (Tối đa: ${widget.item.stockQuantity})'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showExceedsStockWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Số lượng nhập vượt quá số lượng tồn kho (Tồn kho: ${widget.item.stockQuantity})'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInactiveWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sản phẩm đã ngừng kinh doanh, không thể cập nhật số lượng'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateQuantity(int newQuantity) async {
    if (_isUpdating) return;
    
    // ✅ Không cho phép cập nhật nếu sản phẩm ngừng kinh doanh
    if (!widget.item.isActive) {
      _showInactiveWarning();
      _quantityController.text = widget.item.quantity.toString();
      return;
    }
    
    // Kiểm tra số lượng vượt quá tồn kho
    if (newQuantity > widget.item.stockQuantity) {
      _showExceedsStockWarning();
      _quantityController.text = widget.item.quantity.toString();
      return;
    }
    
    if (newQuantity <= 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 30,
                    color: Colors.orange.shade400,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Xác nhận xóa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có chắc chắn muốn xóa sản phẩm "${widget.item.productName}" khỏi giỏ hàng?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      
      if (confirm == true) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await cartProvider.removeItem(widget.item.productId);
        widget.onQuantityChanged?.call();
      } else {
        _quantityController.text = widget.item.quantity.toString();
      }
      return;
    }

    setState(() => _isUpdating = true);
    
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.updateQuantity(widget.item.productId, newQuantity);
      HapticFeedback.lightImpact();
      _quantityController.text = newQuantity.toString();
      widget.onQuantityChanged?.call();
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _handleQuantitySubmit(String value) {
    if (_isUpdating) return;
    
    final int? newQuantity = int.tryParse(value);
    if (newQuantity != null && newQuantity > 0) {
      _updateQuantity(newQuantity);
    } else {
      _quantityController.text = widget.item.quantity.toString();
    }
  }

  Future<void> _handleRemove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 30,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Xác nhận xóa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn có chắc chắn muốn xóa "${widget.item.productName}" khỏi giỏ hàng?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Xóa'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (confirm == true) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.removeItem(widget.item.productId);
      widget.onQuantityChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final imageUrl = _getFullImageUrl(widget.item.imageUrl);
    final isOverStock = widget.item.quantity > widget.item.stockQuantity;
    final isInactive = !widget.item.isActive; // ✅ Kiểm tra ngừng kinh doanh
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox (vô hiệu hóa nếu sản phẩm ngừng kinh doanh)
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: isInactive ? false : cartProvider.isSelected(widget.item.cartItemId),
                    onChanged: isInactive ? null : (value) {
                      cartProvider.toggleSelect(widget.item.cartItemId);
                      widget.onQuantityChanged?.call();
                    },
                    activeColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                // Ảnh sản phẩm (thêm opacity nếu ngừng kinh doanh)
                Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: isInactive 
                                ? const ColorFilter.mode(Colors.black38, BlendMode.darken)
                                : null,
                          )
                        : null,
                  ),
                  child: imageUrl == null
                      ? Center(
                          child: Text(
                            widget.item.productName.isNotEmpty ? widget.item.productName[0] : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      : null,
                ),
                // Thông tin sản phẩm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.productName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isInactive ? Colors.grey.shade500 : Colors.black87,
                                decoration: isInactive ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatCurrency(widget.item.price)}/${widget.item.unit}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isInactive ? Colors.grey.shade400 : Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ✅ Vô hiệu hóa nút tăng/giảm số lượng nếu ngừng kinh doanh
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: isInactive ? null : () => _updateQuantity(widget.item.quantity - 1),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isInactive ? Colors.grey.shade200 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: isInactive ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 28,
                              alignment: Alignment.center,
                              child: TextField(
                                controller: _quantityController,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isInactive ? Colors.grey.shade400 : Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onSubmitted: _handleQuantitySubmit,
                                enabled: !isInactive,
                                onTap: () {
                                  if (!isInactive) {
                                    _quantityController.selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _quantityController.text.length,
                                    );
                                  }
                                },
                              ),
                            ),
                            InkWell(
                              onTap: isInactive ? null : () {
                                if (widget.item.quantity >= widget.item.stockQuantity) {
                                  _showMaxQuantityWarning();
                                } else {
                                  _updateQuantity(widget.item.quantity + 1);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isInactive ? Colors.grey.shade200 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: isInactive ? Colors.grey.shade400 : Colors.green.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(widget.item.price * widget.item.quantity),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isInactive ? Colors.grey.shade500 : Colors.black87,
                        decoration: isInactive ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                        padding: EdgeInsets.zero,
                        onPressed: _handleRemove,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ✅ Hiển thị cảnh báo ngừng kinh doanh
          if (isInactive)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sản phẩm đã ngừng kinh doanh, vui lòng xóa khỏi giỏ hàng',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            )
          else if (isOverStock)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Số lượng vượt quá tồn kho (còn ${widget.item.stockQuantity})',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}