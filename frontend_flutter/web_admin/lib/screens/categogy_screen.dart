import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../utils/responsive.dart';
import '../utils/image_utils.dart';
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
  final _formKey = GlobalKey<FormState>();

  File? _selectedImageFile;
  Uint8List? _webImage;
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
    _descController.dispose();
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
          ElevatedButton.icon(
            onPressed: _openAddDialog,
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(isMobile ? 'Thêm' : 'Thêm danh mục'),
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
                  Text(category.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${category.productCount} sản phẩm', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _openEditDialog(category)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteCategory(category)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- MODERN DIALOG THEO PHONG CÁCH SUPPLIER ---
  void _showFormDialog({required bool isEdit, CategoryModel? category}) {
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
                          _buildSectionTitle("Hình ảnh danh mục"),
                          _buildImagePickerCard(setStateDialog, isEdit, category),
                          const SizedBox(height: 20),
                          _buildSectionTitle("Thông tin chi tiết"),
                          _buildInputCard([
                            _buildTextField(
                              controller: _nameController,
                              label: "Tên danh mục",
                              icon: Icons.category_outlined,
                              validator: (v) => v!.isEmpty ? "Vui lòng nhập tên danh mục" : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _descController,
                              label: "Mô tả danh mục",
                              icon: Icons.description_outlined,
                              maxLines: 3,
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDialogActions(isEdit, category?.categoryId, setStateDialog),
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
        CircleAvatar(
          backgroundColor: primaryGreen.withOpacity(0.1),
          child: Icon(isEdit ? Icons.edit : Icons.add_photo_alternate_outlined, color: primaryGreen),
        ),
        const SizedBox(width: 12),
        Text(isEdit ? "Cập nhật danh mục" : "Thêm danh mục mới", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  Widget _buildImagePickerCard(StateSetter setStateDialog, bool isEdit, CategoryModel? category) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Center(
        child: GestureDetector(
          onTap: () => _pickImage(setStateDialog),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: bgGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _webImage != null
                  ? Image.memory(_webImage!, fit: BoxFit.cover)
                  : _selectedImageFile != null
                      ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                      : (isEdit && category?.imageUrl != null)
                          ? ImageUtils.networkImage(category!.imageUrl)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.add_a_photo, color: primaryGreen, size: 30), SizedBox(height: 4), Text("Chọn ảnh", style: TextStyle(fontSize: 12, color: primaryGreen))],
                            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: bgGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDialogActions(bool isEdit, String? id, StateSetter setStateDialog) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Hủy bỏ"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _handleSave(isEdit, id, setStateDialog),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEdit ? "Cập nhật" : "Tạo danh mục", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // --- LOGIC XỬ LÝ ---
  Future<void> _handleSave(bool isEdit, String? id, StateSetter setStateDialog) async {
    if (!_formKey.currentState!.validate()) return;
    setStateDialog(() => _isSubmitting = true);

    final provider = context.read<CategoryProvider>();
    bool success;

    if (isEdit) {
      success = await provider.updateCategory(
        categoryId: id!,
        categoryName: _nameController.text,
        description: _descController.text,
        imageFile: _selectedImageFile,
        imageBytes: _webImage,
      );
    } else {
      success = await provider.createCategory(
        categoryName: _nameController.text,
        description: _descController.text,
        imageFile: _selectedImageFile,
        imageBytes: _webImage,
      );
    }

    setStateDialog(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context);
      _loadData();
    }
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

  Future<void> _deleteCategory(CategoryModel category) async {
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
      await context.read<CategoryProvider>().deleteCategory(category.categoryId);
      _loadData();
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