import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../providers/order_provider.dart';
import '../services/payment_service.dart'; // Thêm import này
import 'order_detail_screen.dart';

class SePayPaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String? existingPaymentId;

  const SePayPaymentScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    this.existingPaymentId, // THÊM
  }) : super(key: key);

  @override
  State<SePayPaymentScreen> createState() => _SePayPaymentScreenState();
}

class _SePayPaymentScreenState extends State<SePayPaymentScreen> {
  Timer? _timer;
  int _checkCount = 0;
  bool _isCountingDown = false;
  int _countdown = 120;
  
  // Cấu hình thời gian
  static const int _pollingIntervalSeconds = 3;
  static const int _maxPollingAttempts = 40;
  static const int _countdownSeconds = 120;

  // Modern color scheme
  static const Color _primaryColor = Color(0xFF1A73E8);
  static const Color _successColor = Color(0xFF34A853);
  static const Color _warningColor = Color(0xFFFBBC04);
  static const Color _errorColor = Color(0xFFEA4335);
  static const Color _textPrimary = Color(0xFF202124);
  static const Color _textSecondary = Color(0xFF5F6368);
  static const Color _surfaceColor = Colors.white;
  static const Color _borderColor = Color(0xFFE8EAED);
  static const Color _backgroundLight = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createOrLoadPayment(); // Đổi tên hàm
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // THÊM: Hàm mới để tạo mới hoặc load payment cũ
  Future<void> _createOrLoadPayment() async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    // Nếu đã có paymentId, lấy thông tin từ API
    if (widget.existingPaymentId != null && widget.existingPaymentId!.isNotEmpty) {
      await _loadExistingPayment(widget.existingPaymentId!);
    } else {
      // Tạo payment mới
      final success = await paymentProvider.createSePayPayment(widget.orderId);
      if (success && mounted) {
        _startPolling();
      }
    }
  }

  // THÊM: Load payment đã tồn tại
  Future<void> _loadExistingPayment(String paymentId) async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    try {
      // Hiển thị loading
      if (mounted) {
        setState(() {});
      }
      
      final result = await PaymentService.getPaymentInfo(paymentId);
      
      print('Load existing payment result: $result');
      
      if (result['success'] == true && mounted) {
        final data = result['data'];
        
        // Cập nhật provider với thông tin đã có
        final qrCodeUrl = data['qrCodeUrl'];
        final paymentStatus = data['paymentStatus'];
        
        // Sử dụng reflection hoặc thêm method vào PaymentProvider
        paymentProvider.setQrCodeUrl(qrCodeUrl);
        paymentProvider.setPaymentId(data['paymentId']);
        
        if (paymentStatus == 'paid') {
          paymentProvider.setStatus('paid');
          // Thanh toán thành công, tự động đóng
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Đơn hàng đã được thanh toán trước đó!'),
                ],
              ),
              backgroundColor: _successColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context, true);
          });
        } else {
          paymentProvider.setStatus('pending');
          _startPolling(); // Bắt đầu polling để kiểm tra
        }
      } else {
        // Nếu không lấy được, tạo mới
        print('Không lấy được payment cũ, tạo mới');
        final success = await paymentProvider.createSePayPayment(widget.orderId);
        if (success && mounted) {
          _startPolling();
        }
      }
    } catch (e) {
      print('Lỗi load payment: $e');
      // Fallback: tạo mới
      final success = await paymentProvider.createSePayPayment(widget.orderId);
      if (success && mounted) {
        _startPolling();
      }
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(
      const Duration(seconds: _pollingIntervalSeconds), 
      (timer) async {
        _checkCount++;
        
        if (_checkCount > _maxPollingAttempts) {
          timer.cancel();
          if (mounted) {
            setState(() => _isCountingDown = true);
            _startCountdown();
          }
          return;
        }

        await _checkPaymentStatus();
      }
    );
  }

  void _startCountdown() {
    if (mounted && _countdown == _countdownSeconds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.timer_outlined, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Hết thời gian chờ thanh toán!\n Tự động thoát sau 2 phút'),
            ],
          ),
          backgroundColor: _warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      } else if (_countdown == 0 && mounted) {
        _showPaymentTimeoutDialog();
      }
    });
  }

  Future<void> _showPaymentTimeoutDialog() async {
    _timer?.cancel();
    final orderId = widget.orderId;
    
    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: _errorColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Chưa thanh toán',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _errorColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bạn chưa thanh toán đơn hàng ${widget.orderId}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng thanh toán để xác nhận đơn hàng.\nNếu không thanh toán, đơn hàng sẽ bị hủy sau 24 giờ.',
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Thanh toán ngay',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    if (mounted) {
      if (shouldRetry == true) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SePayPaymentScreen(
              orderId: orderId,
              amount: widget.amount,
              existingPaymentId: widget.existingPaymentId, // Giữ lại paymentId
            ),
          ),
        );
      } else {
        Navigator.pop(context);
        _navigateToOrderDetail(orderId);
      }
    }
  }

  Future<void> _navigateToOrderDetail(String orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final order = await orderProvider.fetchOrderDetail(orderId);
      
      if (mounted) Navigator.pop(context);
      
      if (mounted && order != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải thông tin đơn hàng'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    final success = await paymentProvider.checkSePayPaymentStatus(widget.orderId);
    
    if (success && mounted) {
      _timer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Thanh toán thành công!'),
              ],
            ),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    }
  }

  String _getRemainingPollingTime() {
    int remainingAttempts = _maxPollingAttempts - _checkCount;
    int remainingSeconds = remainingAttempts * _pollingIntervalSeconds;
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    if (minutes > 0) {
      return '$minutes phút $seconds giây';
    }
    return '$seconds giây';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: _surfaceColor,
          appBar: AppBar(
            title: const Text(
              'Thanh toán qua SePay',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            centerTitle: false,
            backgroundColor: _surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 20),
              onPressed: () => _showConfirmExitDialog(),
            ),
          ),
          body: provider.isLoading && provider.qrCodeUrl == null
              ? _buildLoadingState()
              : provider.errorMessage != null
                  ? _buildErrorWidget(provider.errorMessage!)
                  : _buildQRWidget(provider),
        );
      },
    );
  }

  void _showConfirmExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thoát'),
        content: const Text('Bạn chưa thanh toán đơn hàng. Thoát sẽ làm mất cơ hội thanh toán này. Bạn có muốn tiếp tục?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tạo mã thanh toán...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRWidget(PaymentProvider provider) {
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatusHeader(provider.status),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // QR Code to hơn - tăng từ 240 lên 280
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    provider.qrCodeUrl!,
                    width: 500,
                    height: 500,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 400 ,
                        height: 400,
                        color: _backgroundLight,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                                color: _primaryColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Đang tải QR...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 280,
                        height: 280,
                        color: _backgroundLight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 48, color: _textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'Không thể tải QR code',
                              style: TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Container(
                  height: 1,
                  color: _borderColor,
                ),
                
                const SizedBox(height: 20),
                
                // ĐÃ BỎ PHẦN HIỂN THỊ SỐ TIỀN CẦN THANH TOÁN
                // Chỉ giữ lại mã đơn hàng và ngân hàng
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã đơn hàng',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.orderId,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ngân hàng nhận',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00A859),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'M',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'MB Bank',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hướng dẫn thanh toán SePay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInstructionStep(
                  number: '1',
                  title: 'Mở ứng dụng ngân hàng (MB Bank)',
                  description: 'Dùng app MB Bank hoặc bất kỳ ngân hàng nào hỗ trợ VietQR',
                ),
                _buildInstructionStep(
                  number: '2',
                  title: 'Chọn tính năng "Quét mã QR"',
                  description: 'Thường nằm ở góc phải màn hình chính',
                ),
                _buildInstructionStep(
                  number: '3',
                  title: 'Quét mã QR bên trên',
                  description: 'Hệ thống sẽ tự động nhập số tiền và nội dung ${widget.orderId}',
                ),
                _buildInstructionStep(
                  number: '4',
                  title: 'Xác nhận thanh toán',
                  description: 'Kiểm tra lại thông tin (số tiền, nội dung) và xác nhận chuyển khoản',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (provider.status == 'pending' || provider.status == 'unpaid')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đang chờ thanh toán',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tự động kiểm tra mỗi $_pollingIntervalSeconds giây',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                  if (!_isCountingDown)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Thời gian chờ còn lại: ${_getRemainingPollingTime()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          if (_isCountingDown)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _warningColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _warningColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hết thời gian chờ thanh toán',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tự động quay lại sau $_countdown giây',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    Color backgroundColor;
    IconData icon;
    String title;
    String subtitle;
    
    if (status == 'paid' || status == 'success') {
      backgroundColor = _successColor;
      icon = Icons.check_circle;
      title = 'Thanh toán thành công';
      subtitle = 'Cảm ơn bạn đã thanh toán';
    } else if (status == 'failed') {
      backgroundColor = _errorColor;
      icon = Icons.error;
      title = 'Thanh toán thất bại';
      subtitle = 'Vui lòng thử lại';
    } else {
      backgroundColor = _warningColor;
      icon = Icons.access_time;
      title = 'Chờ thanh toán';
      subtitle = 'Vui lòng quét QR để thanh toán';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: backgroundColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: _errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không thể tạo thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}