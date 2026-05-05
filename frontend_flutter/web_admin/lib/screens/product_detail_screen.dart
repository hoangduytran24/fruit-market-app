import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/image_utils.dart';
import '../utils/responsive.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailScreen({super.key, this.product, this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (widget.product != null) {
      setState(() {
        _product = widget.product;
        _isLoading = false;
      });
      return;
    }

    if (widget.productId != null) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.getProductById(widget.productId!);
      setState(() {
        _product = product;
        _isLoading = false;
        if (product == null) {
          _error = 'Không tìm thấy sản phẩm trên hệ thống';
        }
      });
    }
  }

  Future<void> _refresh() async {
    if (widget.productId != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.getProductById(widget.productId!);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1A5F3A))),
      );
    }

    if (_error != null || _product == null) return _buildErrorState();

    final product = _product!;
    final isMobile = context.isMobile;
    final imageUrl = ImageUtils.getOriginalImage(product.imageUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A5F3A),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        // Đã xóa actions (nút sửa)
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF1A5F3A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (MediaQuery.of(context).size.width * 0.1),
            vertical: 24,
          ),
          child: Column(
            children: [
              // --- PHẦN 1: BANNER CHÍNH (ẢNH & TÊN) ---
              _buildHeroCard(product, imageUrl, isMobile),
              
              const SizedBox(height: 16),

              // --- PHẦN 2: BENTO GRID (THÔNG SỐ ĐỊNH LƯỢNG) ---
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildBentoItem(constraints, "Danh mục", product.categoryName ?? "N/A", Icons.grid_view_rounded, isMobile),
                      _buildBentoItem(constraints, "Tồn kho", "${product.stockQuantity}", Icons.inventory_2_rounded, isMobile),
                      _buildBentoItem(constraints, "Đơn vị", product.unit, Icons.straighten_rounded, isMobile),
                      _buildBentoItem(constraints, "Giá bán", "${_formatCurrency(product.price)}đ", Icons.payments_rounded, isMobile),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // --- PHẦN 3: CHI TIẾT MÔ TẢ & NHÀ CUNG CẤP ---
              _buildInfoContainer(product),

              const SizedBox(height: 32),
              
              // Đã xóa nút "Gỡ bỏ sản phẩm này"
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: CARD CHÍNH ---
  Widget _buildHeroCard(Product product, String? imageUrl, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 90 : 130,
            height: isMobile ? 90 : 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFF8F9FA),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, 
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey))
                  : const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBadge(product.stockQuantity > 0),
                const SizedBox(height: 8),
                Text(
                  product.productName,
                  style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A202C)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text("ID: #${product.productId.toUpperCase()}", 
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, letterSpacing: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: Ô THÔNG SỐ (BENTO BOX) ---
  Widget _buildBentoItem(BoxConstraints constraints, String label, String value, IconData icon, bool isMobile) {
    final double width = isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF1F8E9), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: const Color(0xFF1A5F3A)),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3748)), 
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // --- WIDGET: CONTAINER CHI TIẾT ---
  Widget _buildInfoContainer(Product product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextRow("Nhà cung cấp", product.supplierName ?? "N/A", Icons.business_outlined),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          _buildTextRow("Ngày nhập kho", _formatDate(product.createdAt), Icons.history_rounded),
          const SizedBox(height: 24),
          const Text("Mô tả sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Text(
            product.description ?? "Không có mô tả chi tiết cho sản phẩm này.",
            style: const TextStyle(color: Color(0xFF4A5568), height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748), fontSize: 14)),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAvailable ? "ĐANG KINH DOANH" : "HẾT HÀNG",
        style: TextStyle(
          color: isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontWeight: FontWeight.bold,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }


  Widget _buildErrorState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error ?? 'Lỗi dữ liệu'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Quay lại")),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) => amount.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  String _formatDate(DateTime date) => "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}