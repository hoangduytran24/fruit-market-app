import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/responsive.dart';
import '../../providers/supplier_provider.dart';
import '../../models/supplier.dart';

class SupplierFormDialog extends StatefulWidget {
  final SupplierModel? supplier;
  final VoidCallback? onSuccess;

  const SupplierFormDialog({
    super.key,
    this.supplier,
    this.onSuccess,
  });

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  
  String? _duplicateNameError;
  String? _duplicatePhoneError;
  String? _duplicateEmailError;

  static const Color primaryGreen = Color(0xFF1A5F3A);
  static const Color bgGrey = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.supplierName;
      _phoneController.text = widget.supplier!.phone ?? '';
      _addressController.text = widget.supplier!.address ?? '';
      _emailController.text = widget.supplier!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Logic Functions (Giữ nguyên) ---

  Future<bool> _checkDuplicate(String field, String value, {String? excludeId}) async {
    final suppliers = context.read<SupplierProvider>().suppliers;
    
    return suppliers.any((supplier) {
      if (excludeId != null && supplier.supplierId == excludeId) return false;
      
      switch (field) {
        case 'name':
          return supplier.supplierName.toLowerCase() == value.toLowerCase();
        case 'phone':
          return supplier.phone == value;
        case 'email':
          return supplier.email?.toLowerCase() == value.toLowerCase();
        default:
          return false;
      }
    });
  }

  void _validateName(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _duplicateNameError = null);
      return;
    }
    final isDuplicate = await _checkDuplicate('name', value.trim(), excludeId: widget.supplier?.supplierId);
    setState(() {
      _duplicateNameError = isDuplicate ? '⚠️ Tên nhà cung cấp này đã tồn tại trong hệ thống' : null;
    });
  }

  void _validatePhone(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _duplicatePhoneError = null);
      return;
    }
    final isDuplicate = await _checkDuplicate('phone', value.trim(), excludeId: widget.supplier?.supplierId);
    setState(() {
      _duplicatePhoneError = isDuplicate ? '⚠️ Số điện thoại này đã được đăng ký bởi nhà cung cấp khác' : null;
    });
  }

  void _validateEmail(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _duplicateEmailError = null);
      return;
    }
    final isDuplicate = await _checkDuplicate('email', value.trim(), excludeId: widget.supplier?.supplierId);
    setState(() {
      _duplicateEmailError = isDuplicate ? '⚠️ Email này đã được sử dụng bởi nhà cung cấp khác' : null;
    });
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    
    final isNameDuplicate = await _checkDuplicate('name', name, excludeId: widget.supplier?.supplierId);
    final isPhoneDuplicate = await _checkDuplicate('phone', phone, excludeId: widget.supplier?.supplierId);
    final isEmailDuplicate = await _checkDuplicate('email', email, excludeId: widget.supplier?.supplierId);
    
    if (isNameDuplicate || isPhoneDuplicate || isEmailDuplicate) {
      setState(() {
        _duplicateNameError = isNameDuplicate ? '⚠️ Tên nhà cung cấp này đã tồn tại trong hệ thống' : null;
        _duplicatePhoneError = isPhoneDuplicate ? '⚠️ Số điện thoại này đã được đăng ký bởi nhà cung cấp khác' : null;
        _duplicateEmailError = isEmailDuplicate ? '⚠️ Email này đã được sử dụng bởi nhà cung cấp khác' : null;
      });
      return;
    }
    
    setState(() => _isSubmitting = true);
    final provider = context.read<SupplierProvider>();
    
    bool success = widget.supplier != null
      ? await provider.updateSupplier(
          supplierId: widget.supplier!.supplierId, 
          supplierName: name, 
          address: _addressController.text.trim(), 
          phone: phone, 
          email: email,
        )
      : await provider.createSupplier(
          supplierName: name, 
          address: _addressController.text.trim(), 
          phone: phone, 
          email: email,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) { 
        widget.onSuccess?.call();
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.supplier != null ? "✅ Đã cập nhật nhà cung cấp thành công" : "✅ Đã thêm nhà cung cấp mới thành công"),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Thao tác thất bại, vui lòng kiểm tra lại thông tin!'), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }

  // --- UI Build (Integrated Responsive) ---

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    
    // Tính toán độ rộng Dialog dựa trên loại thiết bị
    double dialogWidth;
    if (context.isDesktop) {
      dialogWidth = context.screenWidth * 0.35; // Desktop: 35% màn hình
    } else if (context.isTablet) {
      dialogWidth = context.screenWidth * 0.6;  // Tablet: 60% màn hình
    } else {
      dialogWidth = context.screenWidth * 0.95; // Mobile: 95% màn hình
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 10 : 40,
        vertical: 24,
      ),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxWidth: 500), // Không vượt quá 500px theo code gốc
        padding: EdgeInsets.all(context.isMobile ? 16 : 24),
        decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(isEdit),
            SizedBox(height: context.responsiveSpacing),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSectionTitle("Thông tin cơ bản"),
                      _buildCard([
                        _buildTextField(
                          controller: _nameController, 
                          label: "Tên nhà cung cấp", 
                          icon: Icons.business,
                          onChanged: (value) => _validateName(value),
                          errorText: _duplicateNameError,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Bắt buộc nhập tên NCC";
                            if (v.trim().length < 3) return "Tên quá ngắn (tối thiểu 3 ký tự)";
                            return _duplicateNameError != null ? _duplicateNameError : null;
                          }
                        ),
                        SizedBox(height: context.responsiveSpacing),
                        _buildTextField(
                          controller: _phoneController, 
                          label: "Số điện thoại", 
                          icon: Icons.phone_android, 
                          keyboard: TextInputType.phone,
                          onChanged: (value) => _validatePhone(value),
                          errorText: _duplicatePhoneError,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Bắt buộc nhập SĐT";
                            if (!RegExp(r'^0[0-9]{9}$').hasMatch(v)) return "SĐT 10 số, bắt đầu bằng 0";
                            return _duplicatePhoneError != null ? _duplicatePhoneError : null;
                          }
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionTitle("Liên hệ & Địa chỉ"),
                      _buildCard([
                        _buildTextField(
                          controller: _emailController, 
                          label: "Email nhà cung cấp", 
                          icon: Icons.email_outlined, 
                          keyboard: TextInputType.emailAddress,
                          onChanged: (value) => _validateEmail(value),
                          errorText: _duplicateEmailError,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Bắt buộc nhập Email";
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v)) return "Email sai định dạng";
                            return _duplicateEmailError != null ? _duplicateEmailError : null;
                          }
                        ),
                        SizedBox(height: context.responsiveSpacing),
                        _buildTextField(
                          controller: _addressController, 
                          label: "Địa chỉ trụ sở", 
                          icon: Icons.location_on_outlined, 
                          maxLines: 2,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Bắt buộc nhập địa chỉ";
                            if (v.trim().length < 5) return "Vui lòng nhập địa chỉ cụ thể hơn";
                            return null;
                          }
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDialogActions(isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(bool isEdit) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: primaryGreen.withOpacity(0.1), 
          child: Icon(isEdit ? Icons.edit_rounded : Icons.add_business_rounded, color: primaryGreen, size: 20)
        ),
        const SizedBox(width: 12),
        Text(
          isEdit ? "Cập nhật NCC" : "Thêm nhà cung cấp", 
          style: TextStyle(fontSize: context.isMobile ? 16 : 18, fontWeight: FontWeight.bold)
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.close_rounded, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8), 
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: context.isMobile ? 10 : 11, 
            fontWeight: FontWeight.bold, 
            color: Colors.grey[600], 
            letterSpacing: 0.8
          )
        )
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    int maxLines = 1, 
    TextInputType keyboard = TextInputType.text, 
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
    Function(String)? onChanged,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller, 
      maxLines: maxLines, 
      keyboardType: keyboard, 
      validator: validator,
      inputFormatters: formatters,
      onChanged: onChanged,
      style: TextStyle(fontSize: context.responsiveBodySize),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(fontSize: context.responsiveBodySize),
        prefixIcon: Icon(icon, size: 18),
        filled: true, 
        fillColor: bgGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 11, height: 0.8, color: Colors.orange),
      ),
    );
  }

  Widget _buildDialogActions(bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context), 
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ), 
            child: Text("Hủy bỏ", style: TextStyle(fontSize: context.isMobile ? 13 : 14))
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2, 
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _saveSupplier,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0
            ),
            child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : Text(
                  isEdit ? "Lưu thay đổi" : "Xác nhận tạo", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.isMobile ? 13 : 14)
                ),
          )
        ),
      ],
    );
  }
}