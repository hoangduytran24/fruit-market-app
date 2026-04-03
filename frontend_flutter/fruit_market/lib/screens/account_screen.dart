import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'login_screen.dart';
import 'orders_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  // --- Logic Helpers ---
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return 'U';
    List<String> nameParts = fullName.trim().split(' ');
    if (nameParts.length > 1) {
      return (nameParts.first[0] + nameParts.last[0]).toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  String _getDisplayName(String fullName) =>
      fullName.isEmpty ? 'Người dùng' : fullName.split(' ').last;

  String _getMaskedPhone(String? phone) {
    if (phone == null || phone.length < 10) return phone ?? '';
    return '${phone.substring(0, 4)} *** ${phone.substring(phone.length - 3)}';
  }

  Future<Map<String, int>> _getOrderStatistics(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.fetchMyOrders();
    final orders = orderProvider.orders;
    return {
      'pending': orders.where((o) => o.status == 'pending').length,
      'processing': orders.where((o) => o.status == 'processing').length, // Trạng thái mới
      'shipping': orders.where((o) => o.status == 'shipping').length,
      'completed': orders.where((o) => o.status == 'completed').length,
      'cancelled': orders.where((o) => o.status == 'cancelled').length,
    };
  }

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.currentUser != null;

    return Scaffold(
      backgroundColor: isLoggedIn ? const Color(0xFFF8F9FA) : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoggedIn ? _buildLoggedInView(context) : _buildLoggedOutView(context),
    );
  }

  // --- Giao diện KHI ĐÃ đăng nhập ---
  Widget _buildLoggedInView(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final fullName = user?.fullName ?? '';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildUserHeader(
            initials: _getInitials(fullName),
            displayName: _getDisplayName(fullName),
            subInfo: email.isNotEmpty ? email : _getMaskedPhone(phone),
            role: user?.role ?? 'customer',
          ),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, int>>(
            future: _getOrderStatistics(context),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return _buildLoadingContainer();
              final stats = snapshot.data!;
              return _buildOrderSection(context, stats);
            },
          ),
          const SizedBox(height: 20),
          _buildMenuSection([
            _buildMenuItem(icon: Icons.person_outline, title: 'Thông tin tài khoản', color: const Color(0xFF0B2A1F), onTap: () {}),
            _buildMenuItem(icon: Icons.location_on_outlined, title: 'Địa chỉ giao hàng', color: const Color(0xFFFF9800), badge: '2', onTap: () {}),
            _buildMenuItem(icon: Icons.history_outlined, title: 'Lịch sử mua hàng', color: const Color(0xFF9C27B0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
            _buildMenuItem(icon: Icons.favorite_outline, title: 'Yêu thích', color: const Color(0xFFF44336), badge: '12', onTap: () {}),
            _buildMenuItem(icon: Icons.card_giftcard_outlined, title: 'Voucher của tôi', color: const Color(0xFFFF6B6B), badge: '3', onTap: () {}),
          ]),
          const SizedBox(height: 20),
          _buildAISuggestion(),
          const SizedBox(height: 20),
          _buildMenuSection([
            _buildMenuItem(icon: Icons.headset_mic_outlined, title: 'Hỗ trợ', color: const Color(0xFF4CAF50), onTap: () {}),
            _buildMenuItem(icon: Icons.settings_outlined, title: 'Cài đặt', color: const Color(0xFF607D8B), onTap: () {}),
          ]),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Giao diện CHƯA đăng nhập ---
  Widget _buildLoggedOutView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_circle_outlined,
                size: 60,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Vui lòng đăng nhập',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đăng nhập để xem thông tin cá nhân và quản lý đơn hàng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sub-Widgets ---
  Widget _buildUserHeader({required String initials, required String displayName, required String subInfo, required String role}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2A1F), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                if (subInfo.isNotEmpty) Text(subInfo, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF7CB342), borderRadius: BorderRadius.circular(20)),
                  child: Text(role == 'admin' ? 'Quản trị viên' : 'Thành viên', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSection(BuildContext context, Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Đơn hàng của tôi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                  child: const Text('Xem tất cả', style: TextStyle(color: Color(0xFF0B2A1F))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(context, 'Chờ xử lý', Icons.pending_outlined, stats['pending'] ?? 0, Colors.orange, 'pending'),
              _buildStatusItem(context, 'Đóng gói', Icons.inventory_2_outlined, stats['processing'] ?? 0, Colors.amber, 'processing'),
              _buildStatusItem(context, 'Đang giao', Icons.delivery_dining, stats['shipping'] ?? 0, Colors.blue, 'shipping'),
              _buildStatusItem(context, 'Đã giao', Icons.check_circle_outline, stats['completed'] ?? 0, Colors.green, 'completed'),
              _buildStatusItem(context, 'Đã hủy', Icons.cancel_outlined, stats['cancelled'] ?? 0, Colors.red, 'cancelled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, String label, IconData icon, int count, Color color, String status) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersScreen(initialStatus: status))),
      child: SizedBox(
        width: 65, // Giới hạn chiều rộng để 5 icon nằm vừa
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (count > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: const Color(0xFFFF6B6B),
                      child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required Color color, String? badge, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(badge, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  Widget _buildAISuggestion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF0B2A1F)),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gợi ý thông minh', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Dựa trên thói quen mua hàng của bạn', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFFF6B6B), size: 20),
            SizedBox(width: 8),
            Text('Đăng xuất', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      height: 120,
      decoration: _cardDecoration(),
      child: const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}