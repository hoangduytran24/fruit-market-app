import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';

class UserDetailDialog extends StatelessWidget {
  final User user;
  final Map<String, String> roleDisplay;
  final Color primaryGreen;
  final Color backgroundGrey;

  const UserDetailDialog({
    super.key,
    required this.user,
    required this.roleDisplay,
    required this.primaryGreen,
    required this.backgroundGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundGrey,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(context, "Chi tiết người dùng", Icons.person_outline),
            const SizedBox(height: 16),
            _buildDialogCard([
              _buildInfoRow(Icons.badge_outlined, "Họ tên", user.fullName),
              _buildInfoRow(Icons.email_outlined, "Email", user.email),
              _buildInfoRow(Icons.phone_android_outlined, "Số điện thoại", user.phone ?? "Chưa cập nhật"),
              _buildInfoRow(Icons.admin_panel_settings_outlined, "Vai trò", roleDisplay[user.role] ?? user.role),
            ]),
            const SizedBox(height: 12),
            _buildDialogCard([
              _buildInfoRow(Icons.calendar_today_outlined, "Ngày tham gia", DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt)),
              _buildInfoRow(Icons.info_outline, "Trạng thái", user.status == 'active' ? "Đang hoạt động" : "Đang bị khóa", 
                color: user.status == 'active' ? Colors.green : Colors.red),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)
                ),
                child: const Text("Đóng"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: primaryGreen.withOpacity(0.1), 
          child: Icon(icon, color: primaryGreen, size: 20)
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        //Nút đóng
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}