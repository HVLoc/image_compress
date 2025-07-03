import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_compress_platform_interface.dart';

/// An implementation of [ImageCompressPlatform] that uses method channels.
class MethodChannelImageCompress extends ImageCompressPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('image_compress');

  @override
  Future<Uint8List?> compressImage({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1, // fallback nếu không có maxSizeInKB
  }) async {
    final arguments = {
      'image': imageBytes,
      if (maxSizeInKB != null) 'maxSizeInKB': maxSizeInKB,
      if (maxSizeInKB == null) 'maxSizeLevel': maxSizeLevel,
    };

    final result = await methodChannel.invokeMethod<Uint8List>(
      'compressImage',
      arguments,
    );

    return result;
  }
}
