import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/image_utils.dart';
import '../../utils/responsive.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.refreshProducts();
  }

  Future<void> _refresh() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    _searchController.clear();
    await productProvider.refreshProducts();
  }

  void _onSearchSubmitted(String value) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (value.isNotEmpty) {
      productProvider.searchProducts(value);
    } else {
      productProvider.refreshProducts();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.refreshProducts();
  }

  void _openProductForm([Product? product]) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, 
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ProductFormScreen(product: product),
        ),
      ),
    ).then((value) {
      if (value == true) {
        _refresh();
      }
    });
  }

  String _formatCurrency(double amount) {
    return amount.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${product.productName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      try {
        await productProvider.deleteProduct(product.productId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa sản phẩm thành công'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e is String ? e : e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _goToPage(int page) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (page >= 1 && page <= productProvider.totalPages && page != productProvider.currentPage) {
      productProvider.goToPage(page);
    }
  }

  // Hàm lấy text trạng thái sản phẩm
  String _getProductStatusText(Product product) {
    // Nếu sản phẩm có trường isActive hoặc status
    // Giả sử product có trường isActive (bool) hoặc status (String)
    if (product.isActive == false) {
      return 'Ngừng kinh doanh';
    }
    // Nếu có stockQuantity
    if (product.stockQuantity > 0) {
      return 'Còn hàng';
    } else {
      return 'Hết hàng';
    }
  }

  // Hàm lấy màu cho trạng thái
  Color _getProductStatusColor(Product product) {
    if (product.isActive == false) {
      return Colors.orange;
    }
    if (product.stockQuantity > 0) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  // Hàm lấy màu nền cho trạng thái
  Color _getProductStatusBackgroundColor(Product product) {
    if (product.isActive == false) {
      return Colors.orange.withOpacity(0.1);
    }
    if (product.stockQuantity > 0) {
      return Colors.green.withOpacity(0.1);
    } else {
      return Colors.red.withOpacity(0.1);
    }
  }

  // Hàm lấy icon cho trạng thái
  IconData _getProductStatusIcon(Product product) {
    if (product.isActive == false) {
      return Icons.pause_circle_outline;
    }
    if (product.stockQuantity > 0) {
      return Icons.check_circle_outline;
    } else {
      return Icons.remove_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildToolBar(isMobile),
          Expanded(
            child: productProvider.isLoading && productProvider.products.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A5F3A)))
                : productProvider.products.isEmpty
                    ? _buildEmptyState(isMobile)
                    : LayoutBuilder(builder: (context, constraints) {
                        return Column(
                          children: [
                            Expanded(
                              child: _buildProductTable(productProvider.products, isMobile, constraints),
                            ),
                            if (productProvider.totalPages > 1)
                              _buildPagination(productProvider.totalPages, productProvider.currentPage, isMobile),
                          ],
                        );
                      }),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? 180 : 350,
            height: 42,
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: _clearSearch)
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openProductForm(),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(isMobile ? 'Thêm' : 'Thêm sản phẩm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5F3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text('Không tìm thấy sản phẩm nào', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProductTable(List<Product> products, bool isMobile, BoxConstraints constraints) {
    double minTableWidth = isMobile ? 800 : 1100;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Container(
                width: minTableWidth,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTableHeader(),
                    ...products.map((product) => _buildProductRow(product)).toList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A5F3A), fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F8E9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Sản phẩm', style: headerStyle)),
          Expanded(flex: 1, child: Center(child: Text('Ảnh', style: headerStyle))),
          Expanded(flex: 2, child: Center(child: Text('Danh mục', style: headerStyle))),
          Expanded(flex: 2, child: Text('Giá bán', style: headerStyle, textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Center(child: Text('Kho', style: headerStyle))),
          Expanded(flex: 2, child: Center(child: Text('Trạng thái', style: headerStyle))),
          Expanded(flex: 3, child: Center(child: Text('Hành động', style: headerStyle))),
        ],
      ),
    );
  }

  Widget _buildProductRow(Product product) {
    final imageUrl = ImageUtils.getOriginalImage(product.imageUrl);
    final statusText = _getProductStatusText(product);
    final statusColor = _getProductStatusColor(product);
    final statusBgColor = _getProductStatusBackgroundColor(product);
    final statusIcon = _getProductStatusIcon(product);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
        // Thêm màu nền nhạt nếu sản phẩm ngừng kinh doanh
        color: product.isActive == false ? Colors.grey.shade50 : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2, 
            child: Text(
              product.productName, 
              style: TextStyle(
                fontWeight: FontWeight.w500, 
                fontSize: 13,
                // Thêm gạch ngang nếu ngừng kinh doanh
                decoration: product.isActive == false ? TextDecoration.lineThrough : null,
                color: product.isActive == false ? Colors.grey : null,
              ), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl, 
                        width: 35, 
                        height: 35, 
                        fit: BoxFit.cover,
                        // Thêm opacity nếu ngừng kinh doanh
                        color: product.isActive == false ? Colors.grey.withOpacity(0.5) : null,
                        colorBlendMode: product.isActive == false ? BlendMode.color : null,
                      )
                    : Container(
                        width: 35, 
                        height: 35, 
                        color: Colors.grey[100], 
                        child: Icon(
                          Icons.image, 
                          size: 20, 
                          color: product.isActive == false ? Colors.grey : Colors.grey,
                        ),
                      ),
              ),
            ),
          ),
          Expanded(
            flex: 2, 
            child: Center(
              child: Text(
                product.categoryName ?? '-', 
                style: TextStyle(
                  fontSize: 13,
                  color: product.isActive == false ? Colors.grey : null,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2, 
            child: Text(
              '${_formatCurrency(product.price)}₫', 
              textAlign: TextAlign.right, 
              style: TextStyle(
                color: product.isActive == false ? Colors.grey : Colors.green, 
                fontWeight: FontWeight.bold, 
                fontSize: 13,
                decoration: product.isActive == false ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Expanded(
            flex: 1, 
            child: Center(
              child: Text(
                product.stockQuantity.toString(), 
                style: TextStyle(
                  fontSize: 13,
                  color: product.isActive == false ? Colors.grey : null,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionIcon(Icons.visibility_outlined, Colors.blue, 'Chi tiết', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                  ).then((_) => _refresh());
                }),
                // Nếu sản phẩm ngừng kinh doanh, vẫn cho phép sửa (có thể kích hoạt lại)
                _buildActionIcon(Icons.edit_outlined, Colors.orange, 'Sửa', () {
                  _openProductForm(product); 
                }),
                _buildActionIcon(Icons.delete_outline, Colors.red, 'Xóa', () => _deleteProduct(product)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, color: color, size: 18),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildPagination(int totalPages, int currentPage, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(Icons.first_page, currentPage > 1 ? () => _goToPage(1) : null),
          _buildPageButton(Icons.chevron_left, currentPage > 1 ? () => _goToPage(currentPage - 1) : null),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1A5F3A), borderRadius: BorderRadius.circular(15)),
            child: Text('$currentPage / $totalPages', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          _buildPageButton(Icons.chevron_right, currentPage < totalPages ? () => _goToPage(currentPage + 1) : null),
          _buildPageButton(Icons.last_page, currentPage < totalPages ? () => _goToPage(totalPages) : null),
        ],
      ),
    );
  }

  Widget _buildPageButton(IconData icon, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      color: const Color(0xFF1A5F3A),
      disabledColor: Colors.grey[300],
    );
  }
}