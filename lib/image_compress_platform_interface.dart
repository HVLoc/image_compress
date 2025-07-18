import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_compress_method_channel.dart';

abstract class ImageCompressPlatform extends PlatformInterface {
  ImageCompressPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImageCompressPlatform _instance = MethodChannelImageCompress();

  static ImageCompressPlatform get instance => _instance;

  static set instance(ImageCompressPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Uint8List?> compressImage({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) {
    throw UnimplementedError('compressImage() has not been implemented.');
  }

  Future<bool> compressAndSaveToGallery({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) {
    throw UnimplementedError(
        'compressAndSaveToGallery() has not been implemented.');
  }

  Future<String?> compressAndSaveTempFile({
    required Uint8List imageBytes,
    int? maxSizeInKB,
    int maxSizeLevel = 1,
  }) {
    throw UnimplementedError(
        'compressAndSaveTempFile() has not been implemented.');
  }
}
