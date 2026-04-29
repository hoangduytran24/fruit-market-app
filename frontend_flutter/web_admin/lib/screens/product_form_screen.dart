import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
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

  final _currencyFormatter = NumberFormat.decimalPattern('vi_VN');

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
      _priceController.text = _currencyFormatter.format(widget.product!.price);
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

  double _getCleanPrice() {
    String cleanString = _priceController.text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanString) ?? 0.0;
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

  // Hàm hiển thị Dialog cảnh báo
  void _showIncompleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Thông tin chưa đủ"),
          ],
        ),
        content: const Text("Bạn cần nhập đầy đủ thông tin kể cả ảnh thì mới thêm, sửa được."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Đã hiểu", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    // 1. Kiểm tra Validate Form (Text fields, Dropdowns)
    final isValid = _formKey.currentState!.validate();
    
    // 2. Kiểm tra Hình ảnh (Nếu là thêm mới thì bắt buộc, nếu sửa thì có thể dùng ảnh cũ)
    bool hasImage = false;
    if (kIsWeb) {
      hasImage = _webImage != null || (widget.product?.imageUrl != null);
    } else {
      hasImage = _selectedImageFile != null || (widget.product?.imageUrl != null);
    }

    if (!isValid || !hasImage) {
      _showIncompleteDialog();
      return;
    }

    setState(() => _isLoading = true);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    bool success;

    try {
      final priceValue = _getCleanPrice();
      final stockValue = int.parse(_stockController.text);

      if (widget.product == null) {
        success = await productProvider.createProduct(
          productName: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          supplierId: _selectedSupplierId!,
          unit: _unitController.text.trim(),
          price: priceValue,
          stockQuantity: stockValue,
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
          price: priceValue,
          stockQuantity: stockValue,
          description: _descriptionController.text.trim(),
          imageFile: _selectedImageFile,
          imageBytes: _webImage,
          isActive: _isActive,
        );
      }

      if (mounted) setState(() => _isLoading = false);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.product == null ? 'Thêm thành công!' : 'Cập nhật thành công!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 650,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: backgroundGrey, borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingData
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : SingleChildScrollView(
                    child: Form(
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
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return "Bắt buộc nhập tên";
                                if (!RegExp(r'^[\wÀ-ỹ0-9\s]{2,150}$', unicode: true).hasMatch(v)) {
                                  return "Từ 2-150 ký tự, không ký tự đặc biệt";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildRowFields([
                              _buildDropdownField(
                                label: "Danh mục",
                                icon: Icons.category_outlined,
                                value: _selectedCategoryId,
                                items: Provider.of<CategoryProvider>(context).categories.map((c) => 
                                  DropdownMenuItem(value: c.categoryId, child: Text(c.categoryName))).toList(),
                                onChanged: (val) => setState(() => _selectedCategoryId = val),
                                validator: (v) => v == null ? "Chọn danh mục" : null,
                              ),
                              _buildDropdownField(
                                label: "Nhà cung cấp",
                                icon: Icons.local_shipping_outlined,
                                value: _selectedSupplierId,
                                items: Provider.of<SupplierProvider>(context).suppliers.map((s) => 
                                  DropdownMenuItem(value: s.supplierId, child: Text(s.supplierName))).toList(),
                                onChanged: (val) => setState(() => _selectedSupplierId = val),
                                validator: (v) => v == null ? "Chọn nhà cung cấp" : null,
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
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "Nhập giá";
                                  final price = _getCleanPrice();
                                  if (price <= 0) return "Giá phải > 0";
                                  if (price > 1000000000) return "Giá quá lớn (> 1 tỷ)";
                                  return null;
                                },
                              ),
                              _buildTextField(
                                controller: _unitController,
                                label: "Đơn vị tính",
                                icon: Icons.scale_outlined,
                                hint: "1kg, gói 100g...",
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "Nhập đơn vị";
                                  if (!RegExp(r'^[\wÀ-ỹ0-9\s]{1,50}$', unicode: true).hasMatch(v)) {
                                    return "1-50 ký tự";
                                  }
                                  return null;
                                },
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _stockController,
                              label: "Số lượng tồn kho",
                              icon: Icons.inventory_2_outlined,
                              keyboard: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Nhập số lượng";
                                final stock = int.tryParse(v) ?? -1;
                                if (stock < 0) return "Tồn kho ≥ 0";
                                if (stock > 100000) return "Tồn kho ≤ 100.000";
                                return null;
                              },
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
                              validator: (v) => (v != null && v.length > 1000) ? "Tối đa 1000 ký tự" : null,
                            ),
                            if (widget.product != null) ...[
                              const Divider(height: 24),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Đang kinh doanh", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(backgroundColor: primaryGreen.withOpacity(0.1), child: Icon(widget.product == null ? Icons.add : Icons.edit, color: primaryGreen)),
        const SizedBox(width: 12),
        Text(widget.product == null ? "Thêm sản phẩm" : "Cập nhật", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: children),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, String? hint, int maxLines = 1, TextInputType keyboard = TextInputType.text, String? Function(String?)? validator, List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 18),
        filled: true, fillColor: backgroundGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon, required String? value, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged, String? Function(String?)? validator}) {
    return DropdownButtonFormField<String>(
      value: value, items: items, onChanged: onChanged, validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 18),
        filled: true, fillColor: backgroundGrey.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryGreen.withOpacity(0.2))),
          child: ClipRRect(borderRadius: BorderRadius.circular(20), child: _getImagePreview()),
        ),
      ),
    );
  }

  Widget _getImagePreview() {
    if (kIsWeb && _webImage != null) return Image.memory(_webImage!, fit: BoxFit.cover);
    if (!kIsWeb && _selectedImageFile != null) return Image.file(_selectedImageFile!, fit: BoxFit.cover);
    if (widget.product?.imageUrl != null) {
      return Image.network(ImageUtils.getOriginalImage(widget.product!.imageUrl)!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: primaryGreen));
    }
    return Icon(Icons.add_a_photo_outlined, color: primaryGreen.withOpacity(0.4));
  }

  Widget _buildRowFields(List<Widget> fields) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields.map((f) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: f))).toList(),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy bỏ"))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.product == null ? "Tạo sản phẩm" : "Lưu thay đổi"),
        )),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    double value = double.parse(newValue.text);
    final formatter = NumberFormat.decimalPattern('vi_VN');
    String newText = formatter.format(value);
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}