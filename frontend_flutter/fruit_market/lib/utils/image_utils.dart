class ImageUtils {
  // Base URL cho Android emulator
  static const String _baseUrl = 'https://10.0.2.2:7262';
  
  // Base URL cho iOS simulator (nếu cần)
  // static const String _baseUrl = 'https://localhost:7262';
  
  // Base URL cho thiết bị thật (dùng IP máy tính)
  // static const String _baseUrl = 'https://192.168.1.x:7262';

  /// Lấy URL đầy đủ của ảnh gốc (bỏ _scaled_36)
  static String? getOriginalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    String path = imageUrl;
    
    // Nếu đã có http:// hoặc https:// thì giữ nguyên
    if (path.startsWith('http')) {
      return path;
    }
    
    // Loại bỏ _scaled_36 để lấy ảnh gốc
    path = path.replaceAll('_scaled_36', '');
    
    // Xử lý đường dẫn
    if (path.startsWith('/')) {
      return '$_baseUrl$path';
    }
    
    return '$_baseUrl/$path';
  }

  /// Lấy URL ảnh với kích thước mong muốn (nếu API hỗ trợ)
  static String? getImageWithSize(String? imageUrl, {int size = 256}) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    String path = imageUrl;
    
    if (path.startsWith('http')) return path;
    
    // Thay scaled_36 bằng scaled_size mong muốn
    if (path.contains('_scaled_')) {
      // Tách phần tên file và đuôi
      final parts = path.split('_scaled_');
      if (parts.length > 1) {
        final extension = parts[1].substring(parts[1].indexOf('.'));
        path = '${parts[0]}_scaled_$size$extension';
      }
    } else {
      // Nếu chưa có scaled, thêm vào
      final extension = path.substring(path.lastIndexOf('.'));
      final nameWithoutExt = path.substring(0, path.lastIndexOf('.'));
      path = '${nameWithoutExt}_scaled_$size$extension';
    }
    
    if (path.startsWith('/')) {
      return '$_baseUrl$path';
    }
    return '$_baseUrl/$path';
  }

  /// Lấy URL ảnh thumbnail (kích thước nhỏ)
  static String? getThumbnail(String? imageUrl, {int size = 100}) {
    return getImageWithSize(imageUrl, size: size);
  }

  /// Kiểm tra URL ảnh có hợp lệ không
  static bool isValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    
    // Kiểm tra định dạng file
    final lowercase = imageUrl.toLowerCase();
    return lowercase.endsWith('.jpg') || 
           lowercase.endsWith('.jpeg') || 
           lowercase.endsWith('.png') || 
           lowercase.endsWith('.gif') || 
           lowercase.endsWith('.webp');
  }

  /// Lấy tên file từ URL
  static String? getFileName(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    try {
      final uri = Uri.parse(imageUrl);
      final path = uri.path;
      return path.split('/').last;
    } catch (e) {
      return imageUrl.split('/').last;
    }
  }

  /// Lấy kích thước ảnh từ URL (nếu có)
  static int? getImageSizeFromUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    if (imageUrl.contains('_scaled_')) {
      try {
        final parts = imageUrl.split('_scaled_');
        if (parts.length > 1) {
          final sizePart = parts[1].split('.')[0];
          return int.tryParse(sizePart);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Tạo URL với base URL khác (dùng cho môi trường khác)
  static String? withBaseUrl(String? imageUrl, String baseUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    if (imageUrl.startsWith('http')) return imageUrl;
    
    if (imageUrl.startsWith('/')) {
      return '$baseUrl$imageUrl';
    }
    return '$baseUrl/$imageUrl';
  }

  /// Lấy URL cho môi trường hiện tại
  static String? getImageUrlForEnvironment(String? imageUrl, {
    required bool isAndroid,
    required bool isIOS,
    String? customBaseUrl,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    if (imageUrl.startsWith('http')) return imageUrl;
    
    String baseUrl;
    
    if (customBaseUrl != null) {
      baseUrl = customBaseUrl;
    } else if (isAndroid) {
      baseUrl = 'https://10.0.2.2:7262';
    } else if (isIOS) {
      baseUrl = 'https://localhost:7262';
    } else {
      baseUrl = _baseUrl;
    }
    
    String path = imageUrl.replaceAll('_scaled_36', '');
    
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }
}

/// Extension để sử dụng dễ dàng hơn
extension ImageUrlExtension on String? {
  String? get originalImage => ImageUtils.getOriginalImage(this);
  
  String? imageWithSize({int size = 256}) => 
      ImageUtils.getImageWithSize(this, size: size);
  
  String? thumbnail({int size = 100}) => 
      ImageUtils.getThumbnail(this, size: size);
  
  bool get isValidImage => ImageUtils.isValidImageUrl(this);
  
  String? get fileName => ImageUtils.getFileName(this);
  
  int? get imageSize => ImageUtils.getImageSizeFromUrl(this);
}