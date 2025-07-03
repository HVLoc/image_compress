package vn.lochv.image_compress

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class ImageCompressPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "image_compress")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "compressImage") {
            val imageBytes = call.argument<ByteArray>("image")
            val maxSizeInKB = call.argument<Int>("maxSizeInKB")      // Ưu tiên truyền theo KB
            val maxSizeLevel = call.argument<Int>("maxSizeLevel") ?: 1
            val maxSize = maxSizeInKB?.times(1024) ?: (maxSizeLevel * 1_048_576)

            if (imageBytes != null) {
                val compressed = compressImage(imageBytes, maxSize)
                if (compressed != null) {
                    result.success(compressed)
                } else {
                    result.error(
                        "COMPRESSION_FAILED",
                        "Cannot compress image under $maxSize bytes",
                        null
                    )
                }
            } else {
                result.error("INVALID_ARGUMENT", "Image bytes is null", null)
            }
        } else {
            result.notImplemented()
        }
    }

    /**
     * Nén ảnh JPEG sao cho dung lượng đầu ra <= maxSize (bytes)
     */
    private fun compressImage(imageBytes: ByteArray, maxSize: Int): ByteArray? {
        val originalBitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: return null

        // Đọc orientation từ EXIF và xoay ảnh nếu cần
        val exif = ExifInterface(ByteArrayInputStream(imageBytes))
        val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        val rotatedBitmap = when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> rotateBitmap(originalBitmap, 90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> rotateBitmap(originalBitmap, 180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> rotateBitmap(originalBitmap, 270f)
            else -> originalBitmap
        }

        val originalSize = imageBytes.size
        var quality = ((maxSize.toDouble() / originalSize) * 120).toInt().coerceIn(10, 100)
        val minQuality = 10
        val maxAttempts = 10
        var attempt = 0
        var compressedBytes: ByteArray

        do {
            val outputStream = ByteArrayOutputStream()
            rotatedBitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
            compressedBytes = outputStream.toByteArray()
            quality -= 5
            attempt++
        } while (compressedBytes.size > maxSize && quality > minQuality && attempt < maxAttempts)

        return if (compressedBytes.size <= maxSize) compressedBytes else null
    }

    /**
     * Xoay ảnh bitmap theo góc angle (độ)
     */
    private fun rotateBitmap(source: Bitmap, angle: Float): Bitmap {
        val matrix = Matrix().apply { postRotate(angle) }
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }
}

