import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/inventory.dart';
import '../../models/product.dart';
import '../../utils/responsive.dart';

class InventoryFormScreen extends StatefulWidget {
  final Inventory? inventory;
  final VoidCallback onSuccess;

  const InventoryFormScreen({
    super.key,
    this.inventory,
    required this.onSuccess,
  });

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _manufactureDateController = TextEditingController();
  final _expiryDateController = TextEditingController();

  String? _selectedProductId;
  String? _editingInventoryId;
  String? _duplicateBatchCodeError;
  
  String? _manufactureDateError;
  String? _expiryDateError;
  
  bool _isSubmitting = false;

  static const Color primaryGreen = Color(0xFF1A5F3A);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color bgGrey = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    _initFormData();
    _batchCodeController.addListener(_validateDuplicateBatchCode);
    _manufactureDateController.addListener(_validateDates);
    _expiryDateController.addListener(_validateDates);
  }

  @override
  void dispose() {
    _batchCodeController.removeListener(_validateDuplicateBatchCode);
    _manufactureDateController.removeListener(_validateDates);
    _expiryDateController.removeListener(_validateDates);
    _batchCodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _manufactureDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  // --- Logic Functions (Giữ nguyên) ---

  void _initFormData() {
    final isEdit = widget.inventory != null;
    _editingInventoryId = isEdit ? widget.inventory!.inventoryId : null;

    if (isEdit) {
      _selectedProductId = widget.inventory!.productId;
      _batchCodeController.text = widget.inventory!.batchCode;
      _quantityController.text = widget.inventory!.quantity.toString();
      _priceController.text = widget.inventory!.importPrice?.toString() ?? '';
      _manufactureDateController.text = widget.inventory!.manufactureDate != null
          ? DateFormat('yyyy-MM-dd').format(widget.inventory!.manufactureDate!)
          : '';
      _expiryDateController.text =
          DateFormat('yyyy-MM-dd').format(widget.inventory!.expiryDate);
    }
  }

  void _validateDuplicateBatchCode() {
    final batchCode = _batchCodeController.text.trim();
    if (batchCode.isEmpty || batchCode.length < 3) {
      setState(() => _duplicateBatchCodeError = null);
      return;
    }

    final provider = context.read<InventoryProvider>();
    final isExists = provider.isBatchCodeExists(batchCode,
        excludeId: _editingInventoryId);

    setState(() {
      if (isExists) {
        _duplicateBatchCodeError = "Mã lô hàng đã tồn tại! Vui lòng nhập mã khác.";
      } else {
        _duplicateBatchCodeError = null;
      }
    });
  }

  void _validateDates() {
    setState(() {
      final manufactureDate = _getManufactureDate();
      if (manufactureDate == null && _manufactureDateController.text.isNotEmpty) {
        _manufactureDateError = "Ngày sản xuất không hợp lệ";
      } else {
        _manufactureDateError = null;
      }

      final expiryDate = _getExpiryDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (expiryDate == null && _expiryDateController.text.isNotEmpty) {
        _expiryDateError = "Ngày hết hạn không hợp lệ";
      } else if (expiryDate != null) {
        if (expiryDate.isBefore(today)) {
          _expiryDateError = "Ngày hết hạn phải sau hoặc bằng ngày hiện tại";
        } else if (manufactureDate != null && (expiryDate.isBefore(manufactureDate) || expiryDate == manufactureDate)) {
          _expiryDateError = "Ngày hết hạn phải sau ngày sản xuất";
        } else {
          _expiryDateError = null;
        }
      } else {
        _expiryDateError = null;
      }
    });
  }

  DateTime? _getManufactureDate() {
    if (_manufactureDateController.text.isEmpty) return null;
    try { return DateTime.parse(_manufactureDateController.text); } catch (e) { return null; }
  }

  DateTime? _getExpiryDate() {
    if (_expiryDateController.text.isEmpty) return null;
    try { return DateTime.parse(_expiryDateController.text); } catch (e) { return null; }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
      _validateDates();
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _validateDates();
    
    if (_duplicateBatchCodeError != null && widget.inventory == null) {
      _showToast('Mã lô hàng đã tồn tại, vui lòng nhập mã khác', isSuccess: false);
      return;
    }

    final manufactureDate = _getManufactureDate();
    final expiryDate = _getExpiryDate();

    if (manufactureDate == null) {
      setState(() => _manufactureDateError = "Vui lòng chọn ngày sản xuất");
      return;
    }
    if (expiryDate == null) {
      setState(() => _expiryDateError = "Vui lòng chọn ngày hết hạn");
      return;
    }
    if (_expiryDateError != null) return;

    if (_selectedProductId == null && widget.inventory == null) {
      _showToast('Vui lòng chọn sản phẩm', isSuccess: false);
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<InventoryProvider>();
    bool success;

    try {
      if (widget.inventory != null) {
        success = await provider.updateInventory(
          inventoryId: _editingInventoryId!,
          quantity: int.parse(_quantityController.text),
          manufactureDate: manufactureDate,
          expiryDate: expiryDate,
          importPrice: double.parse(_priceController.text),
        );
      } else {
        success = await provider.createInventory(
          productId: _selectedProductId!,
          batchCode: _batchCodeController.text.trim().toUpperCase(),
          quantity: int.parse(_quantityController.text),
          manufactureDate: manufactureDate,
          expiryDate: expiryDate,
          importPrice: double.parse(_priceController.text),
        );
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          _showToast('Thao tác thành công', isSuccess: true);
          widget.onSuccess();
          Navigator.pop(context);
        } else {
          _showToast(provider.error ?? 'Thao tác thất bại', isSuccess: false);
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showToast('Lỗi: $e', isSuccess: false);
    }
  }

  void _showToast(String msg, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? primaryGreen : Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- UI Components (Responsive) ---

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.inventory != null;

    // Tính toán độ rộng Dialog dựa trên loại thiết bị
    double dialogWidth;
    if (context.isDesktop) {
      dialogWidth = context.screenWidth * 0.4;
    } else if (context.isTablet) {
      dialogWidth = context.screenWidth * 0.7;
    } else {
      dialogWidth = context.screenWidth * 0.95;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 10 : 40,
        vertical: 24,
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: 600, // Không cho phép quá rộng trên màn hình UltraWide
          maxHeight: context.screenHeight * 0.9,
        ),
        decoration: BoxDecoration(
          color: bgGrey,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isEdit),
            SizedBox(height: context.responsiveSpacing),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSectionTitle("Thông tin lô hàng"),
                      _buildCard([
                        _buildProductDropdown(isEdit),
                        SizedBox(height: context.responsiveSpacing),
                        _buildBatchCodeField(isEdit),
                        SizedBox(height: context.responsiveSpacing),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildField(
                                _quantityController,
                                'Số lượng',
                                Icons.numbers,
                                isDigit: true,
                              ),
                            ),
                            SizedBox(width: context.isMobile ? 8 : 12),
                            Expanded(
                              child: _buildField(
                                _priceController,
                                'Giá nhập',
                                Icons.money,
                                isDigit: true,
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionTitle("Hạn sử dụng"),
                      _buildCard([
                        _buildDateField(
                          controller: _manufactureDateController,
                          label: 'Ngày sản xuất',
                          icon: Icons.calendar_today,
                          errorText: _manufactureDateError,
                          onChanged: (_) => _validateDates(),
                        ),
                        SizedBox(height: context.responsiveSpacing),
                        _buildDateField(
                          controller: _expiryDateController,
                          label: 'Ngày hết hạn',
                          icon: Icons.event_busy,
                          errorText: _expiryDateError,
                          onChanged: (_) => _validateDates(),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _buildDialogActions(isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryGreen.withOpacity(0.15),
                  primaryGreen.withOpacity(0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
              color: primaryGreen,
              size: context.isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? "Cập nhật lô hàng" : "Nhập lô hàng mới",
            style: TextStyle(
              fontSize: context.isMobile ? 18 : 20, 
              fontWeight: FontWeight.bold
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: context.isMobile ? 11 : 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProductDropdown(bool isEdit) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.allProductsForDropdown;

    return DropdownButtonFormField<String>(
      value: _selectedProductId,
      isExpanded: true,
      hint: Text("Chọn sản phẩm",
          style: TextStyle(color: Colors.grey[500], fontSize: context.responsiveBodySize)),
      decoration: InputDecoration(
        labelText: "Sản phẩm",
        labelStyle: TextStyle(fontSize: context.responsiveBodySize),
        prefixIcon: const Icon(Icons.fastfood, size: 18),
        filled: true,
        fillColor: bgGrey.withOpacity(0.5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: products.map((Product product) {
        return DropdownMenuItem(
          value: product.productId,
          child: Text(product.productName, style: TextStyle(fontSize: context.responsiveBodySize)),
        );
      }).toList(),
      onChanged: isEdit ? null : (value) => setState(() => _selectedProductId = value),
      validator: (v) => v == null ? "Vui lòng chọn sản phẩm" : null,
      dropdownColor: Colors.white,
    );
  }

  Widget _buildBatchCodeField(bool isEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _batchCodeController,
          enabled: !isEdit,
          decoration: InputDecoration(
            labelText: 'Mã lô hàng',
            labelStyle: TextStyle(fontSize: context.responsiveBodySize),
            prefixIcon: const Icon(Icons.qr_code, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1),
            ),
            errorBorder: _duplicateBatchCodeError != null 
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: errorRed, width: 1),
                  )
                : null,
            filled: true,
            fillColor: bgGrey.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
            LengthLimitingTextInputFormatter(20),
          ],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mã lô hàng';
            if (v.trim().length < 3) return 'Mã lô tối thiểu 3 ký tự';
            if (_duplicateBatchCodeError != null) return _duplicateBatchCodeError;
            return null;
          },
          style: TextStyle(fontSize: context.responsiveBodySize),
        ),
        if (_duplicateBatchCodeError != null && _batchCodeController.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: errorRed),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _duplicateBatchCodeError!,
                    style: const TextStyle(fontSize: 11, color: errorRed),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {bool isDigit = false, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: context.responsiveBodySize),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1),
        ),
        filled: true,
        fillColor: bgGrey.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: isDigit ? TextInputType.number : TextInputType.text,
      inputFormatters: isDigit ? [FilteringTextInputFormatter.digitsOnly] : [],
      validator: (v) => (v == null || v.isEmpty) ? 'Trống' : null,
      style: TextStyle(fontSize: context.responsiveBodySize),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(controller),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: context.responsiveBodySize),
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: errorRed, width: 1),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 11),
            filled: true,
            fillColor: bgGrey.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: TextStyle(fontSize: context.responsiveBodySize),
        ),
      ],
    );
  }

  Widget _buildDialogActions(bool isEdit) {
    final hasErrors = _expiryDateError != null || 
                      _manufactureDateError != null ||
                      (_duplicateBatchCodeError != null && !isEdit);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text("Hủy bỏ", style: TextStyle(fontSize: context.isMobile ? 13 : 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting || hasErrors ? null : _saveForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      isEdit ? "Lưu thay đổi" : "Xác nhận nhập hàng",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: context.isMobile ? 13 : 14
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}