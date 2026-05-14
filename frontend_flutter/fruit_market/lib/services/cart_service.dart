import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Cart.dart';
import '../models/product.dart';
import 'api_service.dart';

class CartService {
  // Lấy giỏ hàng
  Future<Cart> getCart() async {
    try {
      final headers = await ApiService.authHeaders;
      print('📦 Getting cart...');
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}Cart'),
        headers: headers,
      );

      print('📦 Get cart response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          final now = DateTime.now();
          return Cart(
            cartId: '',
            userId: '',
            createdAt: now,
            updatedAt: now,
            items: [],
            totalItems: 0,
            totalPrice: 0,
          );
        }
        return Cart.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        final now = DateTime.now();
        return Cart(
          cartId: '',
          userId: '',
          createdAt: now,
          updatedAt: now,
          items: [],
          totalItems: 0,
          totalPrice: 0,
        );
      } else {
        String errorMessage = 'Không thể tải giỏ hàng';
        try {
          if (response.body.isNotEmpty) {
            final error = json.decode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Get cart error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ✅ REFRESH STOCK - Gọi API refresh-stock
  Future<Cart> refreshCartStock() async {
    try {
      final headers = await ApiService.authHeaders;
      print('📦 Refreshing cart stock...');
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}Cart/refresh-stock'),
        headers: headers,
      );

      print('📦 Refresh stock response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          final now = DateTime.now();
          return Cart(
            cartId: '',
            userId: '',
            createdAt: now,
            updatedAt: now,
            items: [],
            totalItems: 0,
            totalPrice: 0,
          );
        }
        return Cart.fromJson(json.decode(response.body));
      } else {
        String errorMessage = 'Không thể cập nhật tồn kho';
        try {
          if (response.body.isNotEmpty) {
            final error = json.decode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Refresh stock error: $e');
      throw Exception('Lỗi: $e');
    }
  }

  // Thêm sản phẩm vào giỏ
  Future<Cart> addToCart(Product product, int quantity) async {
    try {
      final headers = await ApiService.authHeaders;
      print('📦 Adding to cart - Product: ${product.productId}, Quantity: $quantity');
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}Cart/add'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'productId': product.productId,
          'quantity': quantity,
        }),
      );

      print('📦 Add to cart response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return await getCart();
        }
        return Cart.fromJson(json.decode(response.body));
      } else {
        String errorMessage = 'Không thể thêm vào giỏ hàng';
        try {
          if (response.body.isNotEmpty) {
            final error = json.decode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Add to cart error: $e');
      throw Exception('$e');
    }
  }

  // Cập nhật số lượng
  Future<Cart> updateQuantity(String productId, int quantity) async {
    try {
      final headers = await ApiService.authHeaders;
      print('📦 Updating quantity - Product: $productId, Quantity: $quantity');
      
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}Cart/update/$productId'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quantity': quantity,
        }),
      );

      print('📦 Update quantity response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return await getCart();
        }
        return Cart.fromJson(json.decode(response.body));
      } else {
        String errorMessage = 'Không thể cập nhật số lượng';
        try {
          if (response.body.isNotEmpty) {
            final error = json.decode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Update quantity error: $e');
      throw Exception('Lỗi: $e');
    }
  }

  // Xóa sản phẩm khỏi giỏ
  Future<Cart> removeFromCart(String productId) async {
    try {
      final headers = await ApiService.authHeaders;
      print('📦 Removing from cart - Product: $productId');
      
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}Cart/remove/$productId'),
        headers: headers,
      );

      print('📦 Remove from cart response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return await getCart();
      } else {
        String errorMessage = 'Không thể xóa sản phẩm';
        try {
          if (response.body.isNotEmpty) {
            final error = json.decode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Remove from cart error: $e');
      throw Exception('Lỗi: $e');
    }
  }

  // Xóa giỏ hàng
  Future<bool> clearCart() async {
    try {
      final headers = await ApiService.authHeaders;
      print('📦 Clearing cart...');
      
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}Cart/clear'),
        headers: headers,
      );

      print('📦 Clear cart response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        String errorMessage = 'Không thể xóa giỏ hàng';
        try {
          if (response.body.isNotEmpty) {
            final error = json.decode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Clear cart error: $e');
      return false;
    }
  }

  // Thanh toán với danh sách cartItemIds
  Future<bool> checkout(List<String> cartItemIds) async {
    try {
      final headers = await ApiService.authHeaders;
      print('📦 Processing checkout for items: $cartItemIds');
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}Cart/checkout'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'cartItemIds': cartItemIds,
        }),
      );

      print('📦 Checkout response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        String errorMessage = 'Thanh toán thất bại';
        try {
          if (response.body.isNotEmpty) {
            final error = json.decode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Checkout error: $e');
      return false;
    }
  }

  // ========== THÊM MỚI: Tạo đơn với danh sách sản phẩm được chọn ==========
  Future<Map<String, dynamic>> createOrderFromSelectedItems({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String paymentMethod,
    required String receiverName,
    required String receiverPhone,
    String? voucherCode,
    double shippingFee = 25000,
  }) async {
    try {
      final headers = await ApiService.authHeaders;
      print('📦 Creating order from selected items: $items');
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}orders/from-selected-items'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'items': items,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          'receiverName': receiverName,
          'receiverPhone': receiverPhone,
          'voucherCode': voucherCode,
          'shippingFee': shippingFee,
        }),
      );

      print('📦 Create order response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        String errorMessage = 'Không thể tạo đơn hàng';
        try {
          if (response.body.isNotEmpty) {
            final error = json.decode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('❌ Create order error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}