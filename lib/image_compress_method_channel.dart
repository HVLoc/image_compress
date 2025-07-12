import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_compress_platform_interface.dart';

/// Thực thi native sử dụng method channel
class MethodChannelImageCompress extends ImageCompressPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('image_compress');

  @override
  Future<Uint8List?> compressImage({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) async {
    final arguments = {
      'image': imageBytes,
      if (maxSizeInKB != null) 'maxSizeInKB': maxSizeInKB,
      if (maxSizeInKB == null) 'maxSizeLevel': maxSizeLevel,
    };

    return await methodChannel.invokeMethod<Uint8List>(
      'compressImage',
      arguments,
    );
  }

  @override
  Future<bool> compressAndSaveToGallery({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) async {
    final arguments = {
      'image': imageBytes,
      if (maxSizeInKB != null) 'maxSizeInKB': maxSizeInKB,
      if (maxSizeInKB == null) 'maxSizeLevel': maxSizeLevel,
    };

    return await methodChannel.invokeMethod<bool>(
          'compressAndSaveToGallery',
          arguments,
        ) ??
        false;
  }

  @override
  Future<String?> compressAndSaveTempFile({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) async {
    final arguments = {
      'image': imageBytes,
      if (maxSizeInKB != null) 'maxSizeInKB': maxSizeInKB,
      if (maxSizeInKB == null) 'maxSizeLevel': maxSizeLevel,
    };

    return await methodChannel.invokeMethod<String>(
      'compressAndSaveTempFile',
      arguments,
    );
  }
}
