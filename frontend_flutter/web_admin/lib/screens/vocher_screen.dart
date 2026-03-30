import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../providers/voucher_provider.dart';
import '../utils/responsive.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Controllers cho Dialog
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedDiscountType = 'percent';

  static const Color primaryGreen = Color(0xFF27AE60); 
  static const Color bgGrey = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminVoucherProvider>().fetchVouchers();
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
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
        controller.text = picked.toIso8601String();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final voucherProvider = context.watch<AdminVoucherProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildToolBar(isMobile),
          Expanded(
            child: voucherProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                : voucherProvider.vouchers.isEmpty
                    ? const Center(child: Text("Chưa có voucher nào"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 130,
                        ),
                        itemCount: voucherProvider.vouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = voucherProvider.vouchers[index];
                          return _buildVoucherTicket(voucher);
                        },
                      ),
          ),
        ],
      ),
    );
  }

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
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm mã giảm giá...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openVoucherDialog(null),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(isMobile ? 'Tạo' : 'Thêm Voucher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherTicket(Voucher v) {
    bool isInactive = v.status != 'active';
    bool isOutOfStock = (v.quantity - v.usedQuantity) <= 0;
    
    Color themeColor = isInactive 
        ? Colors.grey.shade400 
        : (v.discountType == 'percent' ? const Color(0xFFFF9F43) : const Color(0xFF10AC84));

    String discountLabel = v.discountType == 'percent' ? '${v.discountValue.toInt()}%' : '${(v.discountValue / 1000).toInt()}k';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.15), 
            blurRadius: 12, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [themeColor, themeColor.withOpacity(0.85)],
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(discountLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                Text(v.discountType == 'percent' ? "GIẢM GIÁ" : "TIỀN MẶT", 
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
          CustomPaint(size: const Size(1, double.infinity), painter: DashLinePainter(color: Colors.grey.shade300)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(v.voucherCode, style: TextStyle(fontWeight: FontWeight.w900, color: themeColor, fontSize: 14)),
                      if (isInactive)
                        _buildStatusBadge("Đã tắt", Colors.grey)
                      else if (isOutOfStock)
                        _buildStatusBadge("Hết mã", Colors.red)
                      else if ((v.quantity - v.usedQuantity) <= 5)
                        _buildStatusBadge("Sắp hết", Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Đơn tối thiểu ${v.minOrderValue.toInt()}đ", style: TextStyle(fontSize: 11, color: Colors.blueGrey[700])),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: v.quantity > 0 ? v.usedQuantity / v.quantity : 0,
                      minHeight: 4,
                      backgroundColor: themeColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Đã dùng: ${v.usedQuantity}/${v.quantity}", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                      Text("HSD: ${v.endDate?.day}/${v.endDate?.month}", style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildActionMenu(v),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionMenu(Voucher v) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, size: 22, color: Colors.blueGrey),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      itemBuilder: (context) => [
        _buildPopupItem(1, Icons.edit_outlined, "Sửa", Colors.blue),
        _buildPopupItem(2, Icons.power_settings_new, "Bật/Tắt", Colors.orange),
        _buildPopupItem(3, Icons.delete_outline, "Xóa", Colors.red),
      ],
      onSelected: (value) {
        if (value == 1) _openVoucherDialog(v);
        if (value == 2) context.read<AdminVoucherProvider>().toggleVoucherStatus(v.voucherId);
        if (value == 3) _confirmDelete(v);
      },
    );
  }

  PopupMenuItem<int> _buildPopupItem(int value, IconData icon, String title, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _openVoucherDialog(Voucher? voucher) {
    final isEdit = voucher != null;
    if (isEdit) {
      _codeController.text = voucher.voucherCode;
      _valueController.text = voucher.discountValue.toString();
      _minOrderController.text = voucher.minOrderValue.toString();
      _maxDiscountController.text = voucher.maxDiscountValue.toString();
      _quantityController.text = voucher.quantity.toString();
      _startDateController.text = voucher.startDate?.toIso8601String() ?? '';
      _endDateController.text = voucher.endDate?.toIso8601String() ?? '';
      _selectedDiscountType = voucher.discountType;
    } else {
      _codeController.clear(); _valueController.clear(); _minOrderController.clear();
      _maxDiscountController.clear(); _quantityController.clear();
      _startDateController.clear(); _endDateController.clear();
      _selectedDiscountType = 'percent';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                    _buildSectionTitle("Thông tin cơ bản"),
                    _buildCard([
                      _buildTextField(controller: _codeController, label: "Mã giảm giá", icon: Icons.confirmation_number_outlined),
                      const SizedBox(height: 16),
                      const Text("Loại giảm giá", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDiscountTypeOption(setDialogState, "Phần trăm (%)", "percent"),
                          const SizedBox(width: 10),
                          _buildDiscountTypeOption(setDialogState, "Cố định (đ)", "fixed"),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionTitle("Giá trị & Số lượng"),
                    _buildCard([
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: _valueController, label: "Giá trị giảm", icon: Icons.money, keyboard: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _quantityController, label: "Số lượng", icon: Icons.format_list_numbered, keyboard: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: _minOrderController, label: "Đơn tối thiểu", icon: Icons.shopping_bag_outlined, keyboard: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _maxDiscountController, label: "Giảm tối đa", icon: Icons.vertical_align_top, keyboard: TextInputType.number)),
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
                        onTap: () => _selectDate(context, _startDateController),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _endDateController,
                        label: "Ngày kết thúc",
                        icon: Icons.event_available,
                        readOnly: true,
                        onTap: () => _selectDate(context, _endDateController),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildDialogActions(isEdit, voucher),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountTypeOption(Function setDialogState, String label, String type) {
    bool isSelected = _selectedDiscountType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setDialogState(() => _selectedDiscountType = type),
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
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]))));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboard = TextInputType.text, bool readOnly = false, VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDialogActions(bool isEdit, Voucher? originalVoucher) {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy"))),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final provider = context.read<AdminVoucherProvider>();
              
              final voucherData = Voucher(
                voucherId: isEdit ? originalVoucher!.voucherId : '',
                voucherCode: _codeController.text,
                discountType: _selectedDiscountType,
                discountValue: double.tryParse(_valueController.text) ?? 0,
                minOrderValue: double.tryParse(_minOrderController.text) ?? 0,
                maxDiscountValue: double.tryParse(_maxDiscountController.text) ?? 0,
                quantity: int.tryParse(_quantityController.text) ?? 0,
                usedQuantity: isEdit ? originalVoucher!.usedQuantity : 0,
                startDate: DateTime.tryParse(_startDateController.text),
                endDate: DateTime.tryParse(_endDateController.text),
                status: isEdit ? originalVoucher!.status : 'active',
                isValid: true,
              );

              try {
                if (isEdit) {
                  // Đã thêm logic sửa ở đây
                  await provider.updateVoucher(originalVoucher!.voucherId, voucherData);
                } else {
                  await provider.createVoucher(voucherData);
                }
                if (mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
            child: Text(isEdit ? "Lưu" : "Xác nhận"),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(Voucher v) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa mã "${v.voucherCode}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () async {
            await context.read<AdminVoucherProvider>().deleteVoucher(v.voucherId);
            if (mounted) Navigator.pop(context);
          }, child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class DashLinePainter extends CustomPainter {
  final Color color;
  DashLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()..color = color..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}