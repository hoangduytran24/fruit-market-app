import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../models/product.dart';
import '../../utils/image_utils.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  // Form Key
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  final _originController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Selection values
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  
  // Image handling
  File? _selectedImageFile;
  Uint8List? _webImage;
  bool _isImageChanged = false;
  
  // State flags
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  // UI Constants
  static const Color _primaryGreen = Color(0xFF1A5F3A);
  // static const Color _primaryLight = Color(0xFF2E7D4E);
  static const Color _backgroundGrey = Color(0xFFF4F7F5);
  static const Color _errorRed = Color(0xFFDC2626);
  static const Color _warningOrange = Color(0xFFF59E0B);
  
  // Formatters
  // final _currencyFormatter = NumberFormat.decimalPattern('vi_VN');
  final _priceFormatter = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _originController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);

    try {
      await Future.wait([
        categoryProvider.fetchCategories(),
        supplierProvider.fetchSuppliers(),
      ]);

      if (widget.product != null) {
        _populateFormWithProduct();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: _errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _populateFormWithProduct() {
    _nameController.text = widget.product!.productName;
    _unitController.text = widget.product!.unit;
    _priceController.text = _priceFormatter.format(widget.product!.price);
    _originController.text = widget.product!.origin ?? '';
    _descriptionController.text = widget.product!.description ?? '';
    _selectedCategoryId = widget.product!.categoryId;
    _selectedSupplierId = widget.product!.supplierId;
    _isActive = widget.product!.isActive;
  }

  double _getCleanPrice() {
    String cleanString = _priceController.text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanString) ?? 0.0;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _isImageChanged = true;
        if (kIsWeb) {
          pickedFile.readAsBytes().then((bytes) => _webImage = bytes);
        } else {
          _selectedImageFile = File(pickedFile.path);
        }
      });
    }
  }

  // Future<void> _removeImage() async {
  //   setState(() {
  //     _isImageChanged = true;
  //     _selectedImageFile = null;
  //     _webImage = null;
  //   });
  // }

  bool _hasValidImage() {
    if (widget.product == null) {
      // Thêm mới: bắt buộc có ảnh
      if (kIsWeb) return _webImage != null;
      return _selectedImageFile != null;
    } else {
      // Cập nhật: có thể giữ ảnh cũ hoặc chọn ảnh mới
      if (_isImageChanged) {
        if (kIsWeb) return _webImage != null;
        return _selectedImageFile != null;
      }
      return true; // Giữ ảnh cũ
    }
  }

  Future<void> _saveProduct() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate image
    if (!_hasValidImage()) {
      _showImageRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    bool success = false;

    try {
      final price = _getCleanPrice();

      if (widget.product == null) {
        // CREATE: theo backend CreateProductDto
        success = await productProvider.createProduct(
          productName: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          supplierId: _selectedSupplierId!,
          unit: _unitController.text.trim(),
          price: price,
          stockQuantity: 0, // Mặc định 0, backend sẽ xử lý
          origin: _originController.text.trim(),
          description: _descriptionController.text.trim(),
          imageFile: _selectedImageFile,
          imageBytes: _webImage,
        );
      } else {
        // UPDATE: theo backend UpdateProductDto
        success = await productProvider.updateProduct(
          productId: widget.product!.productId,
          productName: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          supplierId: _selectedSupplierId!,
          unit: _unitController.text.trim(),
          price: price,
          stockQuantity: 0, // Mặc định 0, backend sẽ xử lý
          origin: _originController.text.trim(),
          description: _descriptionController.text.trim(),
          imageFile: _isImageChanged ? _selectedImageFile : null,
          imageBytes: _isImageChanged ? _webImage : null,
          isActive: _isActive,
        );
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null ? 'Thêm sản phẩm thành công!' : 'Cập nhật sản phẩm thành công!'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.image_not_supported, color: _warningOrange),
            SizedBox(width: 8),
            Text("Chưa có ảnh sản phẩm"),
          ],
        ),
        content: const Text("Vui lòng chọn ảnh cho sản phẩm trước khi lưu."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đã hiểu", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: _backgroundGrey,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildImageSection(),
                            const SizedBox(height: 24),
                            _buildBasicInfoSection(),
                            const SizedBox(height: 20),
                            _buildPriceSection(),
                            const SizedBox(height: 20),
                            _buildOriginSection(),
                            const SizedBox(height: 20),
                            _buildDescriptionSection(),
                            if (widget.product != null) ...[
                              const SizedBox(height: 20),
                              _buildStatusSection(),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.product == null ? Icons.add_shopping_cart : Icons.edit_note,
              color: _primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product == null ? "Thêm sản phẩm mới" : "Chỉnh sửa sản phẩm",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (widget.product != null)
                Text(
                  'Mã: ${widget.product!.productId}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, size: 18, color: _primaryGreen),
              const SizedBox(width: 8),
              const Text(
                "Ảnh sản phẩm",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Text(
                " *",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _backgroundGrey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primaryGreen.withOpacity(0.2), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildImagePreview(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              widget.product == null ? "Nhấn để chọn ảnh" : "Nhấn để đổi ảnh",
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // Ảnh mới chọn (Web)
    if (kIsWeb && _webImage != null) {
      return Image.memory(_webImage!, fit: BoxFit.cover);
    }
    // Ảnh mới chọn (Mobile)
    if (!kIsWeb && _selectedImageFile != null) {
      return Image.file(_selectedImageFile!, fit: BoxFit.cover);
    }
    // Ảnh cũ từ server
    if (widget.product?.imageUrl != null && !_isImageChanged) {
      return Image.network(
        ImageUtils.getOriginalImage(widget.product!.imageUrl)!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 40, color: _primaryGreen.withOpacity(0.4)),
        const SizedBox(height: 4),
        Text(
          "Chưa có ảnh",
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Thông tin cơ bản", Icons.info_outline),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameController,
            label: "Tên sản phẩm",
            hint: "VD: Táo đỏ Hà Nội, Cam Vinh...",
            icon: Icons.shopping_basket_outlined,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Vui lòng nhập tên sản phẩm";
              if (v.length < 2) return "Tên phải có ít nhất 2 ký tự";
              if (v.length > 150) return "Tên không được quá 150 ký tự";
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: "Danh mục",
                  icon: Icons.category_outlined,
                  value: _selectedCategoryId,
                  items: Provider.of<CategoryProvider>(context).categories.map((c) => 
                    DropdownMenuItem(value: c.categoryId, child: Text(c.categoryName))).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (v) => v == null ? "Chọn danh mục" : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: "Nhà cung cấp",
                  icon: Icons.local_shipping_outlined,
                  value: _selectedSupplierId,
                  items: Provider.of<SupplierProvider>(context).suppliers.map((s) => 
                    DropdownMenuItem(value: s.supplierId, child: Text(s.supplierName))).toList(),
                  onChanged: (val) => setState(() => _selectedSupplierId = val),
                  validator: (v) => v == null ? "Chọn nhà cung cấp" : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ĐÃ SỬA: Bỏ trường Tồn kho, chỉ còn Giá bán và Đơn vị tính
  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Giá bán", Icons.payments_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _priceController,
                  label: "Giá bán (VNĐ)",
                  hint: "0",
                  icon: Icons.payments_outlined,
                  keyboard: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CurrencyInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Nhập giá bán";
                    final price = _getCleanPrice();
                    if (price <= 0) return "Giá phải lớn hơn 0";
                    if (price > 100000000) return "Giá không quá 100 triệu";
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _unitController,
                  label: "Đơn vị tính",
                  hint: "kg, gói, thùng...",
                  icon: Icons.scale_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Nhập đơn vị";
                    if (v.length > 20) return "Quá dài";
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ĐÃ SỬA: Xuất xứ bắt buộc và phải chi tiết (tối thiểu 3 ký tự)
  Widget _buildOriginSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public_outlined, size: 18, color: _primaryGreen),
              const SizedBox(width: 8),
              const Text(
                "Xuất xứ",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Text(
                " *",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _originController,
            label: "Xuất xứ",
            hint: "VD: Hà Nội, Việt Nam / Tokyo, Nhật Bản / California, USA...",
            icon: Icons.place_outlined,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return "Vui lòng nhập xuất xứ sản phẩm";
              }
              if (v.trim().length < 3) {
                return "Xuất xứ quá ngắn, vui lòng nhập chi tiết hơn (ít nhất 3 ký tự)";
              }
              if (v.length > 100) {
                return "Xuất xứ không được quá 100 ký tự";
              }
              // Kiểm tra xem có phải chỉ toàn số không
              if (RegExp(r'^[0-9\s]+$').hasMatch(v.trim())) {
                return "Vui lòng nhập tên địa danh cụ thể, không chỉ nhập số";
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: _warningOrange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Nên nhập chi tiết: 'Vùng miền, Quốc gia' để khách hàng dễ nhận biết",
                    style: TextStyle(fontSize: 11, color: _warningOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Mô tả sản phẩm", Icons.description_outlined),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descriptionController,
            label: "Mô tả chi tiết",
            hint: "Thông tin về sản phẩm, cách bảo quản, hướng dẫn sử dụng...",
            icon: Icons.article_outlined,
            maxLines: 4,
            validator: (v) {
              if (v != null && v.length > 1000) return "Mô tả không quá 1000 ký tự";
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.toggle_on_outlined, color: _isActive ? _primaryGreen : Colors.grey),
              const SizedBox(width: 8),
              const Text(
                "Trạng thái sản phẩm",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: _primaryGreen,
            activeTrackColor: _primaryGreen.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: _primaryGreen.withOpacity(0.7)),
        filled: true,
        fillColor: _backgroundGrey,
        border: _buildOutlineBorder(),
        enabledBorder: _buildOutlineBorder(),
        focusedBorder: _buildOutlineBorder(focused: true),
        errorBorder: _buildOutlineBorder(error: true),
        focusedErrorBorder: _buildOutlineBorder(error: true),
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
      ),
    );
  }

  OutlineInputBorder _buildOutlineBorder({bool focused = false, bool error = false}) {
    Color borderColor;
    if (error) {
      borderColor = _errorRed;
    } else if (focused) {
      borderColor = _primaryGreen;
    } else {
      borderColor = Colors.transparent;
    }
    
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: focused ? 1.5 : 1),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: _primaryGreen.withOpacity(0.7)),
        filled: true,
        fillColor: _backgroundGrey,
        border: _buildOutlineBorder(),
        enabledBorder: _buildOutlineBorder(),
        focusedBorder: _buildOutlineBorder(focused: true),
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: _primaryGreen.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Hủy bỏ"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      widget.product == null ? "Tạo sản phẩm" : "Lưu thay đổi",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom InputFormatter cho tiền tệ
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    final intValue = int.tryParse(newValue.text) ?? 0;
    final formatter = NumberFormat('#,###', 'vi_VN');
    final formattedText = formatter.format(intValue);
    
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}