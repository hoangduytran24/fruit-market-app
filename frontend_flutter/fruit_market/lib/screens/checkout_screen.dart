import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/voucher_provider.dart';
import '../models/product.dart';
import '../models/CartItem.dart';
import '../models/Order.dart';
import '../models/user_voucher.dart';
import '../models/Voucher.dart';
import '../utils/image_utils.dart';
import 'vietqr_payment_screen.dart';

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
  
  // ========== THÔNG TIN NGƯỜI NHẬN ==========
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  // ==========================================
  
  final _noteController = TextEditingController();
  
  String _paymentMethod = 'cod';
  UserVoucher? _selectedUserVoucher;
  bool _isProcessing = false;
  bool _isLoadingVouchers = true;

  // Color scheme
  final Color _primaryColor = const Color(0xFF10B981);
  final Color _secondaryColor = const Color(0xFF059669);
  final Color _accentColor = const Color(0xFF8B5CF6);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadVouchers();
  }

  Future<void> _loadUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      setState(() {
        // Lấy thông tin người nhận từ user làm giá trị mặc định
        _receiverNameController.text = user.fullName;
        _receiverPhoneController.text = user.phone;
        _addressController.text = '';
      });
    }
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoadingVouchers = true);
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    await voucherProvider.loadSavedVouchers();
    if (mounted) {
      setState(() => _isLoadingVouchers = false);
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
    if (_selectedUserVoucher == null) return 0;
    final voucher = _selectedUserVoucher!.voucher;
    if (voucher == null) return 0;
    
    if (voucher.discountType.toLowerCase() == 'percent' ||
        voucher.discountType.toLowerCase() == 'percentage') {
      double discount = _totalAmount * (voucher.discountValue / 100);
      if (voucher.maxDiscountValue != null && discount > voucher.maxDiscountValue!) {
        discount = voucher.maxDiscountValue!;
      }
      return discount;
    } else {
      return voucher.discountValue;
    }
  }
  
  double get _finalAmount => _totalAmount - _discountAmount;
  bool _isVoucherValid(VoucherPublicDto voucher) {
    if (voucher.isExpired) return false;
    if (_totalAmount < voucher.minOrderValue) return false;
    return true;
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate thông tin người nhận
    if (_receiverNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập tên người nhận');
      return;
    }
    if (_receiverPhoneController.text.trim().length < 10) {
      _showErrorSnackBar('Số điện thoại người nhận không hợp lệ');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập địa chỉ giao hàng');
      return;
    }

    // Nếu chọn chuyển khoản ngân hàng -> chuyển sang màn hình QR
    if (_paymentMethod == 'bank_transfer') {
      setState(() => _isProcessing = true);
      
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      Order? order;
      
      try {
        final voucherCode = _selectedUserVoucher?.voucher?.voucherCode;
        
        if (widget.isBuyNow && widget.items.length == 1) {
          final item = widget.items.first;
          order = await orderProvider.buyNow(
            productId: item.productId,
            quantity: item.quantity,
            paymentMethod: 'bank_transfer',
            deliveryAddress: _addressController.text.trim(),
            receiverName: _receiverNameController.text.trim(),
            receiverPhone: _receiverPhoneController.text.trim(),
            voucherCode: voucherCode ?? widget.voucherCode,
          );
        } else {
          order = await orderProvider.createOrderFromCart(
            deliveryAddress: _addressController.text.trim(),
            paymentMethod: 'bank_transfer',
            receiverName: _receiverNameController.text.trim(),
            receiverPhone: _receiverPhoneController.text.trim(),
            voucherCode: voucherCode ?? widget.voucherCode,
          );
        }
        
        setState(() => _isProcessing = false);
        
        if (order != null) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VietQRPaymentScreen(
                  orderId: order!.orderId,
                  amount: _finalAmount + 25000,
                ),
              ),
            ).then((result) {
              if (result == true) {
                if (!widget.isBuyNow) {
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  cartProvider.clearCart();
                }
                _showSuccessDialog();
              }
            });
          }
        } else {
          _showErrorSnackBar(orderProvider.error ?? 'Không thể tạo đơn hàng');
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
      return;
    }
    
    // COD
    setState(() => _isProcessing = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    Order? order;

    try {
      final voucherCode = _selectedUserVoucher?.voucher?.voucherCode;
      
      if (widget.isBuyNow && widget.items.length == 1) {
        final item = widget.items.first;
        order = await orderProvider.buyNow(
          productId: item.productId,
          quantity: item.quantity,
          paymentMethod: _paymentMethod,
          deliveryAddress: _addressController.text.trim(),
          receiverName: _receiverNameController.text.trim(),
          receiverPhone: _receiverPhoneController.text.trim(),
          voucherCode: voucherCode ?? widget.voucherCode,
        );
      } else {
        order = await orderProvider.createOrderFromCart(
          deliveryAddress: _addressController.text.trim(),
          paymentMethod: _paymentMethod,
          receiverName: _receiverNameController.text.trim(),
          receiverPhone: _receiverPhoneController.text.trim(),
          voucherCode: voucherCode ?? widget.voucherCode,
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
            _showSuccessDialog();
          }
        } else {
          _showErrorSnackBar(orderProvider.error ?? 'Không thể tạo đơn hàng');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(
                  'Đặt hàng thành công!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Cảm ơn bạn đã đặt hàng. Đơn hàng của bạn đang được xử lý và sẽ được giao sớm nhất.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng thanh toán:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(_finalAmount + 25000)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: _primaryColor.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Về trang chủ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade300,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: _primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Thanh toán',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _textPrimary),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: _isProcessing
          ? _buildLoadingScreen()
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Thông tin nhận hàng', Icons.local_shipping_outlined),
                          _buildDeliveryInfoCard(),
                          
                          const SizedBox(height: 28),
                          
                          _buildSectionHeader('Ghi chú đơn hàng', Icons.note_add_outlined),
                          _buildNoteCard(),
                          
                          const SizedBox(height: 28),
                          
                          _buildSectionHeader('Mã giảm giá', Icons.discount_outlined),
                          _buildCouponSection(),
                          
                          const SizedBox(height: 28),
                          
                          _buildSectionHeader('Phương thức thanh toán', Icons.payment_outlined),
                          _buildPaymentMethod(),
                          
                          const SizedBox(height: 28),
                          
                          _buildSectionHeader('Sản phẩm đã chọn', Icons.shopping_bag_outlined),
                          _buildSelectedProducts(),
                          
                          const SizedBox(height: 28),
                          
                          _buildTotalSection(),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang xử lý đơn hàng...',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng không thoát ứng dụng',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin người nhận',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Tên người nhận
          _buildEditableInfoField(
            controller: _receiverNameController,
            icon: Icons.person_outline,
            label: 'Tên người nhận',
            validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên người nhận' : null,
          ),
          const SizedBox(height: 12),
          
          // Số điện thoại người nhận
          _buildEditableInfoField(
            controller: _receiverPhoneController,
            icon: Icons.phone_iphone_outlined,
            label: 'Số điện thoại',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại người nhận';
              if (value.length < 10) return 'Số điện thoại không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 12),
          
          // Địa chỉ giao hàng
          _buildEditableInfoField(
            controller: _addressController,
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ giao hàng',
            validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập địa chỉ giao hàng' : null,
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: _primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bạn có thể thay đổi thông tin người nhận nếu muốn giao hàng cho người khác',
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _textSecondary,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: controller,
                style: TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Nhập $label',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: _textSecondary.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                keyboardType: keyboardType,
                validator: validator,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú cho đơn hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            style: TextStyle(color: _textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ví dụ: Giao hàng giờ hành chính, gọi điện trước khi giao...',
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
              ),
              filled: true,
              fillColor: _backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mã giảm giá',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_selectedUserVoucher == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showVoucherDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _backgroundColor,
                  foregroundColor: _textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.discount_outlined, color: _primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Chọn mã giảm giá',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.discount_outlined, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedUserVoucher!.voucher!.voucherCode,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        Text(
                          _getVoucherDiscountText(_selectedUserVoucher!.voucher),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeCoupon,
                    icon: Icon(Icons.close, color: _textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPaymentOption(
            value: 'cod',
            title: 'Thanh toán khi nhận hàng (COD)',
            subtitle: 'Thanh toán bằng tiền mặt khi nhận hàng',
            icon: Icons.money_outlined,
            color: _primaryColor,
            isSelected: _paymentMethod == 'cod',
            onChanged: (value) => setState(() => _paymentMethod = 'cod'),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            value: 'bank_transfer',
            title: 'Chuyển khoản ngân hàng',
            subtitle: 'Thanh toán qua chuyển khoản ngân hàng (VietQR)',
            icon: Icons.account_balance_outlined,
            color: _accentColor,
            isSelected: _paymentMethod == 'bank_transfer',
            onChanged: (value) => setState(() => _paymentMethod = 'bank_transfer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : _textSecondary.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _paymentMethod,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? color : _textSecondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : _textSecondary,
            size: 20,
          ),
        ),
        activeColor: color,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSelectedProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: widget.items.map((item) {
          final imageUrl = ImageUtils.getOriginalImage(item.imageUrl);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: _backgroundColor,
                              child: Icon(Icons.broken_image, color: Colors.grey[400]),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: _backgroundColor,
                          child: Icon(Icons.shopping_bag_outlined, color: _textSecondary.withOpacity(0.5)),
                        ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatCurrency(item.price)} x ${item.quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Text(
                  _formatCurrency(item.subtotal),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTotalRow('Tổng tiền hàng', _totalAmount),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 10),
            _buildTotalRow('Giảm giá', -_discountAmount, isDiscount: true),
          ],
          const SizedBox(height: 10),
          _buildTotalRow('Phí vận chuyển', 25000),
          const SizedBox(height: 10),
          _buildDivider(),
          const SizedBox(height: 10),
          _buildTotalRow('Tổng thanh toán', _finalAmount + 25000, isTotal: true),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                shadowColor: _primaryColor.withOpacity(0.4),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_checkout, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'ĐẶT HÀNG NGAY',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: _textSecondary.withOpacity(0.2),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? _textPrimary : _textSecondary,
          ),
        ),
        Text(
          '${isDiscount && amount > 0 ? '-' : ''}${_formatCurrency(amount)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal 
                ? _primaryColor 
                : isDiscount 
                  ? Colors.green
                  : _textPrimary,
          ),
        ),
      ],
    );
  }

  void _showVoucherDialog() {
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final savedVouchers = voucherProvider.savedVouchers
        .where((uv) => uv.voucher != null && !uv.isUsed)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chọn mã giảm giá',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingVouchers
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF10B981)),
                      )
                    : savedVouchers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bạn chưa có voucher nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hãy lưu voucher để nhận ưu đãi nhé!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: savedVouchers.length,
                            itemBuilder: (context, index) {
                              final userVoucher = savedVouchers[index];
                              final voucher = userVoucher.voucher!;
                              final isSelected = _selectedUserVoucher?.userVoucherId == userVoucher.userVoucherId;
                              final isValid = _isVoucherValid(voucher);
                              return _buildVoucherCard(
                                voucher: voucher,
                                isSelected: isSelected,
                                isValid: isValid,
                                onSelect: isValid ? () {
                                  setState(() {
                                    _selectedUserVoucher = userVoucher;
                                  });
                                  Navigator.pop(context);
                                  _showSuccessSnackBar('Đã áp dụng mã giảm giá ${voucher.voucherCode}');
                                } : null,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoucherCard({
    required VoucherPublicDto voucher,
    required bool isSelected,
    required bool isValid,
    VoidCallback? onSelect,
  }) {
    String getDiscountText() {
      if (voucher.discountType.toLowerCase() == 'percent' ||
          voucher.discountType.toLowerCase() == 'percentage') {
        return 'Giảm ${voucher.discountValue.toInt()}%';
      } else {
        return 'Giảm ${_formatCurrency(voucher.discountValue)}';
      }
    }

    Color getStatusColor() {
      if (!isValid) return Colors.grey;
      if (voucher.isExpired) return Colors.grey;
      if (voucher.isExpiring) return Colors.orange;
      return _primaryColor;
    }

    String getStatusText() {
      if (!isValid) {
        if (voucher.isExpired) return 'Đã hết hạn';
        if (_totalAmount < voucher.minOrderValue) return 'Chưa đủ điều kiện';
        return 'Không áp dụng';
      }
      if (voucher.isExpiring) return 'Sắp hết hạn';
      return 'Có thể áp dụng';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: _primaryColor, width: 2)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    voucher.discountType.toLowerCase() == 'percent'
                        ? Icons.percent
                        : Icons.local_offer,
                    color: getStatusColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            voucher.voucherCode,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? _primaryColor : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              getStatusText(),
                              style: TextStyle(
                                fontSize: 10,
                                color: getStatusColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getDiscountText(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isValid ? Colors.red : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (voucher.minOrderValue > 0)
                        Text(
                          'Đơn tối thiểu ${_formatCurrency(voucher.minOrderValue)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isValid ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        voucher.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isValid ? Colors.grey[500] : Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (voucher.endDate != null)
                        Text(
                          'HSD: ${voucher.formatDate(voucher.endDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: voucher.isExpiring ? Colors.red : Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 14, color: _primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Đã chọn',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isValid)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Áp dụng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getVoucherDiscountText(VoucherPublicDto? voucher) {
    if (voucher == null) return '';
    if (voucher.discountType.toLowerCase() == 'percent' ||
        voucher.discountType.toLowerCase() == 'percentage') {
      return 'Giảm ${voucher.discountValue.toInt()}%';
    } else {
      return 'Giảm ${_formatCurrency(voucher.discountValue)}';
    }
  }

  void _removeCoupon() {
    setState(() {
      _selectedUserVoucher = null;
    });
    _showSuccessSnackBar('Đã xóa mã giảm giá');
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}