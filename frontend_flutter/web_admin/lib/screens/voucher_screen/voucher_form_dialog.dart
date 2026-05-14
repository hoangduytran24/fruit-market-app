import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/voucher.dart';
import '../../providers/voucher_provider.dart';

class VoucherFormDialog extends StatefulWidget {
  final Voucher? voucher;
  final VoidCallback? onSuccess;

  const VoucherFormDialog({
    super.key,
    this.voucher,
    this.onSuccess,
  });

  @override
  State<VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String _selectedDiscountType = 'percent';
  String? _duplicateCodeError;
  String? _editingVoucherId;

  static const Color primaryGreen = Color(0xFF27AE60);
  static const Color bgGrey = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    _editingVoucherId = widget.voucher?.voucherId;
    
    if (widget.voucher != null) {
      _codeController.text = widget.voucher!.voucherCode;
      _valueController.text = widget.voucher!.discountValue.toString();
      _minOrderController.text = widget.voucher!.minOrderValue.toString();
      _maxDiscountController.text = widget.voucher!.maxDiscountValue.toString();
      _quantityController.text = widget.voucher!.quantity.toString();
      _startDateController.text = widget.voucher!.startDate?.toIso8601String().split('T')[0] ?? '';
      _endDateController.text = widget.voucher!.endDate?.toIso8601String().split('T')[0] ?? '';
      _selectedDiscountType = widget.voucher!.discountType;
    }
    
    _codeController.addListener(_validateDuplicateCode);
  }

  @override
  void dispose() {
    _codeController.removeListener(_validateDuplicateCode);
    _codeController.dispose();
    _valueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _quantityController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _validateDuplicateCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 5) {
      setState(() => _duplicateCodeError = null);
      return;
    }

    final provider = context.read<AdminVoucherProvider>();
    final isExists = provider.isVoucherCodeExists(code, excludeId: _editingVoucherId);
    
    setState(() {
      if (isExists) {
        _duplicateCodeError = "Mã voucher đã tồn tại! Vui lòng chọn mã khác.";
      } else {
        _duplicateCodeError = null;
      }
    });
  }

  Future<void> _selectDate(TextEditingController controller, {DateTime? firstDate}) async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: firstDate ?? today,
      firstDate: firstDate ?? today,
      lastDate: DateTime(2101),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.voucher != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(isEdit),
                const SizedBox(height: 20),
                _buildSectionTitle("Thông tin mã"),
                _buildCard([
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _codeController,
                        label: "Mã giảm giá (Ví dụ: SALE10)",
                        icon: Icons.confirmation_number_outlined,
                        formatters: [
                          UpperCaseTextFormatter(),
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Bắt buộc nhập mã";
                          if (v.trim().length < 5) return "Mã tối thiểu 5 ký tự";
                          if (_duplicateCodeError != null) return _duplicateCodeError;
                          return null;
                        },
                      ),
                      if (_duplicateCodeError != null && _codeController.text.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _duplicateCodeError!,
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text("Loại giảm giá", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDiscountTypeOption("Phần trăm (%)", "percent"),
                      const SizedBox(width: 10),
                      _buildDiscountTypeOption("Cố định (đ)", "fixed"),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionTitle("Giá trị & Điều kiện"),
                _buildCard([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTextField(
                        controller: _valueController,
                        label: _selectedDiscountType == 'percent' ? "Giá trị (%)" : "Giá trị (đ)",
                        icon: Icons.money,
                        keyboard: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Bắt buộc";
                          double val = double.tryParse(v) ?? 0;
                          if (val <= 0) return "Phải > 0";
                          if (_selectedDiscountType == 'percent' && val > 100) return "Tối đa 100%";
                          if (_selectedDiscountType == 'fixed' && val > 10000000) return "Quá giới hạn";
                          return null;
                        }
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(
                        controller: _quantityController,
                        label: "Số lượng",
                        icon: Icons.inventory_2_outlined,
                        keyboard: TextInputType.number,
                        validator: (v) {
                          int? val = int.tryParse(v ?? '');
                          if (val == null || val <= 0) return "Bắt buộc (>0)";
                          if (val > 1000) return "Tối đa 1000";
                          return null;
                        }
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTextField(
                        controller: _minOrderController,
                        label: "Đơn tối thiểu",
                        icon: Icons.shopping_cart_checkout,
                        keyboard: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Bắt buộc";
                          if ((double.tryParse(v) ?? -1) < 0) return "Phải >= 0";
                          return null;
                        }
                      )),
                      if (_selectedDiscountType == 'percent') ...[
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(
                          controller: _maxDiscountController,
                          label: "Giảm tối đa",
                          icon: Icons.vertical_align_top,
                          keyboard: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Bắt buộc";
                            if ((double.tryParse(v) ?? -1) < 0) return "Phải >= 0";
                            return null;
                          }
                        )),
                      ]
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionTitle("Thời gian áp dụng"),
                _buildCard([
                  _buildTextField(
                    controller: _startDateController,
                    label: "Ngày bắt đầu",
                    icon: Icons.calendar_today,
                    readOnly: true,
                    onTap: () => _selectDate(_startDateController),
                    validator: (v) => (v == null || v.isEmpty) ? "Chọn ngày bắt đầu" : null
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _endDateController,
                    label: "Ngày kết thúc",
                    icon: Icons.event_available,
                    readOnly: true,
                    onTap: () {
                      if (_startDateController.text.isEmpty) return;
                      DateTime start = DateTime.parse(_startDateController.text);
                      _selectDate(_endDateController, firstDate: start.add(const Duration(days: 1)));
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Chọn ngày kết thúc";
                      DateTime start = DateTime.parse(_startDateController.text);
                      DateTime end = DateTime.parse(v);
                      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
                        return "Phải sau ngày bắt đầu";
                      }
                      return null;
                    }
                  ),
                ]),
                const SizedBox(height: 24),
                _buildDialogActions(isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountTypeOption(String label, String type) {
    bool isSelected = _selectedDiscountType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDiscountType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(bool isEdit) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: primaryGreen.withOpacity(0.1), child: Icon(isEdit ? Icons.edit : Icons.add, color: primaryGreen)),
        const SizedBox(width: 12),
        Text(isEdit ? "Sửa Voucher" : "Thêm Voucher", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]))
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) {
    List<TextInputFormatter> effectiveFormatters = formatters ?? [];
    if (keyboard == TextInputType.number) {
      effectiveFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')));
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      inputFormatters: effectiveFormatters,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        errorStyle: const TextStyle(fontSize: 10, height: 0.8),
        errorBorder: _duplicateCodeError != null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300, width: 1),
              )
            : null,
      ),
    );
  }

  Widget _buildDialogActions(bool isEdit) {
    final provider = context.read<AdminVoucherProvider>();
    
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(0, 48)), child: const Text("Hủy"))),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _duplicateCodeError != null
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    
                    final voucherData = Voucher(
                      voucherId: isEdit ? widget.voucher!.voucherId : '',
                      voucherCode: _codeController.text.trim(),
                      discountType: _selectedDiscountType,
                      discountValue: double.tryParse(_valueController.text) ?? 0,
                      minOrderValue: double.tryParse(_minOrderController.text) ?? 0,
                      maxDiscountValue: _selectedDiscountType == 'percent'
                          ? (double.tryParse(_maxDiscountController.text) ?? 0)
                          : 0,
                      quantity: int.tryParse(_quantityController.text) ?? 0,
                      usedQuantity: isEdit ? widget.voucher!.usedQuantity : 0,
                      startDate: DateTime.tryParse(_startDateController.text),
                      endDate: DateTime.tryParse(_endDateController.text),
                      status: isEdit ? widget.voucher!.status : 'active',
                      isValid: true,
                    );

                    try {
                      if (isEdit) {
                        await provider.updateVoucher(widget.voucher!.voucherId, voucherData);
                      } else {
                        await provider.createVoucher(voucherData);
                      }
                      if (mounted) {
                        widget.onSuccess?.call();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(isEdit ? "Cập nhật thành công" : "Tạo voucher thành công"),
                          backgroundColor: primaryGreen,
                          duration: const Duration(seconds: 2),
                        ));
                      }
                    } catch (e) {
                      if (mounted) {
                        if (e.toString().contains("Mã voucher đã tồn tại")) {
                          setState(() {
                            _duplicateCodeError = "Mã voucher đã tồn tại! Vui lòng chọn mã khác.";
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Mã voucher đã tồn tại, vui lòng nhập mã khác"),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Lỗi: $e"),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ));
                        }
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(0, 48),
              elevation: 0,
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: Text(isEdit ? "Lưu thay đổi" : "Xác nhận tạo", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}