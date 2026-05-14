import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../utils/responsive.dart';
import '../../utils/image_utils.dart';
import 'category_form_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
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
    await context.read<CategoryProvider>().fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final isMobile = context.isMobile;
    final filteredList = _getFilteredCategories(categoryProvider.categories);

    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        children: [
          _buildToolBar(isMobile),
          Expanded(
            child: categoryProvider.isLoading && categoryProvider.categories.isEmpty
                ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: primaryGreen,
                        child: _buildCategoryGrid(filteredList, isMobile),
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
        children: [
          Expanded(
            child: Container(
              height: 42,
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm danh mục...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          })
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _openAddDialog(),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(isMobile ? 'Thêm' : 'Thêm danh mục'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<CategoryModel> categories, bool isMobile) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (context.isTablet ? 2 : 4),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 110,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) => _buildCategoryCard(categories[index], isMobile),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, bool isMobile) {
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
            ImageUtils.networkImage(
              category.imageUrl,
              width: 65,
              height: 65,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.productCount} sản phẩm',
                    style: TextStyle(
                      color: category.productCount > 0 ? Colors.orange.shade700 : Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: category.productCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: isMobile ? 40 : 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                      onPressed: () => _openEditDialog(category),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      onPressed: () => _deleteCategory(category),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showCannotDeleteWarning(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Không thể xóa danh mục"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh mục "${category.categoryName}" đang có ${category.productCount} sản phẩm.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng chuyển hoặc xóa các sản phẩm thuộc danh mục này trước khi xóa danh mục.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Đã hiểu", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CategoryFormDialog(isEdit: false),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _openEditDialog(CategoryModel category) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(
        isEdit: true,
        category: category,
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    if (category.productCount > 0) {
      _showCannotDeleteWarning(category);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa danh mục "${category.categoryName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await context.read<CategoryProvider>().deleteCategory(category.categoryId);
      if (success) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa danh mục thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa danh mục này'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<CategoryModel> _getFilteredCategories(List<CategoryModel> categories) {
    if (_searchController.text.isEmpty) return categories;
    return categories.where((cat) => cat.categoryName.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text('Không tìm thấy danh mục nào', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}