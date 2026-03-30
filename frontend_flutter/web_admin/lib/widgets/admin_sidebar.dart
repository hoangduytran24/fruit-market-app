import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';

class AdminSidebar extends StatelessWidget {
  final bool isCollapsed;
  final int selectedIndex;
  final List<Map<String, dynamic>> menuItems;
  final Function(int) onItemSelected;
  final VoidCallback onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.isCollapsed,
    required this.selectedIndex,
    required this.menuItems,
    required this.onItemSelected,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1A5F3A);
    const accentGreen = Color(0xFF4CAF50);

    final isMobile = context.isMobile;

    final collapsedWidth = isMobile ? 70.0 : 85.0;
    final expandedWidth = isMobile ? 240.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Đảm bảo các con sát lề trái
        children: [
          // ================= HEADER =================
          _buildHeader(primaryGreen, accentGreen, isMobile),

          Divider(color: Colors.grey.shade200, height: 1),

          // ================= MENU =================
          // Không dùng Expanded ở đây để tránh chiếm hết không gian, 
          // ta dùng một cột chứa menu items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: menuItems.map((item) {
                final isSelected = selectedIndex == item['index'];
                return _buildMenuItem(
                  icon: item['icon'],
                  label: item['label'],
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  isMobile: isMobile,
                  onTap: () => onItemSelected(item['index']),
                );
              }).toList(),
            ),
          ),

          // ================= SPACER =================
          // Widget này sẽ đẩy tất cả phần bên dưới nó xuống sát đáy Column
          const Spacer(),

          // ================= FOOTER (ĐĂNG XUẤT) =================
          Divider(color: Colors.grey.shade200, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20), // Padding dưới sâu hơn để đẹp mắt
            child: _buildMenuItem(
              icon: Icons.logout,
              label: 'Đăng xuất',
              isSelected: false,
              isCollapsed: isCollapsed,
              isMobile: isMobile,
              isLogout: true,
              onTap: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER (Giữ nguyên logic của bạn) =================
  Widget _buildHeader(Color primaryGreen, Color accentGreen, bool isMobile) {
    return Container(
      height: isMobile ? 100 : 120,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onToggleCollapse,
              child: Container(
                width: isCollapsed ? 40 : 50,
                height: isCollapsed ? 40 : 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: [primaryGreen, accentGreen]),
                ),
                child: const Icon(Icons.eco, color: Colors.white),
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 10),
            const Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GreenFruit',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A5F3A)),
                  ),
                  Text(
                    'MARKET',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= MENU ITEM =================
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isCollapsed,
    required bool isMobile,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    const primaryGreen = Color(0xFF1A5F3A);
    const lightGreen = Color(0xFFE8F5E9);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: isMobile ? 45 : 50,
          // Khi mở rộng thì padding trái 12, khi thu nhỏ thì căn giữa (0)
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
          decoration: BoxDecoration(
            color: isSelected ? lightGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isLogout ? Colors.red : (isSelected ? primaryGreen : Colors.grey),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: isLogout ? Colors.red : (isSelected ? primaryGreen : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // ================= DIALOG ĐĂNG XUẤT =================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5F3A), foregroundColor: Colors.white),
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}