import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../utils/image_utils.dart';
import '../utils/responsive.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Tất cả';
  final Color primaryGreen = const Color(0xFF1A5F3A);

  final Map<String, String> _statusDisplay = {
    'Tất cả': 'Tất cả',
    'pending': 'Chờ duyệt',
    'processing': 'Đang gói',
    'shipping': 'Đang giao',
    'completed': 'Thành công',
    'cancelled': 'Đã hủy',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<OrderProvider>().refreshOrders();
  }

  String _formatCurrency(double amount) {
    return amount.round().toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.') +
        " ₫";
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'shipping': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getPaymentText(String? status) {
    if (status?.toLowerCase() == 'paid') return 'Đã thanh toán';
    return 'Chưa thanh toán';
  }

  Color _getPaymentColor(String? status) {
    return status?.toLowerCase() == 'paid' ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildToolBar(provider, isMobile),
          _buildStatusFilter(provider),
          Expanded(
            child: provider.isLoading && provider.orders.isEmpty
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : provider.orders.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(builder: (context, constraints) {
                        return Column(
                          children: [
                            Expanded(
                              child: _buildOrderTable(
                                  provider.orders, isMobile, constraints),
                            ),
                            if (provider.totalPages > 1)
                              _buildPagination(provider),
                          ],
                        );
                      }),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBar(OrderProvider provider, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? 200 : 350,
            height: 42,
            child: TextField(
              controller: _searchController,
              onSubmitted: (val) => provider.searchOrders(val),
              decoration: InputDecoration(
                hintText: 'Tìm mã đơn hàng...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      provider.searchOrders('');
                    }),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: provider.refreshOrders,
          )
        ],
      ),
    );
  }

  Widget _buildStatusFilter(OrderProvider provider) {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _statusDisplay.entries.map((e) {
          bool isSelected = _selectedStatus == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedStatus = e.key);
                provider.filterByStatus(e.key == 'Tất cả' ? null : e.key);
              },
              selectedColor: primaryGreen,
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderTable(
      List<OrderListDto> orders, bool isMobile, BoxConstraints constraints) {
    double minTableWidth = isMobile ? 850 : 1100;

    return RefreshIndicator(
      onRefresh: () => context.read<OrderProvider>().refreshOrders(),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Container(
              width: minTableWidth,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  ...orders.map((order) => _buildOrderRow(order)).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    const headerStyle = TextStyle(
        fontWeight: FontWeight.bold, color: Color(0xFF1A5F3A), fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: const BoxDecoration(
          color: Color(0xFFF1F8E9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Mã Đơn', style: headerStyle)),
          Expanded(flex: 2, child: Text('Ngày đặt', style: headerStyle)),
          Expanded(flex: 3, child: Text('Khách hàng', style: headerStyle)),
          Expanded(flex: 2, child: Center(child: Text('Thanh toán', style: headerStyle))),
          Expanded(
              flex: 2,
              child: Text('Tổng cộng',
                  style: headerStyle, textAlign: TextAlign.right)),
          Expanded(
              flex: 2, child: Center(child: Text('Trạng thái', style: headerStyle))),
          Expanded(
              flex: 1, child: Center(child: Text('Xem', style: headerStyle))),
        ],
      ),
    );
  }

  Widget _buildOrderRow(OrderListDto order) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade50))),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text("#${order.orderId.toUpperCase()}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 2,
              child: Text(_formatDate(order.createdAt),
                  style: const TextStyle(fontSize: 11))),
          Expanded(
              flex: 3,
              child: Text(order.customerName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPaymentColor(order.paymentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                  _getPaymentText(order.paymentStatus),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getPaymentColor(order.paymentStatus),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(_formatCurrency(order.finalAmount),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(_statusDisplay[order.status] ?? order.status,
                    style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
              flex: 1,
              child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blue),
                    onPressed: () => _showDetailDialog(order.orderId),
                    tooltip: 'Xem chi tiết',
                  ))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text('Không tìm thấy đơn hàng nào',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPagination(OrderProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: provider.currentPage > 1
                  ? () => provider.goToPage(provider.currentPage - 1)
                  : null),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: primaryGreen, borderRadius: BorderRadius.circular(15)),
            child: Text('${provider.currentPage} / ${provider.totalPages}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: provider.currentPage < provider.totalPages
                  ? () => provider.goToPage(provider.currentPage + 1)
                  : null),
        ],
      ),
    );
  }

  void _showDetailDialog(String id) async {
    final order = await context.read<OrderProvider>().getOrderById(id);
    if (order == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => _OrderDetailDialog(
        order: order,
        formatCurrency: _formatCurrency,
        statusMap: _statusDisplay,
        primaryGreen: primaryGreen,
        getPaymentText: _getPaymentText,
        getPaymentColor: _getPaymentColor,
        formatDate: _formatDate,
      ),
    );
  }
}

class _OrderDetailDialog extends StatelessWidget {
  final Order order;
  final Function formatCurrency;
  final Map<String, String> statusMap;
  final Color primaryGreen;
  final Function getPaymentText;
  final Function getPaymentColor;
  final Function formatDate;

  const _OrderDetailDialog({
    required this.order,
    required this.formatCurrency,
    required this.statusMap,
    required this.primaryGreen,
    required this.getPaymentText,
    required this.getPaymentColor,
    required this.formatDate,
  });

  Map<String, String>? _getNextStatusInfo(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return {'label': 'Duyệt đơn', 'next': 'processing'};
      case 'processing':
        return {'label': 'Giao hàng', 'next': 'shipping'};
      case 'shipping':
        return {'label': 'Hoàn tất', 'next': 'completed'};
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextInfo = _getNextStatusInfo(order.status);
    final bool isCompleted = order.status == 'completed';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 550,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CHI TIẾT ĐƠN HÀNG",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("Mã đơn: #${order.orderId.toUpperCase()}",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  )
                ],
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildReceiptRow("Ngày đặt:", formatDate(order.createdAt)),
                    _buildReceiptRow("Khách hàng:", order.customerName),
                    _buildReceiptRow("Số ĐT:", order.customerPhone ?? 'Không có'),
                    _buildReceiptRow("Địa chỉ:", order.deliveryAddress),
                    const Divider(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Sản phẩm", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Thành tiền", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ImageUtils.networkImage(
                            item.imageUrl,
                            width: 50,
                            height: 50,
                            borderRadius: 8,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, 
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text("${item.quantity} x ${formatCurrency(item.price)}", 
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Text(formatCurrency(item.subtotal), 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )).toList(),
                    
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    
                    _buildReceiptRow("Tổng tiền hàng:", formatCurrency(order.totalAmount)),
                    if(order.discountAmount > 0)
                      _buildReceiptRow("Giảm giá:", "-${formatCurrency(order.discountAmount)}", color: Colors.red),
                    
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TỔNG THANH TOÁN:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(formatCurrency(order.finalAmount), 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryGreen)),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: getPaymentColor(order.paymentStatus).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: getPaymentColor(order.paymentStatus).withOpacity(0.2))
                      ),
                      child: Column(
                        children: [
                          Text(getPaymentText(order.paymentStatus).toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, color: getPaymentColor(order.paymentStatus))),
                          Text("Phương thức: ${order.paymentMethod.toUpperCase()}", 
                            style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Nút Đóng luôn hiện
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text("Đóng"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Nếu trạng thái là THÀNH CÔNG -> Hiện nút Xuất Hóa Đơn
                  if (isCompleted) 
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Logic xuất PDF ở đây
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Xuất hóa đơn", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    )
                  // Nếu chưa thành công và có bước tiếp theo -> Hiện nút Cập nhật trạng thái
                  else if (nextInfo != null)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await context.read<OrderProvider>()
                              .updateOrderStatus(order.orderId, nextInfo['next']!);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(success 
                                  ? "Đã cập nhật: ${statusMap[nextInfo['next']]}" 
                                  : "Cập nhật thất bại"),
                              backgroundColor: success ? Colors.green : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(nextInfo['label']!, 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, 
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}