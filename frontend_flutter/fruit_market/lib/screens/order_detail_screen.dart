import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/Order.dart';
import '../models/OrderItem.dart';
import '../providers/order_provider.dart';
import '../providers/return_provider.dart';
import '../utils/image_utils.dart';
import 'vietqr_payment_screen.dart';
import 'return_request_screen.dart';
import 'return_detail_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;
  bool _isLoadingDetails = true;
  bool _isProcessingPayment = false;
  Order? _orderDetails;
  String? _returnId;
  
  static const double _shippingFee = 25000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails();
    });
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoadingDetails = true);
    
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final orderDetail = await orderProvider.fetchOrderDetail(widget.order.orderId);
      
      final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
      final returnId = await returnProvider.getReturnIdByOrderId(widget.order.orderId);
      
      print('ReturnId from API: $returnId');
      
      if (mounted) {
        setState(() {
          _orderDetails = orderDetail;
          _returnId = returnId;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      print('Lỗi tải chi tiết đơn hàng: $e');
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  Future<void> _requestReturn() async {
    final order = _orderDetails ?? widget.order;
    
    final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
    final canReturn = await returnProvider.canReturnOrder(order.orderId);
    
    if (!canReturn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn hàng không đủ điều kiện trả hàng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnRequestScreen(order: order),
      ),
    );
    
    if (result == true) {
      await _loadOrderDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yêu cầu trả hàng đã được gửi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _viewReturnDetail() async {
    if (_returnId == null || _returnId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin yêu cầu trả hàng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnDetailScreen(returnId: _returnId!),
      ),
    );
  }

  String _getReturnStatusText(String status) {
    switch (status) {
      case 'return_requested':
        return 'Yêu cầu trả hàng đã được gửi, đang chờ xử lý';
      case 'return_approved':
        return 'Yêu cầu trả hàng đã được chấp nhận, vui lòng gửi hàng về shop';
      case 'returned':
        return 'Đơn hàng đã được trả và hoàn tiền thành công';
      default:
        return '';
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentMethodText(String? method) {
    switch (method) {
      case 'cod':
        return 'Thanh toán khi nhận hàng (COD)';
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      case 'momo':
        return 'Ví MoMo';
      case 'zalopay':
        return 'ZaloPay';
      default:
        return method ?? 'Chưa xác định';
    }
  }

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      default:
        return status ?? 'Chưa thanh toán';
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String? status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'unpaid':
        return Icons.pending_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getOrderStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipping':
        return 'Đang giao hàng';
      case 'completed':
        return 'Đã giao hàng';
      case 'return_requested':
        return 'Yêu cầu trả hàng';
      case 'return_approved':
        return 'Chấp nhận trả hàng';
      case 'returned':
        return 'Đã trả hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipping':
        return Colors.purple;
      case 'completed':
        return const Color(0xFF1B5E20);
      case 'return_requested':
        return Colors.purple;
      case 'return_approved':
        return Colors.teal;
      case 'returned':
        return Colors.brown;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.check_circle_outline;
      case 'shipping':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'return_requested':
        return Icons.request_page;
      case 'return_approved':
        return Icons.check_circle_outline;
      case 'returned':
        return Icons.assignment_returned;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> _cancelOrder() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              final success = await orderProvider.cancelOrder(widget.order.orderId);
              
              if (mounted) {
                setState(() => _isLoading = false);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã hủy đơn hàng thành công'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(orderProvider.error ?? 'Không thể hủy đơn hàng'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _continuePayment() async {
    final order = _orderDetails ?? widget.order;

    if (order.paymentMethod != 'bank_transfer' || order.paymentStatus != 'unpaid') {
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SePayPaymentScreen(
            orderId: order.orderId,
            amount: order.totalAmount,
            existingPaymentId: order.paymentId,
          ),
        ),
      );

      if (mounted && result == true) {
        await _loadOrderDetails();
        
        if (_orderDetails?.paymentStatus == 'paid') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thanh toán thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Lỗi khi tiếp tục thanh toán: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chuyển đến trang thanh toán'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _orderDetails ?? widget.order;
    
    final subtotal = order.totalAmount - _shippingFee;
    final hasDiscount = order.discountAmount > 0;
    final finalTotal = order.totalAmount;

    final isReturning = order.status == 'return_requested' || 
                        order.status == 'return_approved' || 
                        order.status == 'returned';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: const Color(0xFF0B2A1F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (order.status == 'pending')
            TextButton(
              onPressed: _cancelOrder,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Hủy đơn'),
            ),
          if (!_isLoadingDetails && order.status == 'completed')
            TextButton(
              onPressed: _requestReturn,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Trả hàng', style: TextStyle(color: Colors.orange)),
            ),
        ],
      ),
      body: _isLoading || _isLoadingDetails
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getOrderStatusColor(order.status).withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getOrderStatusIcon(order.status),
                                color: _getOrderStatusColor(order.status),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getOrderStatusText(order.status),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getOrderStatusColor(order.status),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mã đơn hàng: ${order.orderId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (order.paymentStatus != null && order.paymentStatus!.isNotEmpty)
                                    Text(
                                      'Ngày đặt: ${_formatDate(order.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const Divider(height: 24),
                        
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getPaymentStatusColor(order.paymentStatus).withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getPaymentStatusIcon(order.paymentStatus),
                                color: _getPaymentStatusColor(order.paymentStatus),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getPaymentStatusText(order.paymentStatus),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getPaymentStatusColor(order.paymentStatus),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getPaymentMethodText(order.paymentMethod),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20).withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF1B5E20),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Thông tin người nhận',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          label: 'Họ tên',
                          value: order.receiverName.isNotEmpty ? order.receiverName : 'Chưa cập nhật',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          label: 'Số điện thoại',
                          value: order.receiverPhone.isNotEmpty ? order.receiverPhone : 'Chưa cập nhật',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          label: 'Địa chỉ',
                          value: order.deliveryAddress.isNotEmpty ? order.deliveryAddress : 'Chưa cập nhật',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20).withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payment_outlined,
                                color: Color(0xFF1B5E20),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Thông tin thanh toán',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          label: 'Phương thức',
                          value: _getPaymentMethodText(order.paymentMethod),
                        ),
                        if (order.paymentStatus != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            label: 'Trạng thái',
                            value: _getPaymentStatusText(order.paymentStatus),
                            valueColor: _getPaymentStatusColor(order.paymentStatus),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          label: 'Tạm tính',
                          value: _formatCurrency(subtotal),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            label: 'Giảm giá',
                            value: '-${_formatCurrency(order.discountAmount)}',
                            valueColor: Colors.red,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          label: 'Phí vận chuyển',
                          value: _formatCurrency(_shippingFee),
                          valueColor: Colors.grey[700],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatCurrency(finalTotal),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        if (order.voucherCode != null && order.voucherCode!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_offer,
                                  size: 14,
                                  color: Color(0xFFFF6B6B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Mã: ${order.voucherCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF6B6B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20).withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Color(0xFF1B5E20),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sản phẩm đã mua',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${order.items?.length ?? 0} sản phẩm',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (order.items == null || order.items!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Không có sản phẩm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...order.items!.map((item) => _buildProductItem(item)).toList(),
                      ],
                    ),
                  ),

                  // Phần hiển thị trạng thái trả hàng - Thiết kế lại đẹp hơn
                  if (isReturning) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header gradient
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.orange.shade600,
                                  Colors.orange.shade400,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.request_page, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'TRẠNG THÁI TRẢ HÀNG',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Body
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _getOrderStatusColor(order.status).withAlpha(26),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getOrderStatusIcon(order.status),
                                    color: _getOrderStatusColor(order.status),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getOrderStatusText(order.status),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: _getOrderStatusColor(order.status),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getReturnStatusText(order.status),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _viewReturnDetail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size(70, 38),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Chi tiết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios, size: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (order.paymentMethod == 'bank_transfer' && order.paymentStatus == 'unpaid') ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessingPayment ? null : _continuePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isProcessingPayment
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    'THANH TOÁN NGAY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(OrderItem item) {
    final imageUrl = ImageUtils.getOriginalImage(item.imageUrl);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatCurrency(item.priceAtTime),
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
}