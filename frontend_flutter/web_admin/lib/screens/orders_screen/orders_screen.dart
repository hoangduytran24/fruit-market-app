import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/return_provider.dart';
import '../../models/order.dart';
import '../../models/ReturnRequest.dart';
import '../../utils/responsive.dart';
import 'order_detail_dialog.dart';
import 'admin_return_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedTabIndex = 0; // 0: Đơn hàng, 1: Trả hàng
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _returnSearchController = TextEditingController();
  String _selectedStatus = 'Tất cả';
  String _selectedReturnStatus = 'Tất cả';
  final Color primaryGreen = const Color(0xFF1A5F3A);
  final double shippingFee = 25000;

  final Map<String, String> _statusDisplay = {
    'Tất cả': 'Tất cả',
    'pending': 'Chờ duyệt',
    'processing': 'Đang gói',
    'shipping': 'Đang giao',
    'completed': 'Thành công',
    'cancelled': 'Đã hủy',
    'returned':'Đã trả hàng',
    'return_approved': 'Đã duyệt trả hàng',
    'return_requested': 'xác nhận trả hàng',
  };

  final Map<String, String> _returnStatusDisplay = {
    'Tất cả': 'Tất cả',
    'pending': 'Chờ xử lý',
    'approved': 'Đã duyệt',
    'rejected': 'Từ chối',
    'completed': 'Hoàn tất',
  };
//  bổ sung
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _returnSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<OrderProvider>().refreshOrders();
    await context.read<ReturnProvider>().fetchAllReturnRequests();
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
      case 'returned': return const Color.fromARGB(255, 62, 39, 176);
      case 'return_approved': return Colors.teal;
      case 'return_requested': return Colors.cyan; 
      default: return Colors.grey;
    }
  }

  Color _getReturnStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getReturnStatusText(String status) {
    switch (status) {
      case 'pending': return 'Chờ xử lý';
      case 'approved': return 'Đã duyệt';
      case 'rejected': return 'Từ chối';
      case 'completed': return 'Hoàn tất';
      default: return status;
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
    final returnProvider = context.watch<ReturnProvider>();
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Segment Button - 2 nút vuông
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                        _animationController.forward(from: 0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_selectedTabIndex == 0)
                                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              if (_selectedTabIndex == 0) const SizedBox(width: 8),
                              Text(
                                'Xử lý đơn hàng',
                                style: TextStyle(
                                  color: _selectedTabIndex == 0 ? Colors.white : primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                        _animationController.forward(from: 0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_selectedTabIndex == 1)
                                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              if (_selectedTabIndex == 1) const SizedBox(width: 8),
                              Text(
                                'Xử Lý Trả Hàng',
                                style: TextStyle(
                                  color: _selectedTabIndex == 1 ? Colors.white : primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Nội dung theo tab được chọn
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _selectedTabIndex == 0
                  ? _buildOrderTab(provider, isMobile)
                  : _buildReturnTab(returnProvider, isMobile),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB ĐƠN HÀNG ====================
  Widget _buildOrderTab(OrderProvider provider, bool isMobile) {
    return Column(
      children: [
        _buildOrderToolBar(provider, isMobile),
        _buildOrderStatusFilter(provider),
        Expanded(
          child: provider.isLoading && provider.orders.isEmpty
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : provider.orders.isEmpty
                  ? _buildEmptyState('đơn hàng')
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
    );
  }

  Widget _buildOrderToolBar(OrderProvider provider, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onSubmitted: (val) => provider.searchOrders(val),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đơn hàng...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            provider.searchOrders('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusFilter(OrderProvider provider) {
    return Container(
      height: 45,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _statusDisplay.entries.map((e) {
          bool isSelected = _selectedStatus == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(e.value, style: TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedStatus = e.key);
                provider.filterByStatus(e.key == 'Tất cả' ? null : e.key);
              },
              selectedColor: primaryGreen,
              backgroundColor: Colors.grey.shade100,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
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
                  _buildOrderTableHeader(),
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

  Widget _buildOrderTableHeader() {
    const headerStyle = TextStyle(
        fontWeight: FontWeight.bold, color: Color(0xFF1A5F3A), fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
      decoration: const BoxDecoration(
          color: Color(0xFFF1F8E9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Mã Đơn', style: headerStyle)),
          Expanded(flex: 2, child: Text('Ngày đặt', style: headerStyle)),
          Expanded(flex: 3, child: Text('Khách hàng', style: headerStyle)),
          Expanded(flex: 2, child: Center(child: Text('Thanh toán', style: headerStyle))),
          Expanded(flex: 2, child: Text('Tổng cộng', style: headerStyle, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Center(child: Text('Trạng thái', style: headerStyle))),
          Expanded(flex: 1, child: Center(child: Text('Xem', style: headerStyle))),
        ],
      ),
    );
  }

  Widget _buildOrderRow(OrderListDto order) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text("#${order.orderId}",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text(_formatDate(order.createdAt),
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 3,
              child: Text(order.customerName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                    fontSize: 11,
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
                      fontSize: 13))),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(_statusDisplay[order.status] ?? order.status,
                    style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
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

  // ==================== TAB TRẢ HÀNG ====================
  Widget _buildReturnTab(ReturnProvider provider, bool isMobile) {
    final returns = _getFilteredReturns(provider.returns);
    
    return Column(
      children: [
        _buildReturnToolBar(provider, isMobile),
        _buildReturnStatusFilter(provider),
        Expanded(
          child: provider.isLoading && provider.returns.isEmpty
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : returns.isEmpty
                  ? _buildEmptyState('yêu cầu trả hàng')
                  : LayoutBuilder(builder: (context, constraints) {
                      return RefreshIndicator(
                        onRefresh: () => provider.fetchAllReturnRequests(),
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: isMobile ? 900 : 1100,
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
                                  _buildReturnTableHeader(),
                                  ...returns.map((returnReq) => _buildReturnRow(returnReq)).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
        ),
      ],
    );
  }

  List<ReturnRequest> _getFilteredReturns(List<ReturnRequest> returns) {
    if (_selectedReturnStatus == 'Tất cả') return returns;
    return returns.where((r) => r.status == _selectedReturnStatus).toList();
  }

  Widget _buildReturnToolBar(ReturnProvider provider, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _returnSearchController,
                onChanged: (value) {
                  // TODO: Implement search
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo mã đơn hàng...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _returnSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _returnSearchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchAllReturnRequests(),
            tooltip: 'Làm mới',
          ),
        ],
      ),
    );
  }

  Widget _buildReturnStatusFilter(ReturnProvider provider) {
    return Container(
      height: 45,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _returnStatusDisplay.entries.map((e) {
          bool isSelected = _selectedReturnStatus == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(e.value, style: TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedReturnStatus = e.key);
                if (e.key == 'Tất cả') {
                  provider.fetchAllReturnRequests();
                } else {
                  provider.filterReturnsByStatus(e.key);
                }
              },
              selectedColor: primaryGreen,
              backgroundColor: Colors.grey.shade100,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReturnTableHeader() {
    const headerStyle = TextStyle(
        fontWeight: FontWeight.bold, color: Color(0xFF1A5F3A), fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
      decoration: const BoxDecoration(
          color: Color(0xFFF1F8E9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Mã yêu cầu', style: headerStyle)),
          Expanded(flex: 2, child: Text('Mã đơn hàng', style: headerStyle)),
          Expanded(flex: 2, child: Text('Ngày tạo', style: headerStyle)),
          Expanded(flex: 3, child: Text('Lý do', style: headerStyle)),
          Expanded(flex: 2, child: Center(child: Text('Số tiền', style: headerStyle))),
          Expanded(flex: 2, child: Center(child: Text('Trạng thái', style: headerStyle))),
          Expanded(flex: 1, child: Center(child: Text('Xem', style: headerStyle))),
        ],
      ),
    );
  }

  Widget _buildReturnRow(ReturnRequest returnReq) {
    final statusColor = _getReturnStatusColor(returnReq.status);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(returnReq.returnId,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text(returnReq.orderId,
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text(_formatDate(returnReq.createdAt),
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 3,
              child: Text(returnReq.reason,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  _formatCurrency(returnReq.refundAmount),
                  style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              )),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _getReturnStatusText(returnReq.status),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          Expanded(
              flex: 1,
              child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blue),
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) => AdminReturnDetailScreen(returnId: returnReq.returnId),
                      );
                      if (result == true) {
                        context.read<ReturnProvider>().fetchAllReturnRequests();
                      }
                    },
                    tooltip: 'Xem chi tiết',
                  ))),
        ],
      ),
    );
  }

  // ==================== COMMON ====================
  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text('Không có $type nào',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
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