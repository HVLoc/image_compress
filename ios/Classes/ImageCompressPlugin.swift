import Flutter
import UIKit
import Photos

public class ImageCompressPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "image_compress", binaryMessenger: registrar.messenger())
    let instance = ImageCompressPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imageData = args["image"] as? FlutterStandardTypedData,
          let uiImage = UIImage(data: imageData.data)?.fixedOrientation() else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "❌ Tham số không hợp lệ hoặc không có ảnh", details: nil))
      return
    }

    let maxSizeInKB = args["maxSizeInKB"] as? Int
    let maxSizeLevel = args["maxSizeLevel"] as? Int ?? 1
    let maxSizeInBytes = (maxSizeInKB ?? (maxSizeLevel * 1024)) * 1024

    switch call.method {
    case "compressImage":
      compressImage(uiImage: uiImage, maxSizeInBytes: maxSizeInBytes, originalData: imageData.data, result: result)

    case "compressAndSaveToGallery":
      compressImage(uiImage: uiImage, maxSizeInBytes: maxSizeInBytes, originalData: imageData.data) { compressed in
        guard let data = compressed else {
          result(FlutterError(code: "COMPRESSION_FAILED", message: "❌ Không thể nén ảnh", details: nil))
          return
        }
        self.saveToGallery(data: data, result: result)
      }

    case "compressAndSaveTempFile":
      compressImage(uiImage: uiImage, maxSizeInBytes: maxSizeInBytes, originalData: imageData.data) { compressed in
        guard let data = compressed else {
          result(FlutterError(code: "COMPRESSION_FAILED", message: "❌ Không thể nén ảnh", details: nil))
          return
        }
        self.saveToTempFile(data: data, result: result)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func compressImage(uiImage: UIImage, maxSizeInBytes: Int, originalData: Data, result: @escaping FlutterResult) {
    compressImage(uiImage: uiImage, maxSizeInBytes: maxSizeInBytes, originalData: originalData) { compressed in
      if let finalData = compressed {
        result(finalData)
      } else {
        result(FlutterError(code: "COMPRESSION_TOO_LARGE", message: "❌ Không thể nén ảnh dưới \(maxSizeInBytes / 1024)KB", details: nil))
      }
    }
  }

  private func compressImage(uiImage: UIImage, maxSizeInBytes: Int, originalData: Data, completion: @escaping (Data?) -> Void) {
    if originalData.count <= maxSizeInBytes {
      completion(originalData)
      return
    }

    var quality = CGFloat(min(1.0, max(0.1, (Double(maxSizeInBytes) / Double(originalData.count)) * 1.2)))
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

    if let data = compressedData, data.count <= maxSizeInBytes {
      completion(data)
    } else {
      completion(nil)
    }
  }

  private func saveToGallery(data: Data, result: @escaping FlutterResult) {
    PHPhotoLibrary.shared().performChanges({
      let options = PHAssetResourceCreationOptions()
      let creationRequest = PHAssetCreationRequest.forAsset()
      creationRequest.addResource(with: .photo, data: data, options: options)
    }, completionHandler: { success, error in
      if success {
        result(true)
      } else {
        result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription ?? "Không thể lưu ảnh", details: nil))
      }
    })
  }

  private func saveToTempFile(data: Data, result: @escaping FlutterResult) {
    let tempDir = NSTemporaryDirectory()
    let fileName = "compressed_\(Int(Date().timeIntervalSince1970)).jpg"
    let filePath = (tempDir as NSString).appendingPathComponent(fileName)
    do {
      try data.write(to: URL(fileURLWithPath: filePath))
      result(filePath)
    } catch {
      result(FlutterError(code: "TEMP_WRITE_FAILED", message: "Không thể ghi file tạm", details: error.localizedDescription))
    }
  }
}

extension UIImage {
  func fixedOrientation() -> UIImage {
    if imageOrientation == .up { return self }
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    draw(in: CGRect(origin: .zero, size: size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return normalizedImage ?? self
  }
}
