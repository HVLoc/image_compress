import 'dart:typed_data';
import 'image_compress_platform_interface.dart';

/// Lớp public gọi đến plugin nén ảnh
class ImageCompress {
  /// Nén ảnh JPEG sao cho dung lượng <= [maxSizeInKB] hoặc [maxSizeLevel] (MB).
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

  /// Nén ảnh và lưu vào thư viện (Photos/Gallery)
  static Future<bool> compressAndSaveToGallery({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) {
    return ImageCompressPlatform.instance.compressAndSaveToGallery(
      imageBytes: imageBytes,
      maxSizeInKB: maxSizeInKB,
      maxSizeLevel: maxSizeLevel,
    );
  }

  /// Nén ảnh và lưu vào file tạm, trả về đường dẫn file
  static Future<String?> compressAndSaveTempFile({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) {
    return ImageCompressPlatform.instance.compressAndSaveTempFile(
      imageBytes: imageBytes,
      maxSizeInKB: maxSizeInKB,
      maxSizeLevel: maxSizeLevel,
    );
  }
}
