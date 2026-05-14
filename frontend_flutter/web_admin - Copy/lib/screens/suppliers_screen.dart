import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';
import '../utils/responsive.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  
  // Lưu trữ lỗi trùng lặp theo từng trường
  String? _duplicateNameError;
  String? _duplicatePhoneError;
  String? _duplicateEmailError;

  static const Color primaryGreen = Color(0xFF1A5F3A);
  static const Color bgGrey = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<SupplierProvider>().fetchSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final isMobile = context.isMobile;
    final filteredList = _getFilteredSuppliers(supplierProvider.suppliers);

    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        children: [
          _buildToolBar(isMobile),
          Expanded(
            child: supplierProvider.isLoading && supplierProvider.suppliers.isEmpty
                ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: primaryGreen,
                        child: _buildSupplierGrid(filteredList, isMobile),
                      ),
          ),
        ],
      ),
    );
  }

  // --- TOOLBAR ---
  Widget _buildToolBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? 180 : 350,
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm nhà cung cấp...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openSupplierDialog(null),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(isMobile ? 'Thêm' : 'Thêm nhà cung cấp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --- GRID & CARD ---
  Widget _buildSupplierGrid(List<SupplierModel> list, bool isMobile) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 140, 
      ),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildSupplierCard(list[index]),
    );
  }

  Widget _buildSupplierCard(SupplierModel supplier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.business_rounded, color: primaryGreen, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(supplier.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  _infoRow(Icons.phone_android_outlined, supplier.phone ?? 'N/A'),
                  const SizedBox(height: 2),
                  _infoRow(Icons.location_on_outlined, supplier.address ?? 'N/A'),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _openSupplierDialog(supplier)),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => _confirmDelete(supplier)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]), 
        const SizedBox(width: 6), 
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))
      ]
    );
  }

  // --- KIỂM TRA TRÙNG LẶP ---
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

  void _validateName(String value, {String? excludeId}) async {
    if (value.trim().isEmpty) {
      setState(() => _duplicateNameError = null);
      return;
    }
    final isDuplicate = await _checkDuplicate('name', value.trim(), excludeId: excludeId);
    setState(() {
      _duplicateNameError = isDuplicate ? '⚠️ Tên nhà cung cấp này đã tồn tại trong hệ thống' : null;
    });
  }

  void _validatePhone(String value, {String? excludeId}) async {
    if (value.trim().isEmpty) {
      setState(() => _duplicatePhoneError = null);
      return;
    }
    final isDuplicate = await _checkDuplicate('phone', value.trim(), excludeId: excludeId);
    setState(() {
      _duplicatePhoneError = isDuplicate ? '⚠️ Số điện thoại này đã được đăng ký bởi nhà cung cấp khác' : null;
    });
  }

  void _validateEmail(String value, {String? excludeId}) async {
    if (value.trim().isEmpty) {
      setState(() => _duplicateEmailError = null);
      return;
    }
    final isDuplicate = await _checkDuplicate('email', value.trim(), excludeId: excludeId);
    setState(() {
      _duplicateEmailError = isDuplicate ? '⚠️ Email này đã được sử dụng bởi nhà cung cấp khác' : null;
    });
  }

  // --- MODERN DIALOG ---
  void _openSupplierDialog(SupplierModel? supplier) {
    final isEdit = supplier != null;
    
    // Reset lỗi trùng lặp
    _duplicateNameError = null;
    _duplicatePhoneError = null;
    _duplicateEmailError = null;
    
    if (isEdit) {
      _nameController.text = supplier.supplierName;
      _phoneController.text = supplier.phone ?? '';
      _addressController.text = supplier.address ?? '';
      _emailController.text = supplier.email ?? '';
    } else {
      _nameController.clear(); 
      _phoneController.clear(); 
      _addressController.clear(); 
      _emailController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(28)),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader(isEdit),
                    const SizedBox(height: 16),
                    _buildSectionTitle("Thông tin cơ bản"),
                    _buildCard([
                      _buildTextField(
                        controller: _nameController, 
                        label: "Tên nhà cung cấp", 
                        icon: Icons.business,
                        onChanged: (value) => _validateName(value, excludeId: isEdit ? supplier.supplierId : null),
                        errorText: _duplicateNameError,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Bắt buộc nhập tên NCC";
                          if (v.trim().length < 3) return "Tên quá ngắn (tối thiểu 3 ký tự)";
                          return _duplicateNameError != null ? _duplicateNameError : null;
                        }
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _phoneController, 
                        label: "Số điện thoại", 
                        icon: Icons.phone_android, 
                        keyboard: TextInputType.phone,
                        onChanged: (value) => _validatePhone(value, excludeId: isEdit ? supplier.supplierId : null),
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
                        onChanged: (value) => _validateEmail(value, excludeId: isEdit ? supplier.supplierId : null),
                        errorText: _duplicateEmailError,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Bắt buộc nhập Email";
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(v)) return "Email sai định dạng";
                          return _duplicateEmailError != null ? _duplicateEmailError : null;
                        }
                      ),
                      const SizedBox(height: 12),
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
                    const SizedBox(height: 24),
                    _buildDialogActions(isEdit, supplier?.supplierId, setStateDialog),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(bool isEdit) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: primaryGreen.withOpacity(0.1), child: Icon(isEdit ? Icons.edit_rounded : Icons.add_business_rounded, color: primaryGreen, size: 20)),
        const SizedBox(width: 12),
        Text(isEdit ? "Cập nhật NCC" : "Thêm nhà cung cấp", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 20)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8), 
        child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.8))
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
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label, 
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

  Widget _buildDialogActions(bool isEdit, String? id, StateSetter setStateDialog) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context), 
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
            child: const Text("Hủy bỏ")
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2, 
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _saveSupplier(isEdit, id, setStateDialog),
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : Text(isEdit ? "Lưu thay đổi" : "Xác nhận tạo", style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ),
      ],
    );
  }

  Future<void> _saveSupplier(bool isEdit, String? id, StateSetter setStateDialog) async {
    // Validate form và kiểm tra lỗi trùng
    if (!_formKey.currentState!.validate()) return;
    
    // Kiểm tra lại lỗi trùng lặp một lần nữa trước khi submit
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    
    final isNameDuplicate = await _checkDuplicate('name', name, excludeId: isEdit ? id : null);
    final isPhoneDuplicate = await _checkDuplicate('phone', phone, excludeId: isEdit ? id : null);
    final isEmailDuplicate = await _checkDuplicate('email', email, excludeId: isEdit ? id : null);
    
    if (isNameDuplicate || isPhoneDuplicate || isEmailDuplicate) {
      setState(() {
        _duplicateNameError = isNameDuplicate ? '⚠️ Tên nhà cung cấp này đã tồn tại trong hệ thống' : null;
        _duplicatePhoneError = isPhoneDuplicate ? '⚠️ Số điện thoại này đã được đăng ký bởi nhà cung cấp khác' : null;
        _duplicateEmailError = isEmailDuplicate ? '⚠️ Email này đã được sử dụng bởi nhà cung cấp khác' : null;
      });
      return;
    }
    
    setStateDialog(() => _isSubmitting = true);
    
    final provider = context.read<SupplierProvider>();
    
    bool success = isEdit 
      ? await provider.updateSupplier(
          supplierId: id!, 
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
      setStateDialog(() => _isSubmitting = false);
      if (success) { 
        Navigator.pop(context); 
        _loadData(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? "✅ Đã cập nhật nhà cung cấp thành công" : "✅ Đã thêm nhà cung cấp mới thành công"),
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

  Future<void> _confirmDelete(SupplierModel supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Xác nhận xóa nhà cung cấp'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa nhà cung cấp',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              '“${supplier.supplierName}”',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lưu ý: Nếu nhà cung cấp này vẫn còn sản phẩm liên quan, hệ thống sẽ không cho phép xóa. Vui lòng xóa toàn bộ sản phẩm trước khi thực hiện thao tác này.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Hủy bỏ', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Xóa nhà cung cấp', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context
          .read<SupplierProvider>()
          .deleteSupplier(supplier.supplierId);

      if (mounted) {
        if (success) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Đã xóa nhà cung cấp thành công'),
                ],
              ),
              backgroundColor: primaryGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.block, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Không thể xóa nhà cung cấp này',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vui lòng xóa toàn bộ sản phẩm do nhà cung cấp này cung ứng trước khi thực hiện thao tác.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  List<SupplierModel> _getFilteredSuppliers(List<SupplierModel> suppliers) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return suppliers;
    return suppliers.where((s) => 
      s.supplierName.toLowerCase().contains(query) || 
      (s.phone ?? "").contains(query)
    ).toList();
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Icon(Icons.business_center_outlined, size: 64, color: Colors.grey.shade300), 
        const SizedBox(height: 12),
        const Text('Không tìm thấy nhà cung cấp nào', style: TextStyle(color: Colors.grey))
      ]
    )
  );
}