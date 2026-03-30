import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/product.dart';
import '../utils/image_utils.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSupplierId;
  
  File? _selectedImageFile;
  Uint8List? _webImage;
  
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingData = true;

  final Color primaryGreen = const Color(0xFF1A5F3A);
  final Color backgroundGrey = const Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);

    await Future.wait([
      categoryProvider.fetchCategories(),
      supplierProvider.fetchSuppliers(),
    ]);

    if (widget.product != null) {
      _nameController.text = widget.product!.productName;
      _unitController.text = widget.product!.unit;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stockQuantity.toString();
      _descriptionController.text = widget.product!.description ?? '';
      _selectedCategoryId = widget.product!.categoryId;
      _selectedSupplierId = widget.product!.supplierId;
      _isActive = widget.product!.isActive;
    }

    if (mounted) setState(() => _isLoadingData = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      } else {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    bool success;

    try {
      print('=== SAVING PRODUCT ===');
      print('Has webImage: ${_webImage != null}');
      print('Has selectedImageFile: ${_selectedImageFile != null}');
      
      if (widget.product == null) {
        success = await productProvider.createProduct(
          productName: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          supplierId: _selectedSupplierId!,
          unit: _unitController.text.trim(),
          price: double.parse(_priceController.text),
          stockQuantity: int.parse(_stockController.text),
          description: _descriptionController.text.trim(),
          imageFile: _selectedImageFile,
          imageBytes: _webImage,
        );
      } else {
        success = await productProvider.updateProduct(
          productId: widget.product!.productId,
          productName: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          supplierId: _selectedSupplierId!,
          unit: _unitController.text.trim(),
          price: double.parse(_priceController.text),
          stockQuantity: int.parse(_stockController.text),
          description: _descriptionController.text.trim(),
          imageFile: _selectedImageFile,
          imageBytes: _webImage,
          isActive: _isActive,
        );
      }
      
      if (mounted) setState(() => _isLoading = false);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null ? 'Thêm sản phẩm thành công!' : 'Cập nhật thành công!'), 
            backgroundColor: Colors.green, 
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          )
        );
        Navigator.pop(context, true);
      } else if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.error ?? 'Có lỗi xảy ra, vui lòng thử lại'), 
            backgroundColor: Colors.red, 
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Lỗi khi lưu sản phẩm: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'), 
          backgroundColor: Colors.red, 
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundGrey,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _isLoadingData
                  ? Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: primaryGreen)))
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImagePicker(),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Thông tin cơ bản"),
                          _buildCard([
                            _buildTextField(
                              controller: _nameController,
                              label: "Tên sản phẩm",
                              icon: Icons.shopping_basket_outlined,
                              validator: (v) => v!.isEmpty ? "Nhập tên sản phẩm" : null,
                            ),
                            const SizedBox(height: 16),
                            _buildRowFields([
                              _buildDropdownField(
                                label: "Danh mục",
                                icon: Icons.category_outlined,
                                value: _selectedCategoryId,
                                items: Provider.of<CategoryProvider>(context).categories.map((c) => 
                                  DropdownMenuItem(value: c.categoryId, child: Text(c.categoryName, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) => setState(() => _selectedCategoryId = val),
                              ),
                              _buildDropdownField(
                                label: "Nhà cung cấp",
                                icon: Icons.local_shipping_outlined,
                                value: _selectedSupplierId,
                                items: Provider.of<SupplierProvider>(context).suppliers.map((s) => 
                                  DropdownMenuItem(value: s.supplierId, child: Text(s.supplierName, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) => setState(() => _selectedSupplierId = val),
                              ),
                            ]),
                          ]),
                          const SizedBox(height: 20),
                          _buildSectionTitle("Giá & Tồn kho"),
                          _buildCard([
                            _buildRowFields([
                              _buildTextField(
                                controller: _priceController,
                                label: "Giá bán (₫)",
                                icon: Icons.payments_outlined,
                                keyboard: TextInputType.number,
                              ),
                              _buildTextField(
                                controller: _unitController,
                                label: "Đơn vị tính",
                                icon: Icons.scale_outlined,
                                hint: "Kg, Túi...",
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _stockController,
                              label: "Số lượng tồn kho",
                              icon: Icons.inventory_2_outlined,
                              keyboard: TextInputType.number,
                            ),
                          ]),
                          const SizedBox(height: 20),
                          _buildSectionTitle("Mô tả"),
                          _buildCard([
                            _buildTextField(
                              controller: _descriptionController,
                              label: "Mô tả sản phẩm",
                              icon: Icons.description_outlined,
                              maxLines: 3,
                            ),
                            if (widget.product != null) ...[
                              const Divider(height: 24),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Đang kinh doanh", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                activeColor: primaryGreen,
                                value: _isActive,
                                onChanged: (v) => setState(() => _isActive = v),
                              ),
                            ]
                          ]),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildRowFields(List<Widget> fields) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields.map((f) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: f))).toList(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(backgroundColor: primaryGreen.withOpacity(0.1), child: Icon(widget.product == null ? Icons.add : Icons.edit, color: primaryGreen)),
        const SizedBox(width: 12),
        Text(widget.product == null ? "Thêm sản phẩm mới" : "Cập nhật sản phẩm", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
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

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, String? hint, int maxLines = 1, TextInputType keyboard = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 16),
        filled: true, fillColor: backgroundGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon, required String? value, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: value, items: items, onChanged: onChanged, isExpanded: true,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 16),
        filled: true, fillColor: backgroundGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      validator: (v) => v == null ? "Bắt buộc" : null,
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.1), blurRadius: 10)]),
          child: ClipRRect(borderRadius: BorderRadius.circular(20), child: _getImagePreview()),
        ),
      ),
    );
  }

  Widget _getImagePreview() {
    if (kIsWeb && _webImage != null) return Image.memory(_webImage!, fit: BoxFit.cover);
    if (!kIsWeb && _selectedImageFile != null) return Image.file(_selectedImageFile!, fit: BoxFit.cover);
    if (widget.product?.imageUrl != null) {
      return Image.network(ImageUtils.getOriginalImage(widget.product!.imageUrl)!, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: primaryGreen));
    }
    return Icon(Icons.add_a_photo_outlined, color: primaryGreen.withOpacity(0.4));
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Hủy bỏ"))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.product == null ? "Tạo sản phẩm" : "Lưu thay đổi", style: const TextStyle(fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }
}