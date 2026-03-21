import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/image_utils.dart';

class CategoryCardWidget extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final bool showProductCount;
  final bool isSelected;

  const CategoryCardWidget({
    super.key,
    required this.category,
    this.onTap,
    this.showProductCount = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = category.imageUrl?.originalImage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ảnh danh mục - HIỆU ỨNG PHÁT SÁNG KHI SELECTED
            Container(
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
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.green.shade50,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.green.shade50,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            
            // Thông tin danh mục
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32,
                    child: Text(
                      category.categoryName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1E2C),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                  if (showProductCount) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 8,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${category.productCount}',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget hiển thị danh sách categories dạng horizontal
class CategoryHorizontalListWidget extends StatelessWidget {
  final List<Category> categories;
  final Function(Category)? onCategoryTap;
  final bool showProductCount;
  final String? selectedCategoryId;

  const CategoryHorizontalListWidget({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.showProductCount = true,
    this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 115,
      child: ListView.builder(
        key: const PageStorageKey<String>('category_horizontal_list'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryId == category.categoryId;
          
          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: 6),
            child: CategoryCardWidget(
              key: ValueKey(category.categoryId),
              category: category,
              onTap: onCategoryTap != null 
                  ? () => onCategoryTap!(category)
                  : null,
              showProductCount: showProductCount,
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }
}