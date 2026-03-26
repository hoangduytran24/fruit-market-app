import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/Order.dart';
import '../models/OrderItem.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final String? initialStatus;

  const OrdersScreen({super.key, this.initialStatus});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Modern color scheme
  static const _primaryColor = Color(0xFF1E3A2F);
  static const _accentColor = Color(0xFF7CB342);
  static const _successColor = Color(0xFF2E7D32);
  static const _warningColor = Color(0xFFFF9800);
  static const _errorColor = Color(0xFFD32F2F);
  static const _backgroundColor = Color(0xFFF5F5F5);
  static const _surfaceColor = Colors.white;
  static const _textPrimary = Color(0xFF212121);
  static const _textSecondary = Color(0xFF757575);
  static const _dividerColor = Color(0xFFEEEEEE);
  static const _shadowColor = Color(0xFF1A1A1A);

  // Gradient cho AppBar
  static const _appBarGradient = LinearGradient(
    colors: [Color(0xFF1E3A2F), Color(0xFF2E5A4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Order status configuration
  static const _statuses = ['pending', 'shipping', 'completed', 'cancelled'];
  
  static const _statusConfig = {
    'pending': {
      'label': 'Chờ xử lý',
      'icon': Icons.schedule_rounded,
      'color': _warningColor,
      'bgColor': Color(0xFFFFF3E0),
    },
    'shipping': {
      'label': 'Đang giao',
      'icon': Icons.local_shipping_rounded,
      'color': _accentColor,
      'bgColor': Color(0xFFE8F5E9),
    },
    'completed': {
      'label': 'Hoàn thành',
      'icon': Icons.check_circle_rounded,
      'color': _successColor,
      'bgColor': Color(0xFFE8F5E9),
    },
    'cancelled': {
      'label': 'Đã hủy',
      'icon': Icons.cancel_rounded,
      'color': _errorColor,
      'bgColor': Color(0xFFFFEBEE),
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    
    if (widget.initialStatus != null && _statuses.contains(widget.initialStatus)) {
      _tabController.animateTo(_statuses.indexOf(widget.initialStatus!));
    }
    
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    await Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Order> _getFilteredOrders(List<Order> orders, String status) =>
      orders.where((o) => o.status == status).toList();

  String _formatCurrency(double amount) {
    final formatted = amount.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted₫';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Chờ xử lý';
      case 'shipping': return 'Đang giao hàng';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return _warningColor;
      case 'shipping': return _accentColor;
      case 'completed': return _successColor;
      case 'cancelled': return _errorColor;
      default: return _textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule_rounded;
      case 'shipping': return Icons.local_shipping_rounded;
      case 'completed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.receipt_rounded;
    }
  }

  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    final baseUrl = 'https://10.0.2.2:7262';
    return imageUrl.startsWith('/') ? '$baseUrl$imageUrl' : '$baseUrl/$imageUrl';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrderProvider>(context).orders;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(orders),
      body: _buildBody(orders),
    );
  }

  PreferredSizeWidget _buildAppBar(List<Order> orders) {
    return AppBar(
      title: const Text(
        'Đơn hàng',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: _appBarGradient,
        ),
      ),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.95),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: _accentColor,
            ),
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tabs: _statuses.map((status) => _buildTab(status, orders)).toList(),
            onTap: (index) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String status, List<Order> orders) {
    final config = _statusConfig[status]!;
    final count = _getFilteredOrders(orders, status).length;
    
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(config['icon'] as IconData, size: 18),
            const SizedBox(width: 8),
            Text(config['label'] as String),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Order> orders) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải đơn hàng...',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }
    
    if (orders.isEmpty) {
      return _buildEmptyState();
    }
    
    return TabBarView(
      controller: _tabController,
      children: _statuses.map((status) {
        final filteredOrders = _getFilteredOrders(orders, status);
        return filteredOrders.isEmpty
            ? _buildEmptyStateForStatus(status)
            : RefreshIndicator(
                onRefresh: _loadOrders,
                color: _accentColor,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredOrders.length,
                  itemBuilder: (_, i) => _OrderCard(
                    order: filteredOrders[i],
                    onCancel: _showCancelConfirmDialog,
                    formatCurrency: _formatCurrency,
                    getStatusText: _getStatusText,
                    getStatusColor: _getStatusColor,
                    getStatusIcon: _getStatusIcon,
                    getFullImageUrl: _getFullImageUrl,
                  ),
                ),
              );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor.withOpacity(0.1), _accentColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: _accentColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy mua sắm để có đơn hàng đầu tiên',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Mua sắm ngay',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateForStatus(String status) {
    final config = _statusConfig[status]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              config['icon'] as IconData,
              size: 40,
              color: config['color'] as Color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có đơn hàng ${(config['label'] as String).toLowerCase()}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelConfirmDialog(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 32,
                  color: _errorColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Xác nhận hủy đơn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn có chắc muốn hủy đơn hàng ${order.orderId}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Quay lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Xác nhận hủy'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (confirmed != true) return;
    
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final success = await provider.cancelOrder(order.orderId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Đã hủy đơn hàng thành công'),
            ],
          ),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      await _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(provider.error ?? 'Không thể hủy đơn hàng'),
              ),
            ],
          ),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

// Modern Order Card Widget
class _OrderCard extends StatelessWidget {
  final Order order;
  final void Function(Order) onCancel;
  final String Function(double) formatCurrency;
  final String Function(String) getStatusText;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;
  final String Function(String) getFullImageUrl;

  static const _accentColor = Color(0xFF7CB342);
  static const _textPrimary = Color(0xFF212121);
  static const _textSecondary = Color(0xFF757575);
  static const _errorColor = Color(0xFFD32F2F);
  static const _dividerColor = Color(0xFFEEEEEE);

  const _OrderCard({
    required this.order,
    required this.onCancel,
    required this.formatCurrency,
    required this.getStatusText,
    required this.getStatusColor,
    required this.getStatusIcon,
    required this.getFullImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _shadowColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProductList(),
                  const Divider(color: _dividerColor, height: 24),
                  _buildTotalRow(),
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final statusColor = getStatusColor(order.status);
    final config = _getStatusConfig(order.status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 14,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                order.orderId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getStatusIcon(order.status),
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  getStatusText(order.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {'bgColor': const Color(0xFFFFF3E0)};
      case 'shipping':
        return {'bgColor': const Color(0xFFE8F5E9)};
      case 'completed':
        return {'bgColor': const Color(0xFFE8F5E9)};
      case 'cancelled':
        return {'bgColor': const Color(0xFFFFEBEE)};
      default:
        return {'bgColor': Colors.grey[50]};
    }
  }

  Widget _buildProductList() {
    if (order.items == null || order.items!.isEmpty) {
      return const SizedBox();
    }
    
    final items = order.items!.take(2).toList();
    
    return Column(
      children: [
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _buildProductImage(item),
              const SizedBox(width: 12),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatCurrency(item.priceAtTime)} x ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatCurrency(item.subtotal),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
                  ),
                ),
              ),
            ],
          ),
        )),
        if (order.items!.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 14, color: _textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${order.items!.length - 2} sản phẩm khác',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductImage(OrderItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? Image.network(
                getFullImageUrl(item.imageUrl!),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_outlined,
                  size: 28,
                  color: _textSecondary.withOpacity(0.4),
                ),
              )
            : Icon(
                Icons.image_outlined,
                size: 28,
                color: _textSecondary.withOpacity(0.4),
              ),
      ),
    );
  }

  Widget _buildTotalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Tổng cộng',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textSecondary,
          ),
        ),
        Text(
          formatCurrency(order.finalAmount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _accentColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (order.status == 'pending')
          Expanded(
            child: OutlinedButton(
              onPressed: () => onCancel(order),
              style: OutlinedButton.styleFrom(
                foregroundColor: _errorColor,
                side: BorderSide(color: _errorColor.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hủy đơn',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        if (order.status == 'pending') const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Xem chi tiết',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  static const _shadowColor = Color(0xFF1A1A1A);
}