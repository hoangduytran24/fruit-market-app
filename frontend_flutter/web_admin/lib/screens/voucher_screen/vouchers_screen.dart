import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/voucher.dart';
import '../../providers/voucher_provider.dart';
import '../../utils/responsive.dart';
import 'voucher_form_dialog.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryGreen = Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminVoucherProvider>().fetchVouchers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    String discountLabel = v.discountType == 'percent' 
        ? '${v.discountValue.toInt()}%' 
        : '${(v.discountValue / 1000).toInt()}k';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoucherFormDialog(
        voucher: voucher,
        onSuccess: () {
          context.read<AdminVoucherProvider>().fetchVouchers();
        },
      ),
    );
  }

  void _confirmDelete(Voucher v) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa mã "${v.voucherCode}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () async {
            await context.read<AdminVoucherProvider>().deleteVoucher(v.voucherId);
            if (mounted) Navigator.pop(context);
          }, child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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