import 'dart:typed_data';
import 'image_compress_platform_interface.dart';

/// Lớp public gọi đến plugin nén ảnh
class ImageCompress {
  /// Nén ảnh JPEG sao cho dung lượng <= [maxSizeInKB] hoặc [maxSizeLevel] (MB).
  ///
  /// - Nếu [maxSizeInKB] được truyền, ưu tiên sử dụng.
  /// - Nếu không có, fallback về [maxSizeLevel] với mỗi level = 1MB.
  static Future<Uint8List?> compressImage({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) {
    return ImageCompressPlatform.instance.compressImage(
      imageBytes: imageBytes,
      maxSizeInKB: maxSizeInKB,
      maxSizeLevel: maxSizeLevel,
    );
  }
}
