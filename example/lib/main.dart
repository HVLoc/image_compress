import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_compress/image_compress.dart'; // plugin bạn đã tạo
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Compress & Save',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ImageCompressPage(),
    );
  }
}

class ImageCompressPage extends StatefulWidget {
  const ImageCompressPage({super.key});

  @override
  State<ImageCompressPage> createState() => _ImageCompressPageState();
}

class _ImageCompressPageState extends State<ImageCompressPage> {
  Uint8List? _originalImage;
  Uint8List? _compressedImage;
  Duration? _compressDuration;
  final TextEditingController _sizeController =
      TextEditingController(text: '1');
  bool _isKB = false;

  Future<void> _handleImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();

      final rawValue = _sizeController.text.trim();
      final sizeValue = int.tryParse(rawValue);

      if (sizeValue == null || sizeValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Vui lòng nhập dung lượng hợp lệ")),
        );
        return;
      }

      final stopwatch = Stopwatch()..start();
      try {
        final compressedBytes = await ImageCompress.compressImage(
          imageBytes: imageBytes,
          maxSizeInKB: _isKB ? sizeValue : null,
          maxSizeLevel: _isKB ? 1 : sizeValue, // fallback nếu không chọn KB
        );
        setState(() {
          _originalImage = imageBytes;
          _compressedImage = compressedBytes;
          _compressDuration = stopwatch.elapsed;
        });
      } on PlatformException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Lỗi: ${e.code} - ${e.message}")));
      }

      stopwatch.stop();
    }
  }

  Future<void> _saveCompressedImage() async {
    if (_compressedImage == null) return;

    if (await _requestSavePermission()) {
      final result = await ImageGallerySaverPlus.saveImage(
        _compressedImage!,
        name: "compressed_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true || result['filePath'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã lưu ảnh vào thư viện")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Lưu ảnh thất bại")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Không được cấp quyền lưu ảnh")),
      );
    }
  }

  Widget _buildImageView(Uint8List? bytes, String label) {
    if (bytes == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 5,
            child: Image.memory(bytes),
          ),
        ),
        Text("Kích thước: ${bytes.lengthInBytes ~/ 1024} KB"),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    final milliseconds = duration.inMilliseconds % 1000;
    return '${seconds}s ${milliseconds}ms';
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Compress & Save')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sizeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _isKB
                          ? 'Giới hạn dung lượng (KB)'
                          : 'Giới hạn dung lượng (MB)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text("KB"),
                    Switch(
                      value: _isKB,
                      onChanged: (value) {
                        setState(() {
                          _isKB = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Chọn từ Gallery'),
                  onPressed: () => _handleImage(ImageSource.gallery),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp ảnh'),
                  onPressed: () => _handleImage(ImageSource.camera),
                ),
                if (_compressedImage != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Lưu ảnh đã nén'),
                    onPressed: _saveCompressedImage,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildImageView(_originalImage, "Ảnh gốc"),
            _buildImageView(_compressedImage, "Ảnh đã nén"),
            if (_compressDuration != null)
              Text("⏱ Thời gian nén: ${_formatDuration(_compressDuration!)}"),
          ],
        ),
      ),
    );
  }

  Future<bool> _requestSavePermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final photos = await Permission.photos.request();
      final storage = await Permission.storage.request();
      return photos.isGranted || storage.isGranted;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final status = await Permission.photosAddOnly.request();
      return status.isGranted;
    }
    return false;
  }
}
