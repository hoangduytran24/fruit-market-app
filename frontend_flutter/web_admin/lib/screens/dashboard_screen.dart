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
  static const Color primary = Color(0xFF4E73DF);
  static const Color success = Color(0xFF1CC88A);
  static const Color info = Color(0xFF36B9CC);
  static const Color warning = Color(0xFFF6C23E);
  static const Color danger = Color(0xFFE74A3B);
  static const Color background = Color(0xFFF8F9FC);
  static const Color textMain = Color(0xFF5A5C69);
  static const Color textSub = Color(0xFF858796);
  static const Color cardShadow = Color(0x1A000000);
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
    {'icon': Icons.insights_rounded, 'label': 'Tổng quan', 'index': 0},
    {'icon': Icons.inventory_2_rounded, 'label': 'Sản phẩm', 'index': 1},
    {'icon': Icons.view_quilt_rounded, 'label': 'Danh mục', 'index': 2},
    {'icon': Icons.receipt_rounded, 'label': 'Đơn hàng', 'index': 3},
    {'icon': Icons.manage_accounts_rounded, 'label': 'Người dùng', 'index': 4},
    {'icon': Icons.business_center_rounded, 'label': 'Nhà cung cấp', 'index': 5},
    {'icon': Icons.local_activity_rounded, 'label': 'Voucher', 'index': 6},
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

    return Scaffold(
      backgroundColor: DashboardTheme.background,
      body: Responsive(
        mobile: screens[_selectedIndex],
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          return RefreshIndicator(
            onRefresh: () => provider.loadDashboardData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildStatCards(width, stats),
                  const SizedBox(height: 24),
                  _buildMainChartsRow(width, provider),
                  const SizedBox(height: 24),
                  _buildSecondaryRow(width, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCards(double width, DashboardStats? stats) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    int crossAxisCount = width > 1100 ? 4 : (width > 700 ? 2 : 1);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 100,
      ),
      children: [
        _StatCard(title: 'DOANH THU TỔNG', value: currencyFormat.format(stats?.totalRevenue ?? 0), icon: Icons.account_balance_wallet_rounded, color: DashboardTheme.primary),
        _StatCard(title: 'DOANH THU NAY', value: currencyFormat.format(stats?.todayRevenue ?? 0), icon: Icons.trending_up_rounded, color: DashboardTheme.success),
        _StatCard(title: 'ĐƠN MỚI', value: '${stats?.pendingOrders ?? 0}', icon: Icons.shopping_basket_rounded, color: DashboardTheme.info),
        _StatCard(title: 'KHO THẤP', value: '${stats?.lowStockProducts ?? 0}', icon: Icons.inventory_rounded, color: DashboardTheme.warning),
      ],
    );
  }

  Widget _buildMainChartsRow(double width, AdminStatisticsProvider provider) {
    bool isMobile = width < 1100;
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      children: [
        Expanded(
          flex: isMobile ? 0 : 7,
          child: _ChartContainer(
            title: 'Biến động doanh thu',
            subtitle: 'Dữ liệu miền 30 ngày gần nhất',
            child: SizedBox(height: 300, child: _AreaChartWidget(data: provider.revenueList)),
          ),
        ),
        if (!isMobile) const SizedBox(width: 24),
        if (isMobile) const SizedBox(height: 24),
        Expanded(
          flex: isMobile ? 0 : 3,
          child: _ChartContainer(
            title: 'Sản phẩm bán chạy',
            subtitle: 'Xếp hạng doanh số',
            child: SizedBox(height: 300, child: _TopProductsList(products: provider.topProducts)),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryRow(double width, AdminStatisticsProvider provider) {
    bool isMobile = width < 1100;
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      children: [
        Expanded(
          flex: isMobile ? 0 : 6,
          child: _ChartContainer(
            title: 'Lượng đơn hàng',
            subtitle: 'Thống kê 7 ngày gần nhất',
            child: SizedBox(height: 350, child: _BarChartWidget(data: provider.revenueList)),
          ),
        ),
        if (!isMobile) const SizedBox(width: 24),
        if (isMobile) const SizedBox(height: 24),
        Expanded(
          flex: isMobile ? 0 : 4,
          child: _ChartContainer(
            title: 'Cơ cấu người dùng',
            subtitle: 'Phân loại tài khoản',
            child: SizedBox(
              height: 350, 
              child: Column(
                children: [
                  Expanded(child: _DonutChartWidget(stats: provider.userStats)),
                  const SizedBox(height: 16),
                  _buildLegend(),
                ],
              )
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return const Wrap(
      spacing: 16,
      children: [
        _LegendItem(color: DashboardTheme.primary, label: 'Khách'),
        _LegendItem(color: DashboardTheme.info, label: 'Admin'),
        _LegendItem(color: DashboardTheme.danger, label: 'Khóa'),
      ],
    );
  }
}

// --- CHARTS & COMPONENTS ---

class _TopProductsList extends StatelessWidget {
  final List<TopProduct> products;
  const _TopProductsList({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const Center(child: Text("N/A"));
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length > 5 ? 5 : products.length,
      separatorBuilder: (context, index) => const Divider(height: 20, thickness: 0.5),
      itemBuilder: (context, index) {
        final p = products[index];
        return Row(
          children: [
            // SỬ DỤNG IMAGEUTILS ĐỂ FIX LỖI ẢNH TẠI ĐÂY
            ImageUtils.networkImage(
              p.imageUrl,
              width: 40,
              height: 40,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DashboardTheme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Đã bán: ${p.totalQuantitySold}', style: const TextStyle(fontSize: 11, color: DashboardTheme.textSub)),
                ],
              ),
            ),
            Text('${NumberFormat.compact().format(p.totalRevenue)}đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DashboardTheme.success)),
          ],
        );
      },
    );
  }
}

class _AreaChartWidget extends StatelessWidget {
  final List<RevenueData> data;
  const _AreaChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("Không có dữ liệu"));
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => DashboardTheme.primary,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '${NumberFormat.compact().format(s.y)}đ', 
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            )).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false, 
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.05), strokeWidth: 1)
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(), 
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 42, 
            getTitlesWidget: (v, m) => Text(NumberFormat.compact().format(v), style: const TextStyle(fontSize: 10, color: DashboardTheme.textSub))
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            getTitlesWidget: (v, m) {
              if (v % 7 == 0 && v < data.length) return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(DateFormat('dd/MM').format(data[v.toInt()].date), style: const TextStyle(fontSize: 10, color: DashboardTheme.textSub)),
              );
              return const SizedBox();
            }
          )),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList(),
            isCurved: true,
            color: DashboardTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true, 
              gradient: LinearGradient(
                begin: Alignment.topCenter, 
                end: Alignment.bottomCenter, 
                colors: [
                  DashboardTheme.primary.withOpacity(0.3), 
                  DashboardTheme.primary.withOpacity(0.01)
                ]
              )
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<RevenueData> data;
  const _BarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final recentData = data.length > 7 ? data.sublist(data.length - 7) : data;
    if (recentData.isEmpty) return const SizedBox();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (recentData.map((e) => e.orderCount.toDouble()).reduce((a, b) => a > b ? a : b) + 2),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            getTitlesWidget: (v, m) => Text(DateFormat('E').format(recentData[v.toInt()].date), style: const TextStyle(fontSize: 10))
          )),
          leftTitles: const AxisTitles(), topTitles: const AxisTitles(), rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: recentData.asMap().entries.map((e) => BarChartGroupData(
          x: e.key, 
          barRods: [
            BarChartRodData(
              toY: e.value.orderCount.toDouble(), 
              color: DashboardTheme.success, 
              width: 18, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
            )
          ]
        )).toList(),
      ),
    );
  }
}

class _DonutChartWidget extends StatelessWidget {
  final UserStats? stats;
  const _DonutChartWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const Center(child: Text("N/A"));
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 60,
        sections: [
          PieChartSectionData(value: stats!.customers.toDouble(), title: '', color: DashboardTheme.primary, radius: 20),
          PieChartSectionData(value: stats!.admins.toDouble(), title: '', color: DashboardTheme.info, radius: 20),
          PieChartSectionData(value: stats!.banned.toDouble(), title: '', color: DashboardTheme.danger, radius: 20),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: DashboardTheme.textSub)),
      ],
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartContainer({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: DashboardTheme.cardShadow, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardTheme.textMain)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: DashboardTheme.textSub)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [BoxShadow(color: DashboardTheme.cardShadow, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardTheme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(icon, color: Colors.grey.withOpacity(0.3), size: 32),
        ],
      ),
    );
  }
}