import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_app_bar.dart';
import '../utils/responsive.dart';
import '../providers/statistics_provider.dart';
import '../models/statistics.dart';
import '../utils/image_utils.dart';
import 'products_screen.dart';
import 'categogy_screen.dart';
import 'orders_screen.dart';
import 'suppliers_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';
import 'vocher_screen.dart';

class DashboardTheme {
  static const Color primary = Color(0xFF2E7D32);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF0288D1);
  static const Color warning = Color(0xFFFFA000);
  static const Color danger = Color(0xFFD32F2F);
  static const Color accent = Color(0xFF8E24AA);
  static const Color background = Color(0xFFF1F5F9);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textSub = Color(0xFF64748B);
  static const Color cardShadow = Color(0x0D000000);

  static LinearGradient getGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, color.withOpacity(0.8)],
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Tổng quan', 'index': 0},
    {'icon': Icons.inventory_2_rounded, 'label': 'Sản phẩm', 'index': 1},
    {'icon': Icons.category_rounded, 'label': 'Danh mục', 'index': 2},
    {'icon': Icons.receipt_long_rounded, 'label': 'Đơn hàng', 'index': 3},
    {'icon': Icons.people_rounded, 'label': 'Người dùng', 'index': 4},
    {'icon': Icons.business_center_rounded, 'label': 'Nhà cung cấp', 'index': 5},
    {'icon': Icons.local_offer_rounded, 'label': 'Voucher', 'index': 6},
    {'icon': Icons.settings_rounded, 'label': 'Cài đặt', 'index': 7},
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardHomeScreen(),
      const ProductsScreen(),
      const CategoriesScreen(),
      const OrdersScreen(),
      const UsersScreen(),
      const SuppliersScreen(),
      const VouchersScreen(),
      const SettingsScreen(),
    ];

    bool isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: DashboardTheme.background,
      drawer: isMobile
          ? Drawer(
              child: AdminSidebar(
                isCollapsed: false,
                selectedIndex: _selectedIndex,
                menuItems: _menuItems,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
                onToggleCollapse: () {},
              ),
            )
          : null,
      body: Responsive(
        mobile: Column(
          children: [
            AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: DashboardTheme.textMain),
              title: Text(
                _menuItems[_selectedIndex]['label'],
                style: const TextStyle(color: DashboardTheme.textMain, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: screens[_selectedIndex]),
          ],
        ),
        desktop: Row(
          children: [
            AdminSidebar(
              isCollapsed: _isSidebarCollapsed,
              selectedIndex: _selectedIndex,
              menuItems: _menuItems,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
              onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
            Expanded(
              child: Column(
                children: [
                  AdminAppBar(
                    isSidebarCollapsed: _isSidebarCollapsed,
                    title: _menuItems[_selectedIndex]['label'],
                  ),
                  Expanded(child: screens[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStatisticsProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminStatisticsProvider>();
    final stats = provider.dashboard;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: DashboardTheme.primary));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: () => provider.loadDashboardData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                // Phần thống kê 5 ô
                _buildStatCards(constraints.maxWidth, stats),
                const SizedBox(height: 24),
                _buildMainChartsRow(constraints.maxWidth, provider),
                const SizedBox(height: 24),
                _buildSecondaryRow(constraints.maxWidth, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan hệ thống',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: DashboardTheme.textMain),
        ),
        Text('Theo dõi hoạt động kinh doanh của GreenFruit Market',
            style: TextStyle(fontSize: 14, color: DashboardTheme.textSub)),
      ],
    );
  }

  Widget _buildStatCards(double maxWidth, DashboardStats? stats) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Nếu là Mobile thì chia 1 hoặc 2 cột, nếu Tablet/Desktop thì ép 5 cột
    int crossAxisCount = maxWidth < 600 ? 1 : (maxWidth < 1100 ? 2 : 5);
    
    // Điều chỉnh tỉ lệ để các ô không bị quá dài khi chia 5
    double childAspectRatio = maxWidth > 1100 ? 1.6 : 2.2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        _ModernStatCard(
          title: 'TỔNG DOANH THU',
          value: currencyFormat.format(stats?.totalRevenue ?? 0),
          icon: Icons.payments_rounded,
          color: const Color(0xFF4E73DF),
        ),
        _ModernStatCard(
          title: 'DOANH THU HÔM NAY',
          value: currencyFormat.format(stats?.todayRevenue ?? 0),
          icon: Icons.trending_up_rounded,
          color: DashboardTheme.success,
        ),
        _ModernStatCard(
          title: 'ĐƠN HÀNG MỚI',
          value: '${stats?.pendingOrders ?? 0}',
          icon: Icons.shopping_basket_rounded,
          color: DashboardTheme.info,
        ),
        _ModernStatCard(
          title: 'ĐƠN HÀNG CHỜ DUYỆT',
          value: '${stats?.pendingOrders ?? 0}',
          icon: Icons.warning_amber_rounded,
          color: DashboardTheme.warning,
        ),
        _ModernStatCard(
          title: 'TỔNG NGƯỜI DÙNG',
          value: '${stats?.totalUsers ?? 0}',
          icon: Icons.people_alt_rounded,
          color: DashboardTheme.accent,
        ),
      ],
    );
  }

  Widget _buildMainChartsRow(double maxWidth, AdminStatisticsProvider provider) {
    bool isWide = maxWidth > 1100;
    return Flex(
      direction: isWide ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: isWide ? 7 : 0,
          child: _ChartContainer(
            title: 'Biến động doanh thu',
            subtitle: 'Dữ liệu 30 ngày gần nhất',
            child: _AreaChartWidget(data: provider.revenueList),
          ),
        ),
        if (isWide) const SizedBox(width: 24),
        if (!isWide) const SizedBox(height: 24),
        Expanded(
          flex: isWide ? 3 : 0,
          child: _ChartContainer(
            title: 'Sản phẩm bán chạy',
            subtitle: 'Top 5 sản phẩm',
            child: _TopProductsList(products: provider.topProducts),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryRow(double maxWidth, AdminStatisticsProvider provider) {
    bool isWide = maxWidth > 1100;
    return Flex(
      direction: isWide ? Axis.horizontal : Axis.vertical,
      children: [
        Expanded(
          flex: isWide ? 6 : 0,
          child: _ChartContainer(
            title: 'Lượng đơn hàng',
            subtitle: '7 ngày gần nhất',
            child: _BarChartWidget(data: provider.revenueList),
          ),
        ),
        if (isWide) const SizedBox(width: 24),
        if (!isWide) const SizedBox(height: 24),
        Expanded(
          flex: isWide ? 4 : 0,
          child: _ChartContainer(
            title: 'Trạng thái đơn hàng',
            subtitle: 'Phân bổ tỉ lệ %',
            child: _DonutChartWidget(stats: provider.orderStats),
          ),
        ),
      ],
    );
  }
}

// ==================== COMPONENTS ====================

class _ModernStatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _ModernStatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: DashboardTheme.getGradient(color),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Các widget biểu đồ giữ nguyên logic của bạn...
class _ChartContainer extends StatelessWidget {
  final String title, subtitle;
  final Widget child;

  const _ChartContainer({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: DashboardTheme.cardShadow, blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: DashboardTheme.textSub)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _AreaChartWidget extends StatelessWidget {
  final List<RevenueData> data;
  const _AreaChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 300, child: Center(child: Text('Không có dữ liệu')));
    final double maxRev = data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final double maxY = maxRev * 1.2;

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[100]!, strokeWidth: 1)),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, m) => Text(NumberFormat.compact().format(v), style: const TextStyle(fontSize: 10, color: DashboardTheme.textSub)))),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                if (v.toInt() % 7 == 0 && v.toInt() < data.length) {
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('dd/MM').format(data[v.toInt()].date), style: const TextStyle(fontSize: 10, color: DashboardTheme.textSub)));
                }
                return const Text('');
              }))),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList(),
              isCurved: true,
              color: DashboardTheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [DashboardTheme.primary.withOpacity(0.3), DashboardTheme.primary.withOpacity(0.0)]))),
          ])),
    );
  }
}

class _TopProductsList extends StatelessWidget {
  final List<TopProduct> products;
  const _TopProductsList({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const Center(child: Text('Không có dữ liệu'));
    
    return Column(
      children: products.take(5).map((p) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageUtils.networkImage(p.imageUrl, width: 45, height: 45, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Đã bán: ${p.totalQuantitySold}', style: const TextStyle(fontSize: 11, color: DashboardTheme.textSub)),
                ],
              ),
            ),
            Text(
              NumberFormat.compact().format(p.totalRevenue), 
              style: const TextStyle(color: DashboardTheme.success, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<RevenueData> data;
  const _BarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final recent = data.length > 7 ? data.sublist(data.length - 7) : data;
    if (recent.isEmpty) return const SizedBox(height: 300, child: Center(child: Text('Không có dữ liệu')));
    
    final maxY = recent.map((e) => e.orderCount.toDouble()).reduce((a, b) => a > b ? a : b) + 2;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} đơn',
                  const TextStyle(color: DashboardTheme.textMain, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  if (v.toInt() < recent.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(DateFormat('E').format(recent[v.toInt()].date), 
                        style: const TextStyle(color: DashboardTheme.textSub, fontSize: 11)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: recent.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.orderCount.toDouble(),
                  gradient: LinearGradient(
                    colors: [DashboardTheme.info, DashboardTheme.info.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: DashboardTheme.info.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DonutChartWidget extends StatelessWidget {
  final OrderStats? stats;
  const _DonutChartWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox(height: 300, child: Center(child: Text('Không có dữ liệu')));

    final labels = ['Thành công', 'Đang xử lý', 'Đang giao', 'Chờ duyệt', 'Đã hủy'];
    final colors = [
      DashboardTheme.success,
      DashboardTheme.info,
      DashboardTheme.warning,
      DashboardTheme.primary,
      DashboardTheme.danger
    ];
    final values = [
      stats!.completed,
      stats!.processing,
      stats!.shipping,
      stats!.pending,
      stats!.cancelled
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              sections: List.generate(values.length, (i) {
                final percentage = stats!.total > 0 ? (values[i] / stats!.total * 100) : 0;
                return PieChartSectionData(
                  color: colors[i],
                  value: values[i].toDouble(),
                  title: percentage > 8 ? '${percentage.toInt()}%' : '',
                  radius: 40,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(labels.length, (i) {
            if (values[i] == 0) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(labels[i], style: const TextStyle(fontSize: 12, color: DashboardTheme.textMain)),
              ],
            );
          }),
        ),
      ],
    );
  }
}