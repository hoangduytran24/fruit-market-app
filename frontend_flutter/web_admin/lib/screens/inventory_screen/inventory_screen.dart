import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/inventory.dart';
import '../../utils/responsive.dart';
import 'inventory_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;

  static const Color primaryGreen = Color(0xFF1A5F3A);
  static const Color warningOrange = Color(0xFFFF9F43);
  static const Color dangerRed = Color(0xFFE74C3C);
  static const Color bgGrey = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<InventoryProvider>();
    await provider.fetchInventories();
    await provider.fetchExpiringInventories();
    await provider.fetchExpiredInventories();
    await context.read<ProductProvider>().fetchAllProductsForDropdown();
  }

  List<Inventory> _getFilteredList(InventoryProvider provider) {
    List<Inventory> list;
    if (_selectedFilterIndex == 1) {
      list = provider.expiringInventories;
    } else if (_selectedFilterIndex == 2) {
      list = provider.expiredInventories;
    } else {
      list = provider.inventories;
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      list = list.where((i) => 
        i.batchCode.toLowerCase().contains(query) || 
        i.productName.toLowerCase().contains(query)
      ).toList();
    }
    return list;
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  void _openInventoryForm([Inventory? inventory]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 550,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: InventoryFormScreen(
            inventory: inventory,
            onSuccess: _refresh,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteInventory(Inventory item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(item),
    );

    if (confirmed == true) {
      final success = await context.read<InventoryProvider>().deleteInventory(item.inventoryId);
      if (mounted) {
        if (success) {
          _refresh();
          _showSnackBar('Đã xóa lô hàng thành công', isSuccess: true);
        } else {
          _showSnackBar('Không thể xóa lô hàng này', isSuccess: false);
        }
      }
    }
  }

  Widget _buildDeleteConfirmDialog(Inventory item) {
    return AlertDialog(
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
    );
  }

  void _showSnackBar(String msg, {bool isSuccess = true}) {
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

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final displayList = _getFilteredList(inventoryProvider);

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
                        onRefresh: _refresh,
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
            onPressed: () => _openInventoryForm(),
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
    const tabs = ['Tất cả', 'Sắp hết hạn', 'Đã hết hạn'];
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
    
    (Color color, String text) getStatus() {
      if (item.isExpired) {
        return (dangerRed, 'Hết hạn');
      } else if (item.daysToExpiry <= 7) {
        return (warningOrange, 'Sắp hết hạn');
      } else {
        return (primaryGreen, 'Còn hàng');
      }
    }

    final status = getStatus();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: status.$1.withOpacity(0.08), 
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
            onTap: () => _openInventoryForm(item),
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
                          color: status.$1.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.$2,
                          style: TextStyle(color: status.$1, fontSize: 10, fontWeight: FontWeight.w600),
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
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Sửa',
                        color: Colors.blue,
                        onTap: () => _openInventoryForm(item),
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Xóa',
                        color: dangerRed,
                        onTap: () => _deleteInventory(item),
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
}