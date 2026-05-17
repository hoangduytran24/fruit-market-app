import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeTerms = false;
  
  // ========== THÊM: Biến cho password strength indicator ==========
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  // ===============================================================

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color primaryGreen = Color(0xFF7CB342);
  static const Color darkGreen = Color(0xFF0B2A1F);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _animationController.forward();
    
    // ========== THÊM: Lắng nghe thay đổi mật khẩu ==========
    _passwordController.addListener(_updatePasswordStrength);
  }
  
  // ========== THÊM: Cập nhật strength indicators ==========
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }
  
  double get _passwordStrength {
    int count = 0;
    if (_hasMinLength) count++;
    if (_hasUppercase) count++;
    if (_hasLowercase) count++;
    if (_hasNumber) count++;
    if (_hasSpecialChar) count++;
    return count / 5;
  }
  
  Color get _passwordStrengthColor {
    final strength = _passwordStrength;
    if (strength <= 0.4) return Colors.red;
    if (strength <= 0.7) return Colors.orange;
    return Colors.green;
  }
  
  String get _passwordStrengthText {
    final strength = _passwordStrength;
    if (strength <= 0.4) return 'Yếu';
    if (strength <= 0.7) return 'Trung bình';
    return 'Mạnh';
  }
  // =========================================================

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      _showSnackBar('Vui lòng đồng ý với điều khoản sử dụng', Colors.orange);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar('Đăng ký thành công!', primaryGreen);
      Future.delayed(const Duration(seconds: 2), _navigateToLogin);
    } else {
      _showSnackBar(authProvider.error ?? 'Đăng ký thất bại', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 450 : 500),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40.0 : 24.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildHeaderLogo(),
                      const SizedBox(height: 30),
                      _buildTitleSection(),
                      const SizedBox(height: 30),
                      _buildForm(),
                      const SizedBox(height: 20),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 30),
                      _buildRegisterButton(),
                      const SizedBox(height: 20),
                      _buildLoginLink(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: darkGreen),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Đăng ký',
        style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryGreen, darkGreen]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.4),
                blurRadius: 15, spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'lib/assets/img/logo1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('GF', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GreenFruit', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkGreen)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('MARKET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        const Text('Tạo tài khoản mới', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 8),
        Text('Điền thông tin để bắt đầu mua sắm', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInputField(
            controller: _fullNameController,
            hintText: 'Họ và tên',
            icon: Icons.person_outline,
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _emailController,
            hintText: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Email không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _phoneController,
            hintText: 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || !RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$').hasMatch(v)) ? 'Số điện thoại không hợp lệ' : null,
          ),
          const SizedBox(height: 16),
          // ========== SỬA: Password field với validator mạnh hơn ==========
          _buildPasswordField(
            controller: _passwordController,
            hintText: 'Mật khẩu',
            isVisible: _isPasswordVisible,
            onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
              if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
              if (!v.contains(RegExp(r'[A-Z]'))) return 'Mật khẩu phải có ít nhất 1 chữ hoa';
              if (!v.contains(RegExp(r'[a-z]'))) return 'Mật khẩu phải có ít nhất 1 chữ thường';
              if (!v.contains(RegExp(r'[0-9]'))) return 'Mật khẩu phải có ít nhất 1 số';
              if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
              return null;
            },
          ),
          // ========== THÊM: Password strength indicator ==========
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
          ],
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hintText: 'Xác nhận mật khẩu',
            isVisible: _isConfirmPasswordVisible,
            onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            validator: (v) {
              if (v != _passwordController.text) return 'Mật khẩu không khớp';
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  // ========== THÊM: Password strength indicator widget ==========
  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: Colors.grey[200],
                  color: _passwordStrengthColor,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _passwordStrengthColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _passwordStrengthColor.withOpacity(0.3)),
              ),
              child: Text(
                _passwordStrengthText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _passwordStrengthColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildRequirementChip('Ít nhất 8 ký tự', _hasMinLength),
            _buildRequirementChip('Chữ hoa (A-Z)', _hasUppercase),
            _buildRequirementChip('Chữ thường (a-z)', _hasLowercase),
            _buildRequirementChip('Số (0-9)', _hasNumber),
            _buildRequirementChip('Ký tự đặc biệt (!@#...)', _hasSpecialChar),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRequirementChip(String text, bool isMet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMet ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMet ? Colors.green : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: isMet ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  // ===============================================================

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeTerms,
          activeColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (v) => setState(() => _agreeTerms = v ?? false),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              children: const [
                TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(text: 'Điều khoản sử dụng', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                TextSpan(text: ' và '),
                TextSpan(text: 'Chính sách bảo mật', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    final auth = context.watch<AuthProvider>();
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryGreen, darkGreen]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: darkGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: auth.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('ĐĂNG KÝ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Đã có tài khoản? ', style: TextStyle(color: Colors.grey[600])),
        GestureDetector(
          onTap: _navigateToLogin,
          child: const Text('Đăng nhập', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hintText, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: primaryGreen, size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String hintText, required bool isVisible, required VoidCallback onToggle, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.lock_outline, color: primaryGreen, size: 22),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: primaryGreen, size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }
}