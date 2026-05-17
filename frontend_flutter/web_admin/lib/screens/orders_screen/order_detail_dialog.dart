import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/image_utils.dart';
import '../../utils/pdf_helper.dart';
import '../../utils/responsive.dart';

class OrderDetailDialog extends StatelessWidget {
  final Order order;
  final String Function(double) formatCurrency;
  final Map<String, String> statusMap;
  final Color primaryGreen;
  final Function getPaymentText;
  final Function getPaymentColor;
  final String Function(DateTime) formatDate;
  final double shippingFee;

  const OrderDetailDialog({
    super.key,
    required this.order,
    required this.formatCurrency,
    required this.statusMap,
    required this.primaryGreen,
    required this.getPaymentText,
    required this.getPaymentColor,
    required this.formatDate,
    required this.shippingFee,
  });

  int _getTotalQuantity() {
    return order.items.fold(0, (sum, item) => sum + item.quantity);
  }

  double _getProductTotal() {
    return order.totalAmount - shippingFee;
  }

  double _getFinalTotalWithShipping() {
    return order.finalAmount;
  }

  String _safeFormatCurrency(double amount) {
    if (amount == 0) return '0₫';
    try {
      final result = formatCurrency(amount);
      if (result.isEmpty || result == '0.00' || result == '0') {
        final formatter = NumberFormat('#,###', 'vi_VN');
        return '${formatter.format(amount.round())}₫';
      }
      return result;
    } catch (e) {
      final formatter = NumberFormat('#,###', 'vi_VN');
      return '${formatter.format(amount.round())}₫';
    }
  }

  Future<void> _handleMarkDeliveryFailed(BuildContext context) async {
  final TextEditingController reasonController = TextEditingController();
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping, color: Colors.deepOrange, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Giao thất bại',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Vui lòng nhập lý do:'),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'VD: Khách không nghe máy, sai địa chỉ...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );
  
  if (confirmed == true && context.mounted) {
    final success = await context.read<OrderProvider>()
        .markDeliveryFailed(order.orderId, reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim());
    
    if (context.mounted) {
      // ✅ KHÔNG gọi Navigator.pop(context) ở đây nữa
      // Vì dialog đã tự đóng khi chọn Xác nhận
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Đã cập nhật: Giao thất bại" : "Cập nhật thất bại"),
          backgroundColor: success ? Colors.deepOrange : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

  Future<void> _handleCancelDeliveryFailed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text(
          'Đơn hàng này đã giao thất bại. Hủy đơn sẽ hoàn lại số lượng sản phẩm vào kho. Bạn có chắc chắn muốn hủy?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      final success = await context.read<OrderProvider>()
          .cancelDeliveryFailedOrder(order.orderId);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Đã hủy đơn hàng và hoàn lại kho" : "Hủy đơn thất bại"),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = order.status == 'completed';
    final isShipping = order.status == 'shipping';
    final isDeliveryFailed = order.status == 'delivery_failed';
    final isCancellable = order.status == 'pending' || order.status == 'processing';
    final int totalQuantity = _getTotalQuantity();
    final double productTotal = _getProductTotal();
    final double finalTotal = _getFinalTotalWithShipping();
    
    // Responsive
    final bool isMobile = context.isMobile;
    final double dialogWidth = isMobile ? context.screenWidth * 0.92 : 550;
    final double innerPadding = isMobile ? 16.0 : 20.0;
    final double fontSizeTitle = isMobile ? 16.0 : 18.0;
    final double fontSizeLabel = isMobile ? 12.0 : 13.0;
    final double fontSizeValue = isMobile ? 13.0 : 15.0;
    final double fontSizeTotal = isMobile ? 18.0 : 22.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: context.screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(innerPadding),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CHI TIẾT ĐƠN HÀNG",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSizeTitle,
                          ),
                        ),
                        Text(
                          "Mã đơn: #${order.orderId.toUpperCase()}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: fontSizeLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(innerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReceiptRow(
                      "Ngày đặt:", 
                      formatDate(order.createdAt),
                      fontSizeLabel: fontSizeLabel,
                      fontSizeValue: fontSizeValue,
                    ),
                    _buildReceiptRow(
                      "Khách hàng:", 
                      order.customerName,
                      fontSizeLabel: fontSizeLabel,
                      fontSizeValue: fontSizeValue,
                    ),
                    _buildReceiptRow(
                      "Số ĐT:", 
                      order.customerPhone ?? 'Không có',
                      fontSizeLabel: fontSizeLabel,
                      fontSizeValue: fontSizeValue,
                    ),
                    _buildReceiptRow(
                      "Địa chỉ:", 
                      order.deliveryAddress,
                      fontSizeLabel: fontSizeLabel,
                      fontSizeValue: fontSizeValue,
                    ),
                    const Divider(height: 24),
                    
                    // Thông tin số lượng
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildReceiptRow(
                            "Số lượng sản phẩm:", 
                            "${order.items.length} sản phẩm",
                            isBold: true,
                            fontSizeLabel: fontSizeLabel,
                            fontSizeValue: fontSizeValue,
                          ),
                          const SizedBox(height: 4),
                          _buildReceiptRow(
                            "Tổng số lượng:", 
                            "$totalQuantity",
                            isBold: true,
                            fontSizeLabel: fontSizeLabel,
                            fontSizeValue: fontSizeValue,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tiêu đề sản phẩm
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Sản phẩm",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeLabel,
                            ),
                          ),
                          Text(
                            "Thành tiền",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Danh sách sản phẩm
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ImageUtils.networkImage(
                                item.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: fontSizeLabel,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${item.quantity} x ${_safeFormatCurrency(item.price)}",
                                  style: TextStyle(
                                    fontSize: fontSizeLabel - 1,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _safeFormatCurrency(item.subtotal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeLabel,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    
                    const Divider(height: 24, thickness: 1, color: Colors.black12),
                    
                    // Tổng tiền hàng
                    _buildReceiptRow(
                      "Tổng tiền hàng:",
                      _safeFormatCurrency(productTotal),
                      fontSizeLabel: fontSizeLabel,
                      fontSizeValue: fontSizeValue,
                    ),
                    
                    if (order.discountAmount > 0)
                      _buildReceiptRow(
                        "Giảm giá:",
                        "-${_safeFormatCurrency(order.discountAmount)}",
                        color: Colors.red,
                        fontSizeLabel: fontSizeLabel,
                        fontSizeValue: fontSizeValue,
                      ),
                    
                    _buildReceiptRow(
                      "Tạm tính (sau giảm giá):",
                      _safeFormatCurrency(productTotal - order.discountAmount),
                      isBold: true,
                      fontSizeLabel: fontSizeLabel,
                      fontSizeValue: fontSizeValue,
                    ),
                    
                    _buildReceiptRow(
                      "Phí vận chuyển:",
                      _safeFormatCurrency(shippingFee),
                      color: Colors.orange,
                      isBold: true,
                      fontSizeLabel: fontSizeLabel,
                      fontSizeValue: fontSizeValue,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Tổng thanh toán
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "TỔNG THANH TOÁN:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeLabel + 2,
                            ),
                          ),
                          Text(
                            _safeFormatCurrency(finalTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeTotal,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Thông tin thanh toán
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: getPaymentColor(order.paymentStatus).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: getPaymentColor(order.paymentStatus).withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            getPaymentText(order.paymentStatus).toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeLabel,
                              color: getPaymentColor(order.paymentStatus),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Phương thức: ${order.paymentMethod.toUpperCase()}",
                            style: TextStyle(
                              fontSize: fontSizeLabel - 1,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Actions
            Padding(
              padding: EdgeInsets.all(innerPadding),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  // Nút đóng
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Đóng"),
                  ),
                  
                  // Nút xuất hóa đơn (chỉ khi completed)
                  if (isCompleted)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await PdfHelper.generateInvoice(
                          order: order,
                          formatCurrency: _safeFormatCurrency,
                          formatDate: formatDate,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text("Xuất hóa đơn"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  
                  // Nút cho trạng thái đang giao (shipping)
                  if (isShipping) ...[
                    // Nút hoàn thành
                    ElevatedButton(
                      onPressed: () async {
                        final success = await context.read<OrderProvider>()
                            .updateOrderStatus(order.orderId, 'completed');
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? "Đã cập nhật: Thành công" : "Cập nhật thất bại"),
                              backgroundColor: success ? Colors.green : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Hoàn thành"),
                    ),
                    // Nút giao thất bại
                    ElevatedButton(
                      onPressed: () => _handleMarkDeliveryFailed(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Giao thất bại"),
                    ),
                  ],
                  
                  // Nút hủy đơn cho trạng thái delivery_failed
                  if (isDeliveryFailed)
                    ElevatedButton(
                      onPressed: () => _handleCancelDeliveryFailed(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Hủy đơn + Hoàn kho"),
                    ),
                  
                  // Nút duyệt đơn (pending/processing)
                  if (isCancellable)
                    ElevatedButton(
                      onPressed: () async {
                        String nextStatus = order.status == 'pending' ? 'processing' : 'shipping';
                        String buttonLabel = order.status == 'pending' ? 'Duyệt đơn' : 'Giao hàng';
                        
                        final success = await context.read<OrderProvider>()
                            .updateOrderStatus(order.orderId, nextStatus);
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? "Đã cập nhật: $buttonLabel" : "Cập nhật thất bại"),
                              backgroundColor: success ? Colors.green : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(order.status == 'pending' ? "Duyệt đơn" : "Giao hàng"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    required double fontSizeLabel,
    required double fontSizeValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: fontSizeLabel == 12 ? 100 : 120,
            child: Text(
              label,
              style: TextStyle(
                color: isBold ? Colors.black : Colors.grey[600],
                fontSize: fontSizeLabel,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: fontSizeValue,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}