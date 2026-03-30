import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../utils/responsive.dart';
import '../utils/image_utils.dart'; // THÊM IMPORT NÀY
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  File? _selectedImageFile;
  Uint8List? _webImage;

  // Palette màu thương hiệu GreenFruit
  static const Color primaryGreen = Color(0xFF1A5F3A);
  static const Color bgGrey = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<CategoryProvider>().fetchCategories();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  List<CategoryModel> _getFilteredCategories(List<CategoryModel> categories) {
    if (_searchController.text.isEmpty) return categories;
    return categories
        .where((cat) => cat.categoryName
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? 180 : 350,
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm danh mục...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearSearch)
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _openAddDialog,
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(isMobile ? 'Thêm' : 'Thêm danh mục'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
      itemBuilder: (context, index) => _buildCategoryCard(categories[index]),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildCategoryAvatar(category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.productCount} sản phẩm',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                  onPressed: () => _openEditDialog(category),
                  tooltip: 'Sửa',
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _deleteCategory(category),
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAvatar(CategoryModel category) {
    // SỬA TẠI ĐÂY: Xử lý URL ảnh qua ImageUtils
    final imageUrl = ImageUtils.getOriginalImage(category.imageUrl);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          : const Icon(Icons.category_outlined, color: primaryGreen),
    );
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

  Future<void> _pickImage(StateSetter setStateDialog) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setStateDialog(() => _webImage = bytes);
      } else {
        setStateDialog(() => _selectedImageFile = File(pickedFile.path));
      }
    }
  }

  void _openAddDialog() {
    _nameController.clear();
    _descController.clear();
    _selectedImageFile = null;
    _webImage = null;
    _showFormDialog(isEdit: false);
  }

  void _openEditDialog(CategoryModel category) {
    _nameController.text = category.categoryName;
    _descController.text = category.description ?? '';
    _selectedImageFile = null;
    _webImage = null;
    _showFormDialog(isEdit: true, category: category);
  }

  void _showFormDialog({required bool isEdit, CategoryModel? category}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _pickImage(setStateDialog),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _webImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_webImage!, fit: BoxFit.cover))
                        : _selectedImageFile != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImageFile!, fit: BoxFit.cover))
                            : (isEdit && category?.imageUrl != null)
                                // SỬA TẠI ĐÂY: Hiển thị ảnh cũ trong Dialog cũng cần ImageUtils
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12), 
                                    child: Image.network(
                                      ImageUtils.getOriginalImage(category!.imageUrl!)!, 
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                    )
                                  )
                                : const Icon(Icons.add_a_photo, color: primaryGreen),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên danh mục')),
                TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Mô tả')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => isEdit ? _updateCategory(category!.categoryId) : _saveCategory(),
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: Text(isEdit ? 'Cập nhật' : 'Thêm', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.isEmpty) return;
    Navigator.pop(context);
    await context.read<CategoryProvider>().createCategory(
          categoryName: _nameController.text,
          description: _descController.text,
          imageFile: _selectedImageFile,
          imageBytes: _webImage,
        );
    _loadData();
  }

  Future<void> _updateCategory(String id) async {
    Navigator.pop(context);
    await context.read<CategoryProvider>().updateCategory(
          categoryId: id,
          categoryName: _nameController.text,
          description: _descController.text,
          imageFile: _selectedImageFile,
          imageBytes: _webImage,
        );
    _loadData();
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn muốn xóa danh mục "${category.categoryName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<CategoryProvider>().deleteCategory(category.categoryId);
      _loadData();
    }
  }
}