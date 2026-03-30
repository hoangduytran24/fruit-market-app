import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSidebarCollapsed;
  final String title;

  const AdminAppBar({
    super.key,
    required this.isSidebarCollapsed,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    const primaryGreen = Color(0xFF1B3D2F);
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: isMobile ? 16 : 20),
          child: Text(
            title,
            style: TextStyle(
              color: primaryGreen,
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          // Nút hỗ trợ/Câu hỏi - Ẩn trên mobile
          if (!isMobile)
            _buildActionIcon(Icons.help_outline),
          
          // Notifications với Badge
          _buildNotificationIcon(isMobile),
          
          if (!isMobile) const SizedBox(width: 12),
          if (!isMobile) 
            const VerticalDivider(width: 1, indent: 20, endIndent: 20, color: Colors.grey),
          const SizedBox(width: 8),
          
          // User Profile
          _buildUserProfile(context, user, primaryGreen, isMobile),
          
          SizedBox(width: isMobile ? 12 : 20),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return IconButton(
      icon: Icon(icon, color: Colors.grey[600], size: 22),
      onPressed: () {},
      tooltip: 'Trợ giúp',
    );
  }

  Widget _buildNotificationIcon(bool isMobile) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded, 
            color: Colors.grey[600], 
            size: isMobile ? 22 : 24,
          ),
          onPressed: () {},
          tooltip: 'Thông báo',
        ),
        Positioned(
          right: isMobile ? 10 : 12,
          top: isMobile ? 10 : 12,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(BuildContext context, dynamic user, Color primaryGreen, bool isMobile) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 55),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) {
        if (value == 'logout') _showLogoutDialog(context);
      },
      itemBuilder: (context) => [
        _buildPopupItem('profile', Icons.person_outline, 'Thông tin cá nhân'),
        _buildPopupItem('settings', Icons.settings_outlined, 'Cài đặt hệ thống'),
        const PopupMenuDivider(),
        _buildPopupItem('logout', Icons.logout_rounded, 'Đăng xuất', isDelete: true),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 8, 
          vertical: isMobile ? 2 : 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7CB342), Color(0xFF1B3D2F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2), 
                    blurRadius: 8, 
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isMobile ? 16 : 18,
                backgroundColor: Colors.transparent,
                child: Text(
                  user?.fullName?.substring(0, 1).toUpperCase() ?? 'A',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ),
            
            // Hiển thị tên khi không phải mobile
            if (!isMobile) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user?.fullName ?? 'Quản trị viên',
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF2D3436),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Administrator',
                    style: TextStyle(
                      fontSize: 11, 
                      color: Colors.grey[500], 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label, {bool isDelete = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDelete ? Colors.redAccent : Colors.grey[700]),
          const SizedBox(width: 12),
          Text(
            label, 
            style: TextStyle(
              color: isDelete ? Colors.redAccent : Colors.black87, 
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B3D2F),
        title: const Text('Đăng xuất?', style: TextStyle(color: Colors.white)),
        content: const Text('Mọi phiên làm việc hiện tại sẽ kết thúc.', style: TextStyle(color: Colors.white70)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}