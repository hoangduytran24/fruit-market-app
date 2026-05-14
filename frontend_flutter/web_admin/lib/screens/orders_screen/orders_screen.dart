import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../utils/responsive.dart';
import 'order_detail_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Tất cả';
  final Color primaryGreen = const Color(0xFF1A5F3A);
  final double shippingFee = 25000;

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
    final isMobile = Responsive.isMobile(context);

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
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
      builder: (context) => OrderDetailDialog(
        order: order,
        formatCurrency: _formatCurrency,
        statusMap: _statusDisplay,
        primaryGreen: primaryGreen,
        getPaymentText: _getPaymentText,
        getPaymentColor: _getPaymentColor,
        formatDate: _formatDate,
        shippingFee: shippingFee,
      ),
    );
  }
}