import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../utils/image_utils.dart';

class CategoryFormDialog extends StatefulWidget {
  final bool isEdit;
  final CategoryModel? category;

  const CategoryFormDialog({
    super.key,
    required this.isEdit,
    this.category,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  File? _selectedImageFile;
  Uint8List? _webImage;
  bool _isSubmitting = false;

  static const Color primaryGreen = Color(0xFF1A5F3A);
  static const Color bgGrey = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.category != null) {
      _nameController.text = widget.category!.categoryName;
      _descController.text = widget.category!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool _isCategoryNameDuplicate(String categoryName, [String? excludeCategoryId]) {
    final categories = context.read<CategoryProvider>().categories;
    return categories.any((cat) =>
        cat.categoryName.toLowerCase() == categoryName.toLowerCase() &&
        cat.categoryId != excludeCategoryId);
  }

  void _showDuplicateNameWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Tên danh mục đã tồn tại"),
          ],
        ),
        content: const Text("Vui lòng chọn tên danh mục khác để tránh trùng lặp."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Đã hiểu", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    final provider = context.read<CategoryProvider>();
    bool success;

    if (widget.isEdit) {
      success = await provider.updateCategory(
        categoryId: widget.category!.categoryId,
        categoryName: _nameController.text.trim(),
        description: _descController.text.trim(),
        imageFile: _selectedImageFile,
        imageBytes: _webImage,
      );
    } else {
      success = await provider.createCategory(
        categoryName: _nameController.text.trim(),
        description: _descController.text.trim(),
        imageFile: _selectedImageFile,
        imageBytes: _webImage,
      );
    }

    setState(() => _isSubmitting = false);
    
    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      _showDuplicateNameWarning();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _selectedImageFile = File(pickedFile.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    double dialogWidth = isMobile ? MediaQuery.of(context).size.width * 0.9 : 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Hình ảnh danh mục"),
                      _buildImagePickerCard(),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Thông tin chi tiết"),
                      _buildInputCard([
                        _buildTextField(
                          controller: _nameController,
                          label: "Tên danh mục",
                          icon: Icons.category_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "Vui lòng nhập tên danh mục";
                            }
                            final isDuplicate = _isCategoryNameDuplicate(
                              v.trim(),
                              widget.isEdit ? widget.category?.categoryId : null
                            );
                            if (isDuplicate) {
                              return "Tên danh mục đã tồn tại";
                            }
                            return null;
                          },
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
            _buildDialogActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: primaryGreen.withOpacity(0.1),
          child: Icon(widget.isEdit ? Icons.edit : Icons.add_photo_alternate_outlined, color: primaryGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.isEdit ? "Cập nhật danh mục" : "Thêm danh mục mới",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(children: children),
    );
  }

  Widget _buildImagePickerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Center(
        child: GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 100,
            height: 100,
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
                      : (widget.isEdit && widget.category?.imageUrl != null)
                          ? ImageUtils.networkImage(widget.category!.imageUrl)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: primaryGreen, size: 24),
                                SizedBox(height: 4),
                                Text("Chọn ảnh", style: TextStyle(fontSize: 10, color: primaryGreen))
                              ],
                            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
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

  Widget _buildDialogActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("Hủy bỏ", style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.isEdit ? "Cập nhật" : "Tạo danh mục", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}