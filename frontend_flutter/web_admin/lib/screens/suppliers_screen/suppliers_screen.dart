import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_provider.dart';
import '../../models/supplier.dart';
import '../../utils/responsive.dart';
import 'supplier_form_dialog.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();

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

  void _openSupplierDialog(SupplierModel? supplier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SupplierFormDialog(
        supplier: supplier,
        onSuccess: () => _loadData(),
      ),
    );
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