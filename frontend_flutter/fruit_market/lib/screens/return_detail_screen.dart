import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ReturnRequest.dart';
import '../providers/return_provider.dart';
import '../utils/image_utils.dart';

class ReturnDetailScreen extends StatefulWidget {
  final String returnId;

  const ReturnDetailScreen({super.key, required this.returnId});

  @override
  State<ReturnDetailScreen> createState() => _ReturnDetailScreenState();
}

class _ReturnDetailScreenState extends State<ReturnDetailScreen> {
  bool _isLoading = true;
  ReturnRequest? _returnRequest;

  @override
  void initState() {
    super.initState();
    _loadReturnDetail();
  }

  Future<void> _loadReturnDetail() async {
    setState(() => _isLoading = true);
    
    try {
      final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
      final returnDetail = await returnProvider.fetchReturnDetail(widget.returnId);
      
      if (mounted) {
        setState(() {
          _returnRequest = returnDetail;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi tải chi tiết yêu cầu: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel;
      case 'completed': return Icons.check_circle;
      default: return Icons.info_outline;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết yêu cầu trả hàng'),
        backgroundColor: const Color(0xFF0B2A1F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : _returnRequest == null
              ? const Center(child: Text('Không tìm thấy thông tin'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trạng thái yêu cầu
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getStatusColor(_returnRequest!.status).withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getStatusIcon(_returnRequest!.status),
                                color: _getStatusColor(_returnRequest!.status),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _returnRequest!.statusText,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(_returnRequest!.status),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mã yêu cầu: ${_returnRequest!.returnId}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Ngày tạo: ${_formatDate(_returnRequest!.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Thông tin đơn hàng
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt, size: 20, color: Color(0xFF1B5E20)),
                                SizedBox(width: 8),
                                Text(
                                  'Thông tin đơn hàng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Mã đơn hàng:', _returnRequest!.orderId),
                            _buildInfoRow('Số tiền hoàn lại:', _formatCurrency(_returnRequest!.refundAmount)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Lý do trả hàng
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 10,
                            ),
                          ],
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _returnRequest!.reason,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_returnRequest!.description != null &&
                                _returnRequest!.description!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Mô tả chi tiết:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _returnRequest!.description!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Ảnh minh chứng
                      if (_returnRequest!.imageUrl != null &&
                          _returnRequest!.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.image, size: 20, color: Color(0xFF1B5E20)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ảnh minh chứng',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _showFullImage(_returnRequest!.imageUrl!),
                                child: Hero(
                                  tag: 'return_image_${_returnRequest!.returnId}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: ImageUtils.getOriginalImage(_returnRequest!.imageUrl) ?? '',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 200,
                                      placeholder: (context, url) => Container(
                                        height: 200,
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF1B5E20),
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
                        ),
                      ],

                      // Lý do từ chối (nếu có)
                      if (_returnRequest!.status == 'rejected' &&
                          _returnRequest!.rejectReason != null &&
                          _returnRequest!.rejectReason!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withAlpha(51)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Lý do từ chối',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _returnRequest!.rejectReason!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}