import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../models/inventory.dart';
import '../utils/responsive.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedProductId;
  final _batchCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  
  final _manufactureDateController = TextEditingController();
  final _expiryDateController = TextEditingController();

  int _selectedFilterIndex = 0; 
  bool _isSubmitting = false;
  String? _duplicateBatchCodeError;
  String? _editingInventoryId;
  
  static const Color primaryGreen = Color(0xFF1A5F3A);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color bgGrey = Color(0xFFF4F7F5);
  static const Color warningOrange = Color(0xFFFF9F43);
  static const Color dangerRed = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _batchCodeController.addListener(_validateDuplicateBatchCode);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _batchCodeController.removeListener(_validateDuplicateBatchCode);
    _batchCodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _manufactureDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<InventoryProvider>();
    await provider.fetchInventories();
    await provider.fetchExpiringInventories();
    await provider.fetchExpiredInventories();
    await context.read<ProductProvider>().fetchAllProductsForDropdown();
  }

  void _validateDuplicateBatchCode() {
    final batchCode = _batchCodeController.text.trim();
    if (batchCode.isEmpty || batchCode.length < 3) {
      setState(() {
        _duplicateBatchCodeError = null;
      });
      return;
    }

    final provider = context.read<InventoryProvider>();
    final isExists = provider.isBatchCodeExists(batchCode, excludeId: _editingInventoryId);
    
    setState(() {
      if (isExists) {
        _duplicateBatchCodeError = "Mã lô hàng đã tồn tại! Vui lòng nhập mã khác.";
      } else {
        _duplicateBatchCodeError = null;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {DateTime? firstDate}) async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime minDate = DateTime(2000, 1, 1);
    
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: minDate,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    List<Inventory> displayList;
    if (_selectedFilterIndex == 1) {
      displayList = inventoryProvider.expiringInventories;
    } else if (_selectedFilterIndex == 2) {
      displayList = inventoryProvider.expiredInventories;
    } else {
      displayList = inventoryProvider.inventories;
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      displayList = displayList.where((i) => 
        i.batchCode.toLowerCase().contains(query) || 
        i.productName.toLowerCase().contains(query)
      ).toList();
    }

    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        children: [
          _buildToolBar(isMobile),
          _buildFilterTabs(),
          Expanded(
            child: inventoryProvider.isLoading && inventoryProvider.inventories.isEmpty
                ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                : displayList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: primaryGreen,
                        child: _buildGrid(displayList, isMobile, isTablet),
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
                hintText: 'Tìm mã lô, sản phẩm...',
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
            onPressed: () => _openImportDialog(null),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(isMobile ? 'Nhập' : 'Nhập hàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['Tất cả', 'Sắp hết hạn', 'Đã hết hạn'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: Container(
                margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
                        )
                      : null,
                  color: isSelected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid(List<Inventory> list, bool isMobile, bool isTablet) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
        mainAxisExtent: 210,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildInventoryCard(list[index]),
    );
  }

  Widget _buildInventoryCard(Inventory item) {
    final df = DateFormat('dd/MM/yyyy');
    
    Color statusColor;
    String statusText;
    if (item.isExpired) {
      statusColor = dangerRed;
      statusText = 'Hết hạn';
    } else if (item.daysToExpiry <= 7) {
      statusColor = warningOrange;
      statusText = 'Sắp hết hạn';
    } else {
      statusColor = primaryGreen;
      statusText = 'Còn hàng';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08), 
            blurRadius: 12, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openImportDialog(item),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, 
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primaryGreen.withOpacity(0.15), primaryGreen.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.inventory_2_rounded, color: primaryGreen, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.batchCode,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.productName,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(Icons.inbox, 'SL: ${item.quantity}', color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.money, 
                          '${NumberFormat('#,###').format(item.importPrice)}đ', 
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          Icons.event, 
                          'SX: ${item.manufactureDate != null ? df.format(item.manufactureDate!) : 'N/A'}',
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.event_busy, 
                          'HSD: ${df.format(item.expiryDate)}', 
                          color: item.isExpired ? dangerRed : (item.daysToExpiry <= 7 ? warningOrange : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.grey, height: 1, thickness: 0.5),
                  const SizedBox(height: 8),
                  // Fixed: Using Wrap to prevent overflow
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Sửa',
                        color: Colors.blue,
                        onTap: () => _openImportDialog(item),
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Xóa',
                        color: dangerRed,
                        onTap: () => _confirmDelete(item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label, 
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _openImportDialog(Inventory? item) {
    final isEdit = item != null;
    
    _editingInventoryId = isEdit ? item.inventoryId : null;
    
    if (isEdit) {
      _selectedProductId = item.productId;
      _batchCodeController.text = item.batchCode;
      _quantityController.text = item.quantity.toString();
      _priceController.text = item.importPrice?.toString() ?? '';
      _manufactureDateController.text = item.manufactureDate != null 
          ? DateFormat('yyyy-MM-dd').format(item.manufactureDate!) 
          : '';
      _expiryDateController.text = item.expiryDate != null 
          ? DateFormat('yyyy-MM-dd').format(item.expiryDate!) 
          : '';
    } else {
      _selectedProductId = null;
      _batchCodeController.clear();
      _quantityController.clear();
      _priceController.clear();
      _manufactureDateController.clear();
      _expiryDateController.clear();
    }
    
    _duplicateBatchCodeError = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 550,
          decoration: BoxDecoration(
            color: bgGrey,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(isEdit),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildSectionTitle("Thông tin lô hàng"),
                        _buildCard([
                          _buildProductDropdown(isEdit),
                          const SizedBox(height: 14),
                          _buildBatchCodeField(isEdit),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(_quantityController, 'Số lượng', Icons.numbers, isDigit: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(_priceController, 'Giá nhập', Icons.money, isDigit: true),
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng chọn ngày sản xuất';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildDateField(
                            controller: _expiryDateController,
                            label: 'Ngày hết hạn',
                            icon: Icons.event_busy,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng chọn ngày hết hạn';
                              }
                              final expiryDate = DateTime.tryParse(value);
                              if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
                                return 'Ngày hết hạn phải sau ngày hiện tại';
                              }
                              if (_manufactureDateController.text.isNotEmpty) {
                                final manufactureDate = DateTime.parse(_manufactureDateController.text);
                                if (expiryDate != null && (expiryDate.isBefore(manufactureDate) || expiryDate == manufactureDate)) {
                                  return 'Hạn dùng phải sau ngày sản xuất';
                                }
                              }
                              return null;
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              _buildDialogActions(isEdit, item?.inventoryId),
            ],
          ),
        ),
      ),
    ).then((_) {
      _editingInventoryId = null;
      _duplicateBatchCodeError = null;
    });
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, controller),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1),
        ),
        filled: true,
        fillColor: bgGrey.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
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
            prefixIcon: Icon(Icons.qr_code, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen, width: 1),
            ),
            errorBorder: _duplicateBatchCodeError != null 
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: errorRed, width: 1),
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
          style: const TextStyle(fontSize: 13),
        ),
        if (_duplicateBatchCodeError != null && _batchCodeController.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: errorRed),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _duplicateBatchCodeError!,
                    style: TextStyle(fontSize: 11, color: errorRed),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDialogHeader(bool isEdit) {
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
                colors: [primaryGreen.withOpacity(0.15), primaryGreen.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isEdit ? Icons.edit_rounded : Icons.add_business_rounded, color: primaryGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? "Cập nhật lô hàng" : "Nhập lô hàng mới",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              fontSize: 12,
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
      padding: const EdgeInsets.all(16),
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

  Widget _buildDialogActions(bool isEdit, String? id) {
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
              child: const Text("Hủy bỏ", style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting || _duplicateBatchCodeError != null 
                  ? null 
                  : () => _saveForm(isEdit, id),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isDigit = false, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon, size: 18), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1),
        ),
        filled: true,
        fillColor: bgGrey.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: isDigit ? TextInputType.number : TextInputType.text,
      inputFormatters: isDigit ? [FilteringTextInputFormatter.digitsOnly] : [],
      validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập $label' : null,
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildProductDropdown(bool isEdit) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.allProductsForDropdown.where((p) => p.isActive).toList();
    
    return DropdownButtonFormField<String>(
      value: _selectedProductId,
      isExpanded: true,
      hint: Text("Chọn sản phẩm", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      decoration: InputDecoration(
        labelText: "Sản phẩm",
        prefixIcon: const Icon(Icons.fastfood, size: 18),
        filled: true,
        fillColor: bgGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: products.map((product) {
        return DropdownMenuItem(
          value: product.productId,
          child: Text(product.productName, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: isEdit ? null : (value) => setState(() => _selectedProductId = value),
      validator: (v) => v == null ? "Vui lòng chọn sản phẩm" : null,
      dropdownColor: Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
    );
  }

  Future<void> _saveForm(bool isEdit, String? id) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_duplicateBatchCodeError != null && !isEdit) {
      _showToast('Mã lô hàng đã tồn tại, vui lòng nhập mã khác');
      return;
    }
    
    DateTime? manufactureDate;
    if (_manufactureDateController.text.isNotEmpty) {
      manufactureDate = DateTime.parse(_manufactureDateController.text);
    }
    
    DateTime? expiryDate;
    if (_expiryDateController.text.isNotEmpty) {
      expiryDate = DateTime.parse(_expiryDateController.text);
    }
    
    if (manufactureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày sản xuất'), backgroundColor: Colors.orange)
      );
      return;
    }
    
    if (expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày hết hạn'), backgroundColor: Colors.orange)
      );
      return;
    }
    
    if (expiryDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày hết hạn phải sau ngày hiện tại'), backgroundColor: Colors.orange)
      );
      return;
    }
    
    if (expiryDate.isBefore(manufactureDate) || expiryDate == manufactureDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày hết hạn phải sau ngày sản xuất'), backgroundColor: Colors.orange)
      );
      return;
    }
    
    if (_selectedProductId == null && !isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<InventoryProvider>();
    bool success;

    try {
      if (isEdit) {
        success = await provider.updateInventory(
          inventoryId: id!,
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
          Navigator.pop(context);
          _loadData();
          _showToast('Thao tác thành công');
        } else {
          _showToast(provider.error ?? 'Thao tác thất bại');
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (e.toString().contains('duplicate') || e.toString().contains('trùng') || e.toString().contains('exists')) {
        _showToast('Mã lô hàng đã tồn tại! Vui lòng nhập mã khác');
        _validateDuplicateBatchCode();
      } else {
        _showToast('Lỗi: $e');
      }
    }
  }

  Future<void> _confirmDelete(Inventory item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: warningOrange, size: 28),
            const SizedBox(width: 12),
            const Text('Xác nhận xóa lô hàng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa lô hàng',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              '“${item.batchCode} - ${item.productName}”',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: warningOrange.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: warningOrange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lưu ý: Xóa lô hàng sẽ ảnh hưởng đến số lượng tồn kho của sản phẩm.',
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
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('Hủy bỏ', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Xóa lô hàng', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<InventoryProvider>().deleteInventory(item.inventoryId);
      if (mounted) {
        if (success) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width: 12), Text('Đã xóa lô hàng thành công')]),
              backgroundColor: primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Không thể xóa lô hàng này'),
              backgroundColor: dangerRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inventory_2_outlined, size: 40, color: primaryGreen.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        Text(
          'Không tìm thấy lô hàng nào',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    ),
  );

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: msg.contains('thành công') ? primaryGreen : Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }
}