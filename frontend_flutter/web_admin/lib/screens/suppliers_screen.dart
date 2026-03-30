import 'package:flutter/material.dart';
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
  
  // Các controller cho Form
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  // Palette màu thương hiệu GreenFruit
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
        mainAxisExtent: 130,
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
            // Avatar cố định icon vì NCC không có ảnh
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.business, color: primaryGreen, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(supplier.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                  const SizedBox(height: 4),
                  _infoRow(Icons.phone, supplier.phone ?? 'N/A'),
                  _infoRow(Icons.location_on, supplier.address ?? 'N/A'),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _openSupplierDialog(supplier)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _confirmDelete(supplier)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]);
  }

  // --- MODERN DIALOG (ĐÃ BỎ CHỌN ẢNH) ---
  void _openSupplierDialog(SupplierModel? supplier) {
    final isEdit = supplier != null;
    if (isEdit) {
      _nameController.text = supplier.supplierName;
      _phoneController.text = supplier.phone ?? '';
      _addressController.text = supplier.address ?? '';
      _emailController.text = supplier.email ?? '';
    } else {
      _nameController.clear(); _phoneController.clear(); _addressController.clear(); _emailController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(28)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(isEdit),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Thông tin chính"),
                          _buildCard([
                            _buildTextField(controller: _nameController, label: "Tên nhà cung cấp", icon: Icons.business, validator: (v) => v!.isEmpty ? "Vui lòng nhập tên" : null),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _phoneController, label: "Số điện thoại", icon: Icons.phone, keyboard: TextInputType.phone),
                          ]),
                          const SizedBox(height: 20),
                          _buildSectionTitle("Thông tin liên hệ & Địa chỉ"),
                          _buildCard([
                            _buildTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _addressController, label: "Địa chỉ trụ sở", icon: Icons.location_on_outlined, maxLines: 2),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDialogActions(isEdit, supplier?.supplierId, setStateDialog),
              ],
            ),
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
        Text(isEdit ? "Cập nhật NCC" : "Thêm nhà cung cấp", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
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
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, TextInputType keyboard = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, maxLines: maxLines, keyboardType: keyboard, validator: validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 18),
        filled: true, fillColor: bgGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDialogActions(bool isEdit, String? id, StateSetter setStateDialog) {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Hủy bỏ"))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _isSubmitting ? null : () => _saveSupplier(isEdit, id, setStateDialog),
          style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEdit ? "Lưu thay đổi" : "Tạo nhà cung cấp", style: const TextStyle(fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }

  // --- LOGIC ---
  Future<void> _saveSupplier(bool isEdit, String? id, StateSetter setStateDialog) async {
    if (!_formKey.currentState!.validate()) return;
    setStateDialog(() => _isSubmitting = true);
    
    final provider = context.read<SupplierProvider>();
    bool success = isEdit 
      ? await provider.updateSupplier(supplierId: id!, supplierName: _nameController.text, address: _addressController.text, phone: _phoneController.text, email: _emailController.text, imageFile: null, imageBytes: null)
      : await provider.createSupplier(supplierName: _nameController.text, address: _addressController.text, phone: _phoneController.text, email: _emailController.text, imageFile: null, imageBytes: null);

    setStateDialog(() => _isSubmitting = false);
    if (success) { Navigator.pop(context); _loadData(); }
  }

  Future<void> _confirmDelete(SupplierModel supplier) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Xác nhận'), content: Text('Xóa nhà cung cấp "${supplier.supplierName}"?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red)))]));
    if (confirmed == true) { await context.read<SupplierProvider>().deleteSupplier(supplier.supplierId); _loadData(); }
  }

  List<SupplierModel> _getFilteredSuppliers(List<SupplierModel> suppliers) {
    if (_searchController.text.isEmpty) return suppliers;
    return suppliers.where((s) => s.supplierName.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
  }

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.business_center_outlined, size: 60, color: Colors.grey.shade300), const Text('Không tìm thấy NCC', style: TextStyle(color: Colors.grey))]));
}