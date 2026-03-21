import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../models/CartItem.dart';
import '../models/Order.dart';  // SỬA: import Order.dart (viết hoa)
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CheckoutItem> items;
  final bool isBuyNow;
  final String? voucherCode;

  const CheckoutScreen({
    super.key,
    required this.items,
    this.isBuyNow = false,
    this.voucherCode,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class CheckoutItem {
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final double price;
  final double subtotal;

  CheckoutItem({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory CheckoutItem.fromCartItem(CartItem item) {
    return CheckoutItem(
      productId: item.productId,
      productName: item.productName,
      imageUrl: item.imageUrl,
      quantity: item.quantity,
      price: item.price,
      subtotal: item.price * item.quantity,
    );
  }

  factory CheckoutItem.fromProduct(Product product, int quantity) {
    return CheckoutItem(
      productId: product.productId,
      productName: product.productName,
      imageUrl: product.imageUrl,
      quantity: quantity,
      price: product.price,
      subtotal: product.price * quantity,
    );
  }
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _paymentMethod = 'cod';
  String _selectedVoucher = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = user.fullName;
        _phoneController.text = user.phone ?? '';
        _addressController.text = '';
      });
    }
  }

  String _formatCurrency(double amount) {
    int roundedAmount = amount.round();
    String formatted = roundedAmount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
    return '$formatted₫';
  }

  double get _totalAmount => 
      widget.items.fold(0, (sum, item) => sum + item.subtotal);
  
  double get _discountAmount {
    if (_selectedVoucher.isEmpty) return 0;
    if (_selectedVoucher == 'SALE10') {
      return _totalAmount * 0.1;
    } else if (_selectedVoucher == 'SALE20') {
      return 20000;
    } else if (_selectedVoucher == 'FREESHIP') {
      return 30000;
    }
    return 0;
  }
  
  double get _finalAmount => _totalAmount - _discountAmount;
  
  int get _totalItems => widget.items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số điện thoại không hợp lệ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    Order? order;

    try {
      if (widget.isBuyNow && widget.items.length == 1) {
        final item = widget.items.first;
        order = await orderProvider.buyNow(
          productId: item.productId,
          quantity: item.quantity,
          paymentMethod: _paymentMethod,
          deliveryAddress: _addressController.text.trim(),
          voucherCode: _selectedVoucher.isNotEmpty ? _selectedVoucher : widget.voucherCode,
        );
      } else {
        order = await orderProvider.createOrderFromCart(
          deliveryAddress: _addressController.text.trim(),
          paymentMethod: _paymentMethod,
          voucherCode: _selectedVoucher.isNotEmpty ? _selectedVoucher : widget.voucherCode,
        );
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        
        if (order != null) {
          if (!widget.isBuyNow) {
            final cartProvider = Provider.of<CartProvider>(context, listen: false);
            await cartProvider.clearCart();
          }
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => OrderSuccessScreen(order: order!),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.error ?? 'Không thể tạo đơn hàng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVoucherDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 450,
              child: Column(
                children: [
                  const Text(
                    'Chọn mã giảm giá',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildVoucherItem(
                          code: 'FREESHIP',
                          discount: 'Miễn phí vận chuyển',
                          condition: 'Đơn tối thiểu 100.000đ',
                          isSelected: _selectedVoucher == 'FREESHIP',
                          onSelect: () {
                            setState(() {
                              _selectedVoucher = _selectedVoucher == 'FREESHIP' ? '' : 'FREESHIP';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildVoucherItem(
                          code: 'SALE10',
                          discount: 'Giảm 10%',
                          condition: 'Tối đa 50.000đ',
                          isSelected: _selectedVoucher == 'SALE10',
                          onSelect: () {
                            setState(() {
                              _selectedVoucher = _selectedVoucher == 'SALE10' ? '' : 'SALE10';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildVoucherItem(
                          code: 'SALE20',
                          discount: 'Giảm 20.000đ',
                          condition: 'Đơn tối thiểu 200.000đ',
                          isSelected: _selectedVoucher == 'SALE20',
                          onSelect: () {
                            setState(() {
                              _selectedVoucher = _selectedVoucher == 'SALE20' ? '' : 'SALE20';
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVoucherItem({
    required String code,
    required String discount,
    required String condition,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF1B5E20).withValues(alpha: 0.1)
                : const Color(0xFFFF6B6B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isSelected ? Icons.check_circle : Icons.local_offer,
            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFFF6B6B),
            size: 20,
          ),
        ),
        title: Text(
          code,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF1B5E20) : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(discount, style: const TextStyle(fontSize: 12)),
            Text(condition, style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: isSelected
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Đã chọn',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : OutlinedButton(
                onPressed: onSelect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                ),
                child: const Text('Áp dụng'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt hàng'),
        backgroundColor: const Color(0xFF0B2A1F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin người nhận
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, color: Color(0xFF1B5E20)),
                                SizedBox(width: 8),
                                Text(
                                  'Thông tin người nhận',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Họ và tên',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập họ tên';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Số điện thoại',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập số điện thoại';
                                    }
                                    if (value.length < 10) {
                                      return 'Số điện thoại không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Địa chỉ giao hàng
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined, color: Color(0xFF1B5E20)),
                                SizedBox(width: 8),
                                Text(
                                  'Địa chỉ giao hàng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Địa chỉ cụ thể (Số nhà, đường, phường/xã, quận/huyện)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập địa chỉ giao hàng';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Danh sách sản phẩm
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sản phẩm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$_totalItems sản phẩm',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...widget.items.map((item) => _buildProductItem(item)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Voucher
                    InkWell(
                      onTap: _showVoucherDialog,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_offer,
                                color: Color(0xFFFF6B6B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Voucher',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_selectedVoucher.isNotEmpty)
                                    Text(
                                      'Đã chọn: $_selectedVoucher',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1B5E20),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ghi chú
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            hintText: 'Ghi chú cho người bán...',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.edit_note),
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Phương thức thanh toán
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Phương thức thanh toán',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          RadioListTile(
                            title: Row(
                              children: [
                                const Icon(Icons.money, size: 20),
                                const SizedBox(width: 8),
                                const Text('Thanh toán khi nhận hàng (COD)'),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Miễn phí',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            value: 'cod',
                            groupValue: _paymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value.toString();
                              });
                            },
                            activeColor: const Color(0xFF1B5E20),
                          ),
                          RadioListTile(
                            title: Row(
                              children: [
                                const Icon(Icons.account_balance, size: 20),
                                const SizedBox(width: 8),
                                const Text('Chuyển khoản ngân hàng'),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Hỗ trợ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            value: 'bank_transfer',
                            groupValue: _paymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value.toString();
                              });
                            },
                            activeColor: const Color(0xFF1B5E20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom bar - tổng tiền
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_discountAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tạm tính:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatCurrency(_totalAmount),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Giảm giá:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '-${_formatCurrency(_discountAmount)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(_finalAmount),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            Text(
                              '(Đã bao gồm VAT)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ĐẶT HÀNG',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(CheckoutItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    _getFullImageUrl(item.imageUrl!),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 30, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 30, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatCurrency(item.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(item.subtotal),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    if (imageUrl.startsWith('/')) {
      return 'https://10.0.2.2:7262$imageUrl';
    }
    return 'https://10.0.2.2:7262/$imageUrl';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}