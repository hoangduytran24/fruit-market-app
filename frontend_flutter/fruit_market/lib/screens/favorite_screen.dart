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

  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/')) {
      return 'https://10.0.2.2:7262$imagePath';
    }
    return 'https://10.0.2.2:7262/$imagePath';
  }

  String _formatCurrency(double amount) {
    int roundedAmount = amount.round();
    String formatted = roundedAmount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
    return '$formattedđ';
  }

  void _showRemoveDialog(
    BuildContext context,
    Favorite favorite,
    FavoriteProvider favoriteProvider,
  ) {
    final productName = favorite.productName;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa khỏi yêu thích'),
          content: Text('Bạn có chắc muốn xóa "$productName" khỏi danh sách yêu thích?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final success = await favoriteProvider.removeFavorite(
                  favorite.productId,
                );
                
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Đã xóa "$productName" khỏi yêu thích'),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2E7D32),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
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
      categoryName: null,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final authProvider = Provider.of<AuthProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    if (!authProvider.isAuthenticated) {
      return _buildNotLoggedIn();
    }

    if (!_hasCalledEnsure) {
      _hasCalledEnsure = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('📢 Gọi ensureFavoritesLoaded từ FavoriteScreen');
          favoriteProvider.ensureFavoritesLoaded();
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
        // ĐÃ XÓA NÚT ARROW BACK
        automaticallyImplyLeading: false, // THÊM DÒNG NÀY ĐỂ CHẮC CHẮN KHÔNG CÓ NÚT BACK
      ),
      body: RefreshIndicator(
        onRefresh: () => favoriteProvider.fetchFavorites(forceRefresh: true),
        color: const Color(0xFF2E7D32),
        child: favoriteProvider.isLoading && !favoriteProvider.hasLoaded
            ? _buildLoading()
            : favoriteProvider.favorites.isEmpty
                ? _buildEmptyState()
                : _buildFavoritesList(favoriteProvider),
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Scaffold(
      backgroundColor: Colors.white,
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
        automaticallyImplyLeading: false, // THÊM DÒNG NÀY ĐỂ CHẮC CHẮN KHÔNG CÓ NÚT BACK
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bạn chưa đăng nhập',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1E2C),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Đăng nhập để xem và quản lý\ncác sản phẩm yêu thích của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 80,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có sản phẩm yêu thích',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1E2C),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hãy thêm những sản phẩm bạn yêu thích\nvào danh sách này nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(FavoriteProvider favoriteProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoriteProvider.favorites.length,
      itemBuilder: (context, index) {
        final favorite = favoriteProvider.favorites[index];
        return _buildFavoriteItem(favorite, favoriteProvider);
      },
    );
  }

  Widget _buildFavoriteItem(Favorite favorite, FavoriteProvider favoriteProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProductDetail(context, favorite),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[100],
                    child: favorite.productImage.isNotEmpty
                        ? Image.network(
                            _getFullImageUrl(favorite.productImage),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 30,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 30,
                              color: Colors.grey[400],
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
                        favorite.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1E2C),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (favorite.productUnit.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            favorite.productUnit,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(favorite.productPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 22,
                    ),
                    onPressed: () => _showRemoveDialog(
                      context, 
                      favorite, 
                      favoriteProvider,
                    ),
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