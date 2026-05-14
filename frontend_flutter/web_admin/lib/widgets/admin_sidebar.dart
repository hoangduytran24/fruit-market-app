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
      curve: Curves.easeInOut,
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
          _buildHeader(primaryGreen, accentGreen, isMobile, isCollapsed),
          Divider(color: Colors.grey.shade200, height: 1),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
          // ✅ Chỉ hiển thị text khi không collapsed
          if (!isCollapsed) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GreenFruit',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5F3A),
                      fontSize: 16,
                    ),
                  ),
                  const Text(
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
              // ✅ Chỉ hiển thị text khi không collapsed
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
  final isMobile = Responsive.isMobile(context);
  
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? MediaQuery.of(context).size.width * 0.85 : 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
              child: Column(
                children: [
                  // Animated icon background
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade600,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              height: 1,
              color: Colors.grey.shade100,
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.grey.shade50,
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        Navigator.pop(context);
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Đăng xuất',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}