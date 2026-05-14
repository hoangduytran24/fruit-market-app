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

    return Container(
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
        children: [
          // ================= HEADER =================
          _buildHeader(primaryGreen, accentGreen, isMobile, isCollapsed),

          Divider(color: Colors.grey.shade200, height: 1),

          // ================= MENU - DÙNG Expanded ĐỂ CUỘN =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == item['index'];
                return _buildMenuItem(
                  icon: item['icon'],
                  label: item['label'],
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  isMobile: isMobile,
                  onTap: () => onItemSelected(item['index']),
                );
              },
            ),
          ),

          // ================= FOOTER (ĐĂNG XUẤT) =================
          Divider(color: Colors.grey.shade200, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
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

  Widget _buildHeader(
    Color primaryGreen, 
    Color accentGreen, 
    bool isMobile, 
    bool isCollapsed,
  ) {
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF1A5F3A),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'MARKET',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12, 
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

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
                size: isCollapsed ? 24 : 22,
                color: isLogout 
                    ? Colors.red 
                    : (isSelected ? primaryGreen : Colors.grey.shade600),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLogout 
                          ? Colors.red 
                          : (isSelected ? primaryGreen : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Xác nhận đăng xuất'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Hủy', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              Navigator.pop(context); // Đóng dialog trước
              await authProvider.logout();
              if (context.mounted) {
                // Điều hướng về màn hình login
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}