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
      let uiImage = UIImage(data: imageData.data)?.fixedOrientation() {

      let maxSizeInKB = args["maxSizeInKB"] as? Int
      let maxSizeLevel = args["maxSizeLevel"] as? Int ?? 1
      let maxSizeInBytes = maxSizeInKB != nil ? maxSizeInKB! * 1024 : maxSizeLevel * 1_048_576

      if imageData.data.count <= maxSizeInBytes {
        result(imageData.data) // ✅ Ảnh đã nhỏ hơn, không cần nén
        return
      }

      var quality = CGFloat(min(1.0, max(0.1, (Double(maxSizeInBytes) / Double(imageData.data.count)) * 1.2)))
      let minQuality: CGFloat = 0.1
      let maxAttempts = 10
      var attempt = 0
      var compressedData = uiImage.jpegData(compressionQuality: quality)

      while let data = compressedData,
            data.count > maxSizeInBytes,
            quality > minQuality,
            attempt < maxAttempts {
        quality -= 0.05
        compressedData = uiImage.jpegData(compressionQuality: quality)
        attempt += 1
      }

      if let finalData = compressedData, finalData.count <= maxSizeInBytes {
        result(finalData)
      } else {
        let finalSizeKB = compressedData?.count ?? 0 / 1024
        result(FlutterError(
          code: "COMPRESSION_TOO_LARGE",
          message: "❌ Không thể nén ảnh xuống dưới \(maxSizeInBytes / 1024)KB sau \(attempt) lần. Kích thước cuối cùng: \(finalSizeKB)KB",
          details: nil
        ))
      }

    } else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "❌ Tham số không hợp lệ hoặc không có ảnh", details: nil))
    }
  }

}

extension UIImage {
  func fixedOrientation() -> UIImage {
    if self.imageOrientation == .up { return self }
    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    self.draw(in: CGRect(origin: .zero, size: self.size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return normalizedImage ?? self
  }
}
