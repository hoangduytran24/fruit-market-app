import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/real_time_provider.dart'; // Đã thêm
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

  // Fresh fruit color palette - Giữ nguyên từ file mẫu của bạn
  static const _primaryGreen = Color(0xFF2E7D32);
  static const _orange = Color(0xFFFF9800);
  static const _blue = Color(0xFF2196F3);
  static const _teal = Colors.teal; // Màu cho Processing
  static const _red = Color(0xFFEF5350);
  static const _background = Color(0xFFF9F9F9);
  static const _cardWhite = Colors.white;
  static const _textDark = Color(0xFF2C3E2F);
  static const _textLight = Color(0xFF7C9A7E);

  // Đã thêm 'processing' vào danh sách
  static const _statuses = ['pending', 'processing', 'shipping', 'completed', 'cancelled'];
  
  // Cấu hình trạng thái - Đã cập nhật thêm 'processing'
  static const _statusConfig = {
    'pending': {
      'label': 'Chờ xử lý',
      'icon': Icons.access_time_filled,
      'color': _orange,
      'bg': Color(0xFFFFF3E0),
      'border': Color(0xFFFFE0B2),
    },
    'processing': {
      'label': 'Đóng gói',
      'icon': Icons.inventory_2,
      'color': _teal,
      'bg': Color(0xFFE0F2F1),
      'border': Color(0xFFB2DFDB),
    },
    'shipping': {
      'label': 'Đang giao',
      'icon': Icons.local_shipping,
      'color': _blue,
      'bg': Color(0xFFE3F2FD),
      'border': Color(0xFFBBDEFB),
    },
    'completed': {
      'label': 'Đã giao',
      'icon': Icons.check_circle,
      'color': _primaryGreen,
      'bg': Color(0xFFE8F5E9),
      'border': Color(0xFFC8E6C9),
    },
    'cancelled': {
      'label': 'Đã hủy',
      'icon': Icons.cancel,
      'color': _red,
      'bg': Color(0xFFFFEBEE),
      'border': Color(0xFFFFCDD2),
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    if (widget.initialStatus != null && _statuses.contains(widget.initialStatus)) {
      _tabController.animateTo(_statuses.indexOf(widget.initialStatus!));
    }

    // Tích hợp RealTimeProvider và Load dữ liệu ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realTimeProvider = context.read<RealTimeProvider>();
      realTimeProvider.initialize();
      realTimeProvider.addListener(_onRealTimeUpdate);
      _loadOrders();
    });
  }

  void _onRealTimeUpdate() {
    if (mounted) {
      context.read<OrderProvider>().fetchMyOrders(forceRefresh: true);
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Order> _getFilteredOrders(List<Order> orders, String status) =>
      orders.where((o) => o.status.toLowerCase() == status.toLowerCase()).toList();

  String _formatCurrency(double amount) {
    final formatted = amount.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted₫';
  }

  @override
  void dispose() {
    context.read<RealTimeProvider>().removeListener(_onRealTimeUpdate);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrderProvider>(context).orders;

    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: _buildBody(orders),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Đơn hàng',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: _textDark,
          letterSpacing: -0.3,
        ),
      ),
      backgroundColor: _cardWhite,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: _textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: _cardWhite,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: _primaryGreen,
            indicatorWeight: 2.5,
            labelColor: _primaryGreen,
            unselectedLabelColor: _textLight,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: _statuses.map((status) => _buildTab(status)).toList(),
            onTap: (index) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String status) {
    final config = _statusConfig[status]!;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config['icon'] as IconData, size: 16, color: config['color'] as Color),
          const SizedBox(width: 6),
          Text(
            config['label'] as String,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Order> orders) {
    if (_isLoading && orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _primaryGreen, strokeWidth: 3),
            const SizedBox(height: 12),
            Text('Đang tải đơn hàng...', style: TextStyle(color: _textLight)),
          ],
        ),
      );
    }
    
    return TabBarView(
      controller: _tabController,
      children: _statuses.map((status) {
        final filteredOrders = _getFilteredOrders(orders, status);
        return filteredOrders.isEmpty
            ? _buildEmptyStateForStatus(status)
            : RefreshIndicator(
                onRefresh: _loadOrders,
                color: _primaryGreen,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredOrders.length,
                  itemBuilder: (_, i) => _OrderCard(
                    order: filteredOrders[i],
                    onCancel: _showCancelConfirmDialog,
                    formatCurrency: _formatCurrency,
                    statusConfig: _statusConfig,
                  ),
                ),
              );
      }).toList(),
    );
  }

  Widget _buildEmptyStateForStatus(String status) {
    final config = _statusConfig[status]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              config['icon'] as IconData,
              size: 32,
              color: config['color'] as Color,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Không có đơn hàng ${(config['label'] as String).toLowerCase()}',
            style: TextStyle(fontSize: 14, color: _textLight),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelConfirmDialog(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hủy đơn hàng?'),
        content: Text('Bạn có chắc muốn hủy đơn hàng ${order.orderId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Quay lại', style: TextStyle(color: _textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final success = await provider.cancelOrder(order.orderId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy đơn hàng'),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Hủy đơn thất bại'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final void Function(Order) onCancel;
  final String Function(double) formatCurrency;
  final Map<String, Map<String, dynamic>> statusConfig;

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _textDark = Color(0xFF2C3E2F);
  static const _textLight = Color(0xFF7C9A7E);
  static const _borderLight = Color(0xFFE8F0E8);

  const _OrderCard({
    required this.order,
    required this.onCancel,
    required this.formatCurrency,
    required this.statusConfig,
  });

  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    const baseUrl = 'https://10.0.2.2:7262';
    return imageUrl.startsWith('/') ? '$baseUrl$imageUrl' : '$baseUrl/$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    // Lấy config theo status, mặc định là pending nếu không tìm thấy
    final config = statusConfig[order.status.toLowerCase()] ?? statusConfig['pending']!;
    final statusColor = config['color'] as Color;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderLight, width: 1),
        ),
        child: Column(
          children: [
            _buildHeader(config, statusColor),
            _buildProductList(),
            _buildFooter(context, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> config, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_outlined, size: 14, color: _textLight),
              const SizedBox(width: 6),
              Text(
                order.orderId,
                style: const TextStyle(fontSize: 12, color: _textLight, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
            ),
            child: Row(
              children: [
                Icon(config['icon'] as IconData, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  config['label'] as String,
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

  Widget _buildProductList() {
    if (order.items == null || order.items!.isEmpty) return const SizedBox();
    final items = order.items!.take(2).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatCurrency(item.priceAtTime)} x ${item.quantity}',
                        style: const TextStyle(fontSize: 12, color: _textLight),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency(item.subtotal),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryGreen),
                ),
              ],
            ),
          )),
          if (order.items!.length > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.add, size: 14, color: _textLight),
                  const SizedBox(width: 6),
                  Text(
                    '${order.items!.length - 2} sản phẩm khác',
                    style: const TextStyle(fontSize: 12, color: _textLight),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductImage(OrderItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: const Color(0xFFF5F5F5),
        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? Image.network(
                _getFullImageUrl(item.imageUrl!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 24, color: _textLight),
              )
            : const Icon(Icons.image_outlined, size: 24, color: _textLight),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontSize: 12, color: _textLight)),
              Text(
                formatCurrency(order.finalAmount + 25000), // Cộng phí ship 25k như file cũ
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryGreen),
              ),
            ],
          ),
          Row(
            children: [
              if (order.status.toLowerCase() == 'pending')
                OutlinedButton(
                  onPressed: () => onCancel(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Hủy', style: TextStyle(fontSize: 13)),
                ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Chi tiết', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}