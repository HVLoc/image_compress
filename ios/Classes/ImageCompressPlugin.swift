import Flutter
import UIKit

public class ImageCompressPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "image_compress", binaryMessenger: registrar.messenger())
    let instance = ImageCompressPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "compressImage",
       let args = call.arguments as? [String: Any],
       let imageData = args["image"] as? FlutterStandardTypedData,
       let image = UIImage(data: imageData.data)?.fixedOrientation() {

      let level = args["maxSizeLevel"] as? Int ?? 1
      let maxSize = level * 1_048_576
      let originalSize = imageData.data.count

      let estimatedQuality = CGFloat(min(1.0, max(0.1, (Double(maxSize) / Double(originalSize)) * 1.2)))
      var quality = estimatedQuality

      let minQuality: CGFloat = 0.1
      var compressedData = image.jpegData(compressionQuality: quality)
      var attempt = 0
      let maxAttempts = 10

      while let data = compressedData,
            data.count > maxSize,
            quality > minQuality,
            attempt < maxAttempts {
        quality -= 0.05
        compressedData = image.jpegData(compressionQuality: quality)
        attempt += 1
      }

      if let finalData = compressedData, finalData.count <= maxSize {
        result(finalData)
      } else {
        result(FlutterError(
          code: "COMPRESSION_FAILED",
          message: "Cannot compress image under \(maxSize) bytes after \(attempt) attempts",
          details: nil
        ))
      }
    } else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
    }
  }
}
