package vn.lochv.image_compress

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.os.Environment
import android.provider.MediaStore
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.*

class ImageCompressPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "image_compress")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val imageBytes = call.argument<ByteArray>("image")
        val maxSizeLevel = call.argument<Int>("maxSizeLevel") ?: 1
        val maxSizeInKB = call.argument<Int>("maxSizeInKB")
        val maxSize = maxSizeInKB?.times(1024) ?: maxSizeLevel * 1_048_576

        if (imageBytes == null) {
            result.error("INVALID_ARGUMENT", "Image bytes is null", null)
            return
        }

        when (call.method) {
            "compressImage" -> compressImageOrError(imageBytes, maxSize, result)
            "compressAndSaveToGallery" -> compressAndSaveToGallery(imageBytes, maxSize, result)
            "compressAndSaveTempFile" -> compressAndSaveToTempFile(imageBytes, maxSize, result)
            else -> result.notImplemented()
        }
    }

    private fun compressImageOrError(imageBytes: ByteArray, maxSize: Int, result: MethodChannel.Result) {
        val compressed = compressImage(imageBytes, maxSize)
        if (compressed != null) {
            result.success(compressed)
        } else {
            result.error(
                "COMPRESSION_FAILED",
                "❌ Không thể nén ảnh xuống dưới ${maxSize / 1024}KB",
                null
            )
        }
    }

    private fun compressImage(imageBytes: ByteArray, maxSize: Int): ByteArray? {
        val originalBitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: return null

        if (imageBytes.size <= maxSize) return imageBytes

        val rotatedBitmap = rotateIfNeeded(imageBytes, originalBitmap)
        val originalSize = imageBytes.size
        var quality = ((maxSize.toDouble() / originalSize) * 120).toInt().coerceIn(10, 100)
        val minQuality = 10
        val maxAttempts = 20
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

    private fun compressAndSaveToGallery(imageBytes: ByteArray, maxSize: Int, result: MethodChannel.Result) {
        val compressed = compressImage(imageBytes, maxSize)
        if (compressed == null) {
            result.error("COMPRESSION_FAILED", "Không thể nén ảnh", null)
            return
        }

        try {
            val fileName = "compressed_${System.currentTimeMillis()}.jpg"
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Compressed")
            }
            val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            val stream = uri?.let { context.contentResolver.openOutputStream(it) }
            stream?.write(compressed)
            stream?.flush()
            stream?.close()

            result.success(true)
        } catch (e: Exception) {
            result.error("SAVE_FAILED", "Lỗi khi lưu ảnh: ${e.message}", null)
        }
    }

    private fun compressAndSaveToTempFile(imageBytes: ByteArray, maxSize: Int, result: MethodChannel.Result) {
        val compressed = compressImage(imageBytes, maxSize)
        if (compressed == null) {
            result.error("COMPRESSION_FAILED", "Không thể nén ảnh", null)
            return
        }

        try {
            val tempFile = File.createTempFile("compressed_", ".jpg", context.cacheDir)
            val fos = FileOutputStream(tempFile)
            fos.write(compressed)
            fos.flush()
            fos.close()
            result.success(tempFile.absolutePath)
        } catch (e: Exception) {
            result.error("FILE_WRITE_ERROR", "Không thể lưu file: ${e.message}", null)
        }
    }

    private fun rotateIfNeeded(imageBytes: ByteArray, bitmap: Bitmap): Bitmap {
        return try {
            val exif = ExifInterface(ByteArrayInputStream(imageBytes))
            val orientation = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
            )
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> rotateBitmap(bitmap, 90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> rotateBitmap(bitmap, 180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> rotateBitmap(bitmap, 270f)
                else -> bitmap
            }
        } catch (e: Exception) {
            bitmap
        }
    }

    private fun rotateBitmap(source: Bitmap, angle: Float): Bitmap {
        val matrix = Matrix().apply { postRotate(angle) }
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }
}
