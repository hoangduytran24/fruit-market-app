import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/product_detail_screen.dart';
import '../models/product.dart';
import '../models/favorite.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _hasCalledEnsure = false;

  // Tối ưu: Di chuyển hằng số URL ra ngoài hoặc dùng biến môi trường nếu cần
  static const String _baseUrl = 'https://10.0.2.2:7262';

  String _getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    final cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$_baseUrl$cleanPath';
  }

  String _formatCurrency(double amount) {
    return '${amount.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        )}đ';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();

    if (!authProvider.isAuthenticated) {
      return _NotLoggedInView();
    }

    if (!_hasCalledEnsure) {
      _hasCalledEnsure = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          favoriteProvider.ensureFavoritesLoaded();
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Màu nền nhẹ hơn để nổi bật thẻ trắng
      appBar: AppBar(
        title: const Text(
          'Yêu thích',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1E2C),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => favoriteProvider.fetchFavorites(forceRefresh: true),
        color: const Color(0xFF2E7D32),
        child: _buildBody(favoriteProvider),
      ),
    );
  }

  Widget _buildBody(FavoriteProvider provider) {
    if (provider.isLoading && !provider.hasLoaded) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (provider.favorites.isEmpty) {
      return const _EmptyStateView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.favorites.length,
      itemBuilder: (context, index) {
        return _FavoriteItemTile(
          favorite: provider.favorites[index],
          formatCurrency: _formatCurrency,
          imageUrl: _getFullImageUrl(provider.favorites[index].productImage),
          onRemove: () => _showRemoveDialog(context, provider.favorites[index], provider),
          onTap: () => _navigateToProductDetail(context, provider.favorites[index]),
        );
      },
    );
  }

  void _showRemoveDialog(BuildContext context, Favorite favorite, FavoriteProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khỏi yêu thích'),
        content: Text('Bạn có chắc muốn xóa "${favorite.productName}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.removeFavorite(favorite.productId);
              if (context.mounted && success) {
                _showSuccessSnackBar(context, favorite.productName);
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "$name" khỏi yêu thích'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _navigateToProductDetail(BuildContext context, Favorite favorite) {
    final product = Product(
      productId: favorite.productId,
      productName: favorite.productName,
      price: favorite.productPrice,
      unit: favorite.productUnit,
      imageUrl: favorite.productImage,
      stockQuantity: 10,
      description: '',
      categoryId: '',
      supplierId: '',
      isActive: true,
      createdAt: DateTime.now(),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
  }
}

// --- Các Component nhỏ để tối ưu hóa việc render và dễ bảo trì ---

class _FavoriteItemTile extends StatelessWidget {
  final Favorite favorite;
  final String imageUrl;
  final String Function(double) formatCurrency;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _FavoriteItemTile({
    required this.favorite,
    required this.imageUrl,
    required this.formatCurrency,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tối ưu Responsive: Lấy độ rộng màn hình để điều chỉnh layout nếu cần
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ảnh sản phẩm
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: screenWidth > 400 ? 90 : 80, // Tăng kích thước nhẹ trên màn hình lớn
                  height: screenWidth > 400 ? 90 : 80,
                  color: Colors.grey[100],
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                        )
                      : const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Thông tin sản phẩm
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.productName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1E2C)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (favorite.productUnit.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                        child: Text(favorite.productUnit, style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      formatCurrency(favorite.productPrice),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                  ],
                ),
              ),
              // Nút xóa
              IconButton(
                onPressed: onRemove,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotLoggedInView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Yêu thích', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0, backgroundColor: Colors.white, automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _StatusIcon(icon: Icons.favorite_border, color: Colors.green[50]!),
              const SizedBox(height: 24),
              const Text('Bạn chưa đăng nhập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Đăng nhập để xem danh sách yêu thích của bạn', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Đăng nhập ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatusIcon(icon: Icons.favorite_border, color: Colors.green[50]!),
          const SizedBox(height: 24),
          const Text('Chưa có sản phẩm yêu thích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Hãy thêm sản phẩm bạn thích vào đây nhé!', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _StatusIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 80, color: const Color(0xFF2E7D32)),
    );
  }
}