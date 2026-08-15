import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Chép ảnh hoá đơn vào thư mục riêng của app để ảnh không mất
/// khi người dùng dọn thư viện ảnh.
class ImageService {
  ImageService._();
  static final ImageService instance = ImageService._();

  final ImagePicker _picker = ImagePicker();

  Future<Directory> _receiptsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'receipts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Chụp ảnh hoặc chọn từ thư viện, trả về đường dẫn đã lưu trong app.
  Future<String?> pick(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 2000,
    );
    if (file == null) return null;
    return _persist(file);
  }

  /// Chọn nhiều ảnh cùng lúc từ thư viện.
  Future<List<String>> pickMultiple() async {
    final files = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 2000);
    final saved = <String>[];
    for (final f in files) {
      final path = await _persist(f);
      if (path != null) saved.add(path);
    }
    return saved;
  }

  Future<String?> _persist(XFile file) async {
    try {
      final dir = await _receiptsDir();
      final ext = p.extension(file.path).isEmpty
          ? '.jpg'
          : p.extension(file.path).toLowerCase();
      final name = 'hd_${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = p.join(dir.path, name);
      await File(file.path).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Ảnh có thể đã bị xoá thủ công — bỏ qua.
    }
  }

  bool existsSync(String path) {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
