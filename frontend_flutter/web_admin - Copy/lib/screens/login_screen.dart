import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import '../utils/responsive.dart';

class GreenFruitAdminLogin extends StatefulWidget {
  const GreenFruitAdminLogin({super.key});

  @override
  State<GreenFruitAdminLogin> createState() => _GreenFruitAdminLoginState();
}

class _GreenFruitAdminLoginState extends State<GreenFruitAdminLogin> {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- HÀM HIỂN THỊ DIALOG THÔNG BÁO LỖI ---
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              'Thông báo',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Color(0xFF7CB342), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    // 1. Kiểm tra validation của Form
    if (!_formKey.currentState!.validate()) return;
    
    // 2. Chặn việc nhấn liên tiếp khi đang xử lý
    if (_isLoading) return;
    
    FocusScope.of(context).unfocus(); 
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 3. Thực hiện đăng nhập với timeout 30s
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (mounted) _showErrorDialog('Kết nối quá thời gian, vui lòng kiểm tra lại server!');
          return false;
        },
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (success) {
        // Đăng nhập thành công - Hiện SnackBar rồi chuyển trang
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chào mừng Admin quay trở lại!'),
            backgroundColor: const Color(0xFF7CB342),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        // 4. HIỂN THỊ LỖI - Không load lại trang, chỉ hiện Dialog
        // Lấy đúng message "Sai tên đăng nhập hoặc mật khẩu" từ Backend thông qua Provider
        _showErrorDialog(authProvider.error ?? 'Tài khoản hoặc mật khẩu không chính xác.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Đã xảy ra lỗi hệ thống: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 1000,
              height: isMobile ? null : 600,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  if (!isMobile) _buildDesktopBanner(),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 60, 
                        vertical: isMobile ? 40 : 0
                      ),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLogo(),
                              const SizedBox(height: 12),
                              const Text(
                                'GreenFruit',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B2A1F)),
                              ),
                              const Text(
                                'MARKET',
                                style: TextStyle(fontSize: 12, letterSpacing: 2, color: Color(0xFF7CB342), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 30),
                              const Text(
                                'Web Admin Sign In',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 40),
                              _buildInput(
                                controller: _usernameController,
                                hint: 'Username or Admin ID',
                                icon: Icons.person_outline,
                                autofillHints: const [AutofillHints.username],
                                validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập Username' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildInput(
                                controller: _passwordController,
                                hint: 'Admin Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                autofillHints: const [AutofillHints.password],
                                validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showErrorDialog('Vui lòng liên hệ quản trị viên cấp cao để cấp lại mật khẩu!'),
                                  child: const Text('Quên mật khẩu?', style: TextStyle(color: Color(0xFF7CB342))),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildLoginButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildDesktopBanner() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B3D2F), Color(0xFF0B2A1F)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.eco, size: 60, color: Color(0xFF1B3D2F)),
            ),
            const SizedBox(height: 30),
            const Text(
              'GreenFruit Market\nAdmin Portal',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hệ thống quản lý bán hàng và kho vận thông minh.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 70, 
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7CB342), Color(0xFF0B2A1F)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF7CB342).withOpacity(0.4), blurRadius: 15)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'lib/assets/img/logo1.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text('GF', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(colors: [Color(0xFF7CB342), Color(0xFF0B2A1F)]),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7CB342).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(
                      color: Colors.white, 
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'ĐĂNG NHẬP',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      autofillHints: autofillHints,
      onFieldSubmitted: (_) => _handleLogin(), // Trigger login khi nhấn Enter
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        prefixIcon: Icon(icon, color: const Color(0xFF7CB342), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 18),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7CB342), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}