import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class AddAdminDialog extends StatefulWidget {
  final Color primaryGreen;
  final Color backgroundGrey;

  const AddAdminDialog({
    super.key,
    required this.primaryGreen,
    required this.backgroundGrey,
  });

  @override
  State<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String? _serverEmailError;
  String? _serverPhoneError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.backgroundGrey,
          borderRadius: BorderRadius.circular(28)
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(context, "Thêm Quản trị viên", Icons.add_moderator_outlined),
                const SizedBox(height: 16),
                _buildDialogCard([
                  _buildTextField(
                    controller: _nameController,
                    label: "Họ và tên",
                    icon: Icons.person_outline,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ỹ\s]'))],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Không được để trống";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailController,
                    label: "Email đăng nhập",
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    errorText: _serverEmailError,
                    onChanged: (v) => setState(() => _serverEmailError = null),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Bắt buộc nhập email";
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v)) return "Định dạng email không hợp lệ";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneController,
                    label: "Số điện thoại",
                    icon: Icons.phone_android_outlined,
                    keyboard: TextInputType.phone,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10)
                    ],
                    errorText: _serverPhoneError,
                    onChanged: (v) => setState(() => _serverPhoneError = null),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Bắt buộc nhập SĐT";
                      if (v.length != 10) return "Phải có 10 số";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _passwordController,
                    label: "Mật khẩu",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Bắt buộc nhập mật khẩu";
                      if (v.length < 6) return "Tối thiểu 6 ký tự";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: "Nhập lại mật khẩu",
                    icon: Icons.lock_reset_outlined,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) return "Mật khẩu không khớp";
                      return null;
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: userProvider.isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Hủy"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: userProvider.isLoading ? null : () => _saveAdmin(context, userProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: userProvider.isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Xác nhận tạo", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAdmin(BuildContext context, UserProvider userProvider) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await userProvider.addAdmin(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim()
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thêm quản trị viên thành công"),
            backgroundColor: Color(0xFF1A5F3A),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      String errorMsg = e.toString().toLowerCase();
      setState(() {
        if (errorMsg.contains("email")) {
          _serverEmailError = "Email này đã được sử dụng";
        } else if (errorMsg.contains("phone") || errorMsg.contains("số điện thoại")) {
          _serverPhoneError = "Số điện thoại này đã được sử dụng";
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')))
          );
        }
      });
    }
  }

  Widget _buildDialogHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: widget.primaryGreen.withOpacity(0.1),
          child: Icon(icon, color: widget.primaryGreen, size: 20)
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // ✅ Nút đóng (dấu X) ở góc phải
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffixIcon,
        errorText: errorText,
        filled: true,
        fillColor: widget.backgroundGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }
}