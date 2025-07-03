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

      // Ưu tiên sử dụng maxSizeInKB nếu có
      let maxSizeInKB = args["maxSizeInKB"] as? Int
      let maxSizeLevel = args["maxSizeLevel"] as? Int ?? 1
      let maxSizeInBytes = maxSizeInKB != nil ? maxSizeInKB! * 1024 : maxSizeLevel * 1_048_576

      let originalSize = imageData.data.count

      var quality = CGFloat(min(1.0, max(0.1, (Double(maxSizeInBytes) / Double(originalSize)) * 1.2)))
      let minQuality: CGFloat = 0.1
      let maxAttempts = 10
      var attempt = 0
      var compressedData = image.jpegData(compressionQuality: quality)

      while let data = compressedData,
            data.count > maxSizeInBytes,
            quality > minQuality,
            attempt < maxAttempts {
        quality -= 0.05
        compressedData = image.jpegData(compressionQuality: quality)
        attempt += 1
      }

      if let finalData = compressedData, finalData.count <= maxSizeInBytes {
        result(finalData)
      } else {
        result(FlutterError(
          code: "COMPRESSION_FAILED",
          message: "Cannot compress image under \(maxSizeInBytes) bytes after \(attempt) attempts",
          details: nil
        ))
      }

    } else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments or image", details: nil))
    }
  }
}

extension UIImage {
  func fixedOrientation() -> UIImage {
    if self.imageOrientation == .up {
      return self
    }

    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    self.draw(in: CGRect(origin: .zero, size: self.size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return normalizedImage ?? self
  }
}

