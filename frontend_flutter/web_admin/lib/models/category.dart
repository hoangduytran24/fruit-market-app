class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final int productCount;
  final bool isActive;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.productCount = 0,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      productCount: json['productCount'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'productCount': productCount,
      'isActive': isActive,
    };
  }
}