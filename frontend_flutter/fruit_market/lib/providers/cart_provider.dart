import 'package:flutter/material.dart';
import '../models/Cart.dart';
import '../models/CartItem.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;
  String? _error;
  Set<String> _selectedItems = {};

  // Getters
  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get selectedItems => _selectedItems;
  
  int get itemCount {
    if (_cart?.items.isEmpty ?? true) return 0;
    return _cart!.items.fold(0, (sum, item) => sum + item.quantity);
  }
  
  int get itemTypesCount => _cart?.items.length ?? 0;
  
  List<CartItem> get items => _cart?.items ?? [];
  
  double get totalAmount {
    if (_cart?.items.isEmpty ?? true) return 0;
    return _cart!.items.fold<double>(
      0, 
      (sum, item) => sum + (item.price * item.quantity)
    );
  }
  
  double get totalSelectedAmount {
    if (_cart?.items.isEmpty ?? true) return 0;
    
    return _cart!.items
        .where((item) => _selectedItems.contains(item.cartItemId))
        .fold<double>(
          0,
          (sum, item) => sum + (item.price * item.quantity),
        );
  }
  
  bool isSelected(String cartItemId) => _selectedItems.contains(cartItemId);
  
  bool get isAllSelected {
    if (_cart?.items.isEmpty ?? true) return false;
    return _selectedItems.length == _cart!.items.length;
  }

  final CartService _cartService = CartService();

  Future<void> loadCart() async {
    _setLoading(true);
    _clearError();

    try {
      _cart = await _cartService.getCart();
      if (_cart?.items.isNotEmpty ?? false) {
        _selectedItems = Set.from(_cart!.items.map((e) => e.cartItemId));
      } else {
        _selectedItems.clear();
      }
      _setLoading(false);
    } catch (e) {
      print('❌ Load cart error: $e');
      _setError('Không thể tải giỏ hàng');
    }
  }

  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    _setLoading(true);
    _clearError();

    try {
      final newCart = await _cartService.addToCart(product, quantity);
      _cart = newCart;
      
      if (_cart?.items.isNotEmpty ?? false) {
        try {
          final newItem = _cart!.items.firstWhere(
            (item) => item.productId == product.productId,
          );
          _selectedItems.add(newItem.cartItemId);
        } catch (e) {
          print('⚠️ Item not found in cart after adding');
        }
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Add to cart error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity < 1) {
      return await removeItem(productId);
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedCart = await _cartService.updateQuantity(productId, newQuantity);
      _cart = updatedCart;
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Update quantity error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> removeItem(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      String? itemIdToRemove;
      final itemToRemove = _cart?.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => null as CartItem,
      );
      
      if (itemToRemove != null) {
        itemIdToRemove = itemToRemove.cartItemId;
      }
      
      final updatedCart = await _cartService.removeFromCart(productId);
      _cart = updatedCart;
      
      if (itemIdToRemove != null) {
        _selectedItems.remove(itemIdToRemove);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Remove item error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> removeSelectedItems() async {
    if (_selectedItems.isEmpty) return true;

    _setLoading(true);
    _clearError();

    try {
      final itemsToRemove = _selectedItems.toList();
      Cart? latestCart = _cart;
      
      for (var itemId in itemsToRemove) {
        final item = latestCart?.items.firstWhere(
          (i) => i.cartItemId == itemId,
          orElse: () => null as CartItem,
        );
        
        if (item != null) {
          latestCart = await _cartService.removeFromCart(item.productId);
        }
      }
      
      _cart = latestCart;
      _selectedItems.clear();
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Remove selected items error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  void toggleSelect(String cartItemId) {
    if (_selectedItems.contains(cartItemId)) {
      _selectedItems.remove(cartItemId);
    } else {
      _selectedItems.add(cartItemId);
    }
    notifyListeners();
  }

  void selectAll() {
    if (_cart?.items.isEmpty ?? true) return;
    
    if (isAllSelected) {
      _selectedItems.clear();
    } else {
      _selectedItems = Set.from(_cart!.items.map((e) => e.cartItemId));
    }
    notifyListeners();
  }

  /// Xóa toàn bộ giỏ hàng
  Future<bool> clearCart() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _cartService.clearCart();
      if (success) {
        _cart = null;
        _selectedItems.clear();
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      print('❌ Clear cart error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Thanh toán với các sản phẩm đã chọn
  Future<bool> checkout() async {
    if (_selectedItems.isEmpty) {
      _setError('Vui lòng chọn sản phẩm để thanh toán');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final selectedCartItemIds = _selectedItems.toList();
      final success = await _cartService.checkout(selectedCartItemIds);
      
      if (success) {
        _cart = await _cartService.getCart();
        _selectedItems.clear();
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      print('❌ Checkout error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  int getItemQuantity(String productId) {
    if (_cart?.items.isEmpty ?? true) return 0;
    try {
      final item = _cart!.items.firstWhere((item) => item.productId == productId);
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  bool hasProduct(String productId) {
    if (_cart?.items.isEmpty ?? true) return false;
    try {
      _cart!.items.firstWhere((item) => item.productId == productId);
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}