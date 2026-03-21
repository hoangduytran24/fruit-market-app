import 'package:flutter/material.dart';
import '../models/Voucher.dart';
import '../utils/currency_utils.dart';

class VoucherCard extends StatelessWidget {
  final VoucherPublicDto voucher;
  final VoidCallback? onSave;
  final VoidCallback? onUse;
  final bool isSaved;
  final bool showSaveButton;

  const VoucherCard({
    super.key,
    required this.voucher,
    this.onSave,
    this.onUse,
    this.isSaved = false,
    this.showSaveButton = true,
  });

  String _getDiscountText() {
    if (voucher.discountType.toLowerCase() == 'percent' ||
        voucher.discountType.toLowerCase() == 'percentage') {
      return 'Giảm ${voucher.discountValue.toInt()}%';
    } else {
      return 'Giảm ${CurrencyUtils.format(voucher.discountValue)}';
    }
  }

  Color _getStatusColor() {
    if (voucher.isExpired) return Colors.grey;
    if (voucher.isExpiring) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (voucher.isExpired) return 'Đã hết hạn';
    if (voucher.isExpiring) return 'Sắp hết hạn';
    if (voucher.remainingCount <= 5) return 'Sắp hết lượt';
    return 'Còn ${voucher.remainingCount} lượt';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onUse,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    voucher.discountType.toLowerCase() == 'percent'
                        ? Icons.percent
                        : Icons.local_offer,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            voucher.voucherCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDiscountText(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (voucher.minOrderValue > 0)
                        Text(
                          'Đơn tối thiểu ${CurrencyUtils.format(voucher.minOrderValue)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        voucher.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (voucher.endDate != null)
                        Text(
                          'HSD: ${voucher.formatDate(voucher.endDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: voucher.isExpiring ? Colors.red : Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Nút hành động
                if (showSaveButton && !isSaved)
                  GestureDetector(
                    onTap: onSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Lưu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                
                if (isSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Đã lưu',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}