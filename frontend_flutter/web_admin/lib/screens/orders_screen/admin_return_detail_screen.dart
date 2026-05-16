import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/return_provider.dart';
import '../../models/ReturnRequest.dart';
import '../../utils/responsive.dart';
import '../../utils/image_utils.dart';

class AdminReturnDetailScreen extends StatefulWidget {
  final String returnId;

  const AdminReturnDetailScreen({super.key, required this.returnId});

  @override
  State<AdminReturnDetailScreen> createState() => _AdminReturnDetailScreenState();
}

class _AdminReturnDetailScreenState extends State<AdminReturnDetailScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  ReturnRequest? _returnRequest;

  final Color primaryGreen = const Color(0xFF1A5F3A);

  @override
  void initState() {
    super.initState();
    _loadReturnDetail();
  }

  Future<void> _loadReturnDetail() async {
    setState(() => _isLoading = true);
    final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
    final detail = await returnProvider.fetchReturnDetail(widget.returnId);
    setState(() {
      _returnRequest = detail;
      _isLoading = false;
    });
  }

  Future<void> _processReturn(bool isApproved) async {
    setState(() => _isProcessing = true);

    final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
    final success = await returnProvider.processReturnRequest(
      returnId: widget.returnId,
      isApproved: isApproved,
    );

    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApproved ? 'Đã chấp nhận trả hàng' : 'Đã từ chối trả hàng'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadReturnDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xử lý thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmCompleteReturn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nhận lại hàng'),
        content: const Text('Bạn đã nhận lại hàng từ khách hàng chưa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chưa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Đã nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
    final success = await returnProvider.completeReturnRequest(widget.returnId);
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận nhận lại hàng và hoàn tiền'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác nhận thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0₫';
    try {
      final formatter = NumberFormat('#,###', 'vi_VN');
      return '${formatter.format(amount.round())}₫';
    } catch (e) {
      return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Chờ xử lý';
      case 'approved': return 'Đã duyệt - Chờ nhận hàng';
      case 'rejected': return 'Từ chối';
      case 'completed': return 'Hoàn tất';
      default: return status;
    }
  }

  void _showFullImage(String imageUrl) {
    final fullImageUrl = ImageUtils.getOriginalImage(imageUrl) ?? imageUrl;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.9),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: fullImageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image, size: 64, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          'Không thể tải ảnh',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final dialogWidth = isMobile ? context.screenWidth * 0.92 : 550.0;
    final innerPadding = isMobile ? 16.0 : 20.0;
    final fontSizeTitle = isMobile ? 16.0 : 18.0;
    final fontSizeLabel = isMobile ? 12.0 : 13.0;
    final fontSizeValue = isMobile ? 13.0 : 15.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: context.screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            : _returnRequest == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('Không tìm thấy thông tin'),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(innerPadding),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "CHI TIẾT YÊU CẦU TRẢ HÀNG",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSizeTitle,
                                    ),
                                  ),
                                  Text(
                                    "Mã yêu cầu: #${_returnRequest!.returnId}",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: fontSizeLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(innerPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Trạng thái
                              _buildStatusSection(fontSizeLabel, fontSizeValue),
                              const SizedBox(height: 16),

                              // Thông tin đơn hàng
                              _buildOrderInfoSection(fontSizeLabel, fontSizeValue),
                              const SizedBox(height: 16),

                              // Lý do trả hàng
                              _buildReasonSection(fontSizeLabel, fontSizeValue),
                              const SizedBox(height: 16),

                              // Ảnh minh chứng
                              if (_returnRequest!.imageUrl != null && _returnRequest!.imageUrl!.isNotEmpty)
                                _buildImageSection(),
                              const SizedBox(height: 24),

                              // Action Buttons
                              _buildActionButtons(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatusSection(double fontSizeLabel, double fontSizeValue) {
    final statusColor = _getStatusColor(_returnRequest!.status);
    final statusText = _getStatusText(_returnRequest!.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _returnRequest!.status == 'pending' ? Icons.hourglass_empty :
              _returnRequest!.status == 'approved' ? Icons.check_circle_outline :
              _returnRequest!.status == 'rejected' ? Icons.cancel :
              Icons.check_circle,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: fontSizeValue,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày tạo: ${_formatDate(_returnRequest!.createdAt)}',
                  style: TextStyle(
                    fontSize: fontSizeLabel - 1,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoSection(double fontSizeLabel, double fontSizeValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag, size: 20, color: Color(0xFF1A5F3A)),
              SizedBox(width: 8),
              Text(
                'Thông tin đơn hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Mã đơn hàng:', _returnRequest!.orderId, fontSizeLabel, fontSizeValue),
          _buildInfoRow('Số tiền hoàn lại:', _formatCurrency(_returnRequest!.refundAmount), fontSizeLabel, fontSizeValue),
          _buildInfoRow('Khách hàng:', _returnRequest!.userId, fontSizeLabel, fontSizeValue),
        ],
      ),
    );
  }

  Widget _buildReasonSection(double fontSizeLabel, double fontSizeValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Lý do trả hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _returnRequest!.reason,
              style: TextStyle(fontSize: fontSizeValue, fontWeight: FontWeight.w500),
            ),
          ),
          if (_returnRequest!.description != null && _returnRequest!.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Mô tả chi tiết:',
              style: TextStyle(fontSize: fontSizeLabel, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              _returnRequest!.description!,
              style: TextStyle(fontSize: fontSizeLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final imageUrl = ImageUtils.getOriginalImage(_returnRequest!.imageUrl) ?? _returnRequest!.imageUrl!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.image, size: 20, color: Color(0xFF1A5F3A)),
              SizedBox(width: 8),
              Text(
                'Ảnh minh chứng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showFullImage(_returnRequest!.imageUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A5F3A),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Không thể tải ảnh'),
                    ],
                  ),
                ),
                memCacheWidth: 400,
                memCacheHeight: 400,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Chạm vào ảnh để xem toàn màn hình',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_returnRequest!.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => _processReturn(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('TỪ CHỐI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _processReturn(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CHẤP NHẬN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      );
    } else if (_returnRequest!.status == 'approved') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _confirmCompleteReturn,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('XÁC NHẬN ĐÃ NHẬN LẠI HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double fontSizeLabel, double fontSizeValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: fontSizeLabel, color: Colors.grey[600]),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: fontSizeValue, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}