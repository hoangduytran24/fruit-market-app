import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Định nghĩa màu sắc thương hiệu
  static const Color primaryGreen = Color(0xFF7CB342);
  static const Color darkGreen = Color(0xFF0B2A1F);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _showCustomSnackBar('Đăng nhập thành công!', primaryGreen);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      _showCustomSnackBar(authProvider.error ?? 'Đăng nhập thất bại', Colors.red);
    }
  }

  void _showCustomSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? size.width * 0.2 : 24.0,
                  vertical: 20,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildWelcomeTexts(),
                          const SizedBox(height: 40),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email hoặc số điện thoại',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Mật khẩu',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 12),
                          _buildRememberAndForgot(),
                          const SizedBox(height: 30),
                          _buildLoginButton(),
                          const SizedBox(height: 30),
                          _buildDivider(),
                          const SizedBox(height: 30),
                          _buildSocialLogins(),
                          const SizedBox(height: 30),
                          _buildRegisterLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo Container
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryGreen, darkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'lib/assets/img/logo1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('GF', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GreenFruit',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen, letterSpacing: 1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text(
                'MARKET',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryGreen, letterSpacing: 1.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeTexts() {
    return Column(
      children: [
        const Text('Chào mừng trở lại!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 8),
        Text('Đăng nhập để tiếp tục mua sắm', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: darkGreen.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryGreen, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: primaryGreen),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng điền thông tin' : null,
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              activeColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (v) => setState(() => _rememberMe = v ?? false),
            ),
            Text('Ghi nhớ', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ],
        ),
        TextButton(
          onPressed: () {}, // Logic quên mật khẩu
          child: const Text('Quên mật khẩu?', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final authProvider = Provider.of<AuthProvider>(context);
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryGreen, darkGreen]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: darkGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: authProvider.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Hoặc đăng nhập với', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildSocialLogins() {
    return Row(
      children: [
        Expanded(child: _socialButton('Google', 'lib/assets/icon/google.png', Colors.red)),
        const SizedBox(width: 16),
        Expanded(child: _socialButton('Facebook', null, const Color(0xFF1877F2), iconData: Icons.facebook)),
      ],
    );
  }

  Widget _socialButton(String label, String? assetPath, Color color, {IconData? iconData}) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          assetPath != null
              ? Image.asset(assetPath, width: 20, height: 20, errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata, color: color))
              : Icon(iconData, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: darkGreen, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.grey[600])),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: const Text('Đăng ký ngay', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}