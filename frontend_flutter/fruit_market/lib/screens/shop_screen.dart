import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/category_card_widget.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;
  
  // Biến để lưu danh mục đang được chọn
  String? _selectedCategoryId;
  bool _isDataLoaded = false;

  // Danh sách banner
  final List<String> _bannerImages = [
    'lib/assets/img/bn1.png',
    'lib/assets/img/bn2.png',
    'lib/assets/img/bn3.png',
  ];

  // Hàm lấy tên hiển thị (tên cuối cùng)
  String _getDisplayName(String fullName) {
    if (fullName.isEmpty) return 'Người dùng';
    
    List<String> nameParts = fullName.split(' ');
    if (nameParts.length > 1) {
      return nameParts.last;
    }
    return fullName;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    
    // Tự động chuyển banner mỗi 3 giây
    _startBannerAutoScroll();
  }

  Future<void> _loadInitialData() async {
    if (_isDataLoaded) return;
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    // Load sản phẩm chỉ khi chưa có dữ liệu
    if (!productProvider.hasLoaded) {
      await productProvider.loadProducts(refresh: true);
    }
    
    // Load danh mục chỉ khi chưa có dữ liệu
    if (!categoryProvider.hasLoaded) {
      await categoryProvider.ensureCategoriesLoaded();
    }
    
    _isDataLoaded = true;
  }

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      if (_bannerPageController.hasClients) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage >= _bannerImages.length) {
          nextPage = 0;
        }
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startBannerAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.clearSearch();
    _searchController.clear();
    setState(() {
      _selectedCategoryId = null;
    });
    await provider.refreshProducts();
  }

  void _goToPage(int page) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.goToPage(page);
  }

  void _filterByCategory(String? categoryId, String categoryName) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    if (categoryId == null) {
      productProvider.refreshProducts();
    } else {
      productProvider.filterByCategory(categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    // Lấy tên người dùng từ AuthProvider
    final user = authProvider.currentUser;
    final fullName = user?.fullName ?? 'Người dùng';
    final displayName = _getDisplayName(fullName);

    // Hiển thị loading nếu đang load lần đầu
    if ((!productProvider.hasLoaded && productProvider.isLoading) || 
        (!categoryProvider.hasLoaded && categoryProvider.isLoading)) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Đang tải dữ liệu...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A1F),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Logo và tên app
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'lib/assets/img/logo1.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7CB342),
                                  Color(0xFF4CAF50),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'TM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'GreenFruit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'MARKET',
                        style: TextStyle(
                          color: Color(0xFF7CB342),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Thanh tìm kiếm
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              productProvider.searchProducts(value);
                            } else {
                              productProvider.loadProducts(refresh: true);
                            }
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm trái cây tươi...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            productProvider.loadProducts(refresh: true);
                          },
                          padding: EdgeInsets.zero,
                          splashRadius: 18,
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => DefaultTabController.of(context)?.animateTo(2),
                    padding: EdgeInsets.zero,
                    splashRadius: 22,
                  ),
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF6B6B),
                              Color(0xFFFF4757),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF4757),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: Colors.green,
        child: productProvider.error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Có lỗi xảy ra',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        productProvider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => productProvider.loadProducts(refresh: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Phần chào hỏi
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                authProvider.isAuthenticated ? 'Chào $displayName!' : 'Chào bạn!',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const SizedBox(width: 8),
                              const Text('👋', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Hôm nay bạn muốn ăn gì?',
                            style: TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Banner Carousel
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: PageView.builder(
                        controller: _bannerPageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentBannerIndex = index;
                          });
                        },
                        itemCount: _bannerImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                _bannerImages[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Banner ${index + 1}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Chỉ báo dấu chấm
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _bannerImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentBannerIndex == index ? 20 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentBannerIndex == index
                                  ? Colors.green
                                  : Colors.grey.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Danh mục
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Color.fromARGB(255, 10, 144, 15),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Danh mục',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E3A59),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Hiển thị danh mục từ API
                          if (categoryProvider.categories.isEmpty)
                            const SizedBox(
                              height: 115,
                              child: Center(
                                child: Text('Không có danh mục'),
                              ),
                            )
                          else
                            SizedBox(
                              height: 115,
                              child: ListView.builder(
                                key: const PageStorageKey<String>('category_list'),
                                scrollDirection: Axis.horizontal,
                                itemCount: categoryProvider.categories.length + 1,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  // Item "Tất cả" ở đầu
                                  if (index == 0) {
                                    final isSelected = _selectedCategoryId == null;
                                    
                                    return GestureDetector(
                                      onTap: () => _filterByCategory(null, 'Tất cả'),
                                      child: Container(
                                        width: 70,
                                        margin: const EdgeInsets.only(right: 5),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.green.withOpacity(0.5),
                                                          blurRadius: 12,
                                                          spreadRadius: 2,
                                                          offset: const Offset(0, 4),
                                                        ),
                                                        BoxShadow(
                                                          color: Colors.green.withOpacity(0.3),
                                                          blurRadius: 20,
                                                          spreadRadius: 4,
                                                          offset: const Offset(0, 0),
                                                        ),
                                                      ]
                                                    : [],
                                                border: Border.all(
                                                  color: isSelected ? Colors.green : Colors.grey.withOpacity(0.2),
                                                  width: isSelected ? 2 : 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.asset(
                                                  'lib/assets/img/logo.png',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.green.shade50,
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.image_not_supported_outlined,
                                                          size: 30,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Tất cả',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                color: isSelected ? Colors.green : Colors.grey.shade700,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  // Các danh mục từ API
                                  final category = categoryProvider.categories[index - 1];
                                  final isSelected = _selectedCategoryId == category.categoryId;
                                  
                                  return GestureDetector(
                                    onTap: () => _filterByCategory(category.categoryId, category.categoryName),
                                    child: Container(
                                      width: 70,
                                      margin: const EdgeInsets.only(right: 5),
                                      child: CategoryCardWidget(
                                        key: ValueKey(category.categoryId),
                                        category: category,
                                        showProductCount: false,
                                        isSelected: isSelected,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Gợi ý cho bạn
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Gợi ý cho bạn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Danh sách sản phẩm
                  if (productProvider.products.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Không có sản phẩm',
                                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = productProvider.products[index];
                            return ProductCard(
                              key: ValueKey(product.productId),
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: productProvider.products.length,
                        ),
                      ),
                    ),
                  
                  // Phân trang
                  if (productProvider.totalPages > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${productProvider.products.length} / ${productProvider.totalCount} sản phẩm',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPageButton(
                                  icon: Icons.chevron_left,
                                  onPressed: productProvider.currentPage > 1
                                      ? () => _goToPage(productProvider.currentPage - 1)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                ..._buildPageNumbers(productProvider),
                                const SizedBox(width: 8),
                                _buildPageButton(
                                  icon: Icons.chevron_right,
                                  onPressed: productProvider.currentPage < productProvider.totalPages
                                      ? () => _goToPage(productProvider.currentPage + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300!),
        borderRadius: BorderRadius.circular(8),
        color: onPressed == null ? Colors.grey.shade100 : Colors.white,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: onPressed == null ? Colors.grey : Colors.green),
        padding: EdgeInsets.zero,
      ),
    );
  }

  List<Widget> _buildPageNumbers(ProductProvider provider) {
    List<Widget> pages = [];
    int currentPage = provider.currentPage;
    int totalPages = provider.totalPages;

    pages.add(_buildPageNumberButton(1, currentPage == 1));

    if (totalPages <= 5) {
      for (int i = 2; i <= totalPages; i++) {
        pages.add(const SizedBox(width: 6));
        pages.add(_buildPageNumberButton(i, currentPage == i));
      }
    } else {
      if (currentPage > 3) {
        pages.add(const SizedBox(width: 6));
        pages.add(Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Text('...', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ));
      }

      int start = currentPage > 2 ? currentPage - 1 : 2;
      int end = currentPage < totalPages - 1 ? currentPage + 1 : totalPages - 1;

      for (int i = start; i <= end; i++) {
        if (i > 1 && i < totalPages) {
          pages.add(const SizedBox(width: 6));
          pages.add(_buildPageNumberButton(i, currentPage == i));
        }
      }

      if (currentPage < totalPages - 2) {
        pages.add(const SizedBox(width: 6));
        pages.add(Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Text('...', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ));
      }

      if (totalPages > 1) {
        pages.add(const SizedBox(width: 6));
        pages.add(_buildPageNumberButton(totalPages, currentPage == totalPages));
      }
    }

    return pages;
  }

  Widget _buildPageNumberButton(int page, bool isSelected) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isSelected ? Colors.green : Colors.white,
        border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton(
        onPressed: isSelected ? null : () => _goToPage(page),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
        ),
        child: Text(
          page.toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}