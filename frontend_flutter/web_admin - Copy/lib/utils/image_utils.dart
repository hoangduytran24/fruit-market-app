import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUtils {
  // Base URL cho các môi trường khác nhau
  static String _getBaseUrl() {
    if (kIsWeb) {
      // Chạy trên Web (Chrome, Edge, etc.) - Chú ý port 7262 của bạn
      return 'https://localhost:7262';
    } else {
      // Chạy trên Android emulator
      return 'https://10.0.2.2:7262';
    }
  }
  
  static String get baseUrl => _getBaseUrl();

  // --- HÀM MỚI ĐỂ SỬA LỖI TRONG ORDERS_SCREEN ---
  static Widget networkImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 0,
  }) {
    final url = getOriginalImage(imageUrl);

    Widget imageWidget = (url == null || url.isEmpty)
        ? _buildPlaceholder(width, height)
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(width, height, isError: true),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildPlaceholder(width, height, isLoading: true);
            },
          );

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  static Widget _buildPlaceholder(double? width, double? height,
      {bool isError = false, bool isLoading = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(
                isError ? Icons.error_outline : Icons.image_outlined,
                color: Colors.grey[400],
                size: (width != null && width < 40) ? 16 : 24,
              ),
      ),
    );
  }
  // ----------------------------------------------

  /// Lấy URL đầy đủ của ảnh gốc (bỏ _scaled_36)
  static String? getOriginalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    String path = imageUrl;
    
    if (path.startsWith('http')) return path;
    
    path = path.replaceAll('_scaled_36', '');
    
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    
    return '$baseUrl$path';
  }

  /// Lấy URL ảnh với kích thước mong muốn
  static String? getImageWithSize(String? imageUrl, {int size = 256}) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    String path = imageUrl;
    if (path.startsWith('http')) return path;
    
    if (path.contains('_scaled_')) {
      final parts = path.split('_scaled_');
      if (parts.length > 1) {
        final extension = parts[1].substring(parts[1].indexOf('.'));
        path = '${parts[0]}_scaled_$size$extension';
      }
    } else {
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1) {
        final extension = path.substring(lastDot);
        final nameWithoutExt = path.substring(0, lastDot);
        path = '${nameWithoutExt}_scaled_$size$extension';
      }
    }
    
    if (!path.startsWith('/')) path = '/$path';
    return '$baseUrl$path';
  }

  static String? getThumbnail(String? imageUrl, {int size = 100}) {
    return getImageWithSize(imageUrl, size: size);
  }

  static bool isValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    final lowercase = imageUrl.toLowerCase();
    return lowercase.endsWith('.jpg') || 
           lowercase.endsWith('.jpeg') || 
           lowercase.endsWith('.png') || 
           lowercase.endsWith('.gif') || 
           lowercase.endsWith('.webp');
  }

  static String? getFileName(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(imageUrl);
      return uri.path.split('/').last;
    } catch (e) {
      return imageUrl.split('/').last;
    }
  }

  static int? getImageSizeFromUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.contains('_scaled_')) {
      try {
        final parts = imageUrl.split('_scaled_');
        if (parts.length > 1) {
          final sizePart = parts[1].split('.')[0];
          return int.tryParse(sizePart);
        }
      } catch (e) { return null; }
    }
    return null;
  }
}

/// Extension để sử dụng dễ dàng hơn
extension ImageUrlExtension on String? {
  String? get originalImage => ImageUtils.getOriginalImage(this);
  String? imageWithSize({int size = 256}) => ImageUtils.getImageWithSize(this, size: size);
  String? thumbnail({int size = 100}) => ImageUtils.getThumbnail(this, size: size);
  bool get isValidImage => ImageUtils.isValidImageUrl(this);
  String? get fileName => ImageUtils.getFileName(this);
  int? get imageSize => ImageUtils.getImageSizeFromUrl(this);
}