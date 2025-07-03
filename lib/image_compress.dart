import 'image_compress_platform_interface.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ImageCompress {
  static Future<Uint8List?> compressImage({
    required Uint8List imageBytes,
    int maxSizeLevel = 1, // 1 ~ 1MB
  }) async {
    return await ImageCompressPlatform.instance.compressImage(
      imageBytes: imageBytes,
      maxSizeLevel: maxSizeLevel,
    );
  }
}
