import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Trạng thái cho các cài đặt
  bool _isNotificationEnabled = true;
  bool _isDarkMode = false;
  String _language = "Tiếng Việt";

  // Palette màu thương hiệu GreenFruit
  static const Color primaryGreen = Color(0xFF1A5F3A);
  static const Color bgGrey = Color(0xFFF4F7F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          "Hệ thống", // Đã bỏ chữ "Cài đặt" ở header
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Cá nhân & Tài khoản"),
            _buildSettingsCard([
              _buildListTile(
                icon: Icons.person_outline,
                title: "Thông tin cá nhân",
                subtitle: "Chỉnh sửa tên, email, số điện thoại",
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.lock_outline,
                title: "Đổi mật khẩu",
                subtitle: "Cập nhật mật khẩu định kỳ để bảo mật",
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionTitle("Cài đặt hệ thống"),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: "Thông báo đẩy",
                subtitle: "Nhận tin nhắn về đơn hàng và tồn kho",
                value: _isNotificationEnabled,
                onChanged: (val) => setState(() => _isNotificationEnabled = val),
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.language_outlined,
                title: "Ngôn ngữ",
                subtitle: _language,
                onTap: () => _showLanguagePicker(),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: "Chế độ tối",
                subtitle: "Giảm mỏi mắt khi làm việc ban đêm",
                value: _isDarkMode,
                onChanged: (val) => setState(() => _isDarkMode = val),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle("Hỗ trợ & Thông tin"),
            _buildSettingsCard([
              _buildListTile(
                icon: Icons.help_outline,
                title: "Trung tâm trợ giúp",
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.info_outline,
                title: "Phiên bản ứng dụng",
                subtitle: "v1.0.2 - GreenFruit Market",
                onTap: null, 
              ),
            ]),
            
            const SizedBox(height: 40),
            // Nút đăng xuất đã được loại bỏ hoàn toàn tại đây
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS (GIỮ NGUYÊN DESIGN CARD) ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryGreen, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, size: 18, color: Colors.grey) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryGreen, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primaryGreen,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Chọn ngôn ngữ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _languageOption("Tiếng Việt"),
            _languageOption("English"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String lang) {
    return ListTile(
      title: Text(lang),
      trailing: _language == lang ? const Icon(Icons.check, color: primaryGreen) : null,
      onTap: () {
        setState(() => _language = lang);
        Navigator.pop(context);
      },
    );
  }
}