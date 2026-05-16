import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/Order.dart';
import '../providers/return_provider.dart';

class ReturnRequestScreen extends StatefulWidget {
  final Order order;

  const ReturnRequestScreen({super.key, required this.order});

  @override
  State<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen> {
  final _descriptionController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  final List<String> _reasons = [
    'Hàng bị hỏng / lỗi',
    'Sai sản phẩm',
    'Không đúng mô tả',
    'Thiếu sản phẩm',
    'Hết hạn sử dụng',
    'Lý do khác',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0B2A1F)),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0B2A1F)),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReturnRequest() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn lý do trả hàng'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mô tả chi tiết'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
      
      final success = await returnProvider.createReturnRequest(
        orderId: widget.order.orderId,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        imageFile: _selectedImage, // Truyền file ảnh
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yêu cầu trả hàng đã được gửi!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(returnProvider.errorMessage ?? 'Gửi yêu cầu thất bại'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0B2A1F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Yêu cầu trả hàng',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin đơn hàng Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      spreadRadius: 0,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: primaryColor.withOpacity(0.8), size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Thông tin đơn hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 15,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                    _buildInfoRow('Mã đơn hàng', widget.order.orderId),
                    const SizedBox(height: 10),
                    _buildInfoRow('Ngày đặt', _formatDate(widget.order.createdAt)),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      'Tổng tiền thanh toán', 
                      _formatCurrency(widget.order.finalAmount),
                      isHighlight: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tiêu đề chọn lý do
              _buildSectionTitle('Lý do trả hàng *'),
              const SizedBox(height: 8),
              
              // Dropdown lý do trả hàng
              DropdownButtonFormField<String>(
                value: _selectedReason,
                hint: const Text('Chọn lý do phù hợp', style: TextStyle(color: Colors.grey, fontSize: 14)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                items: _reasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
              ),

              const SizedBox(height: 20),

              // Tiêu đề hình ảnh minh họa
              _buildSectionTitle('Hình ảnh minh họa (tùy chọn)'),
              const SizedBox(height: 8),
              
              // Khu vực chọn/ hiển thị ảnh
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImage = null),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chạm để thêm ảnh',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Hỗ trợ: jpg, png (tối đa 5MB)',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Tiêu đề nhập mô tả
              _buildSectionTitle('Mô tả chi tiết *'),
              const SizedBox(height: 8),
              
              // TextField mô tả chi tiết
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Vui lòng cung cấp thêm thông tin tình trạng sản phẩm để chúng tôi xử lý nhanh nhất...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  fillColor: Colors.white,
                  filled: true,
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Hộp Lưu ý
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1E4E7)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF1F6E7B), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lưu ý: Yêu cầu trả hàng chỉ được hệ thống ghi nhận và xử lý trong vòng 7 ngày kể từ thời điểm nhận hàng thành công.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1F6E7B), height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Nút gửi yêu cầu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReturnRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withOpacity(0.6),
                    elevation: 2,
                    shadowColor: primaryColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Gửi Yêu Cầu Trả Hàng',
                          style: TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600, 
        fontSize: 14,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: const TextStyle(color: Color(0xFF757575), fontSize: 13, fontWeight: FontWeight.w400),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: isHighlight ? 15 : 13,
              color: isHighlight ? const Color(0xFFD32F2F) : const Color(0xFF212121),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}