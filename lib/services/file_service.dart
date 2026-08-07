import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Abstraction over file picking for testability.
class FileService {
  /// Opens the platform file picker for images and returns raw bytes.
  /// Returns null if the user cancels or no data is available.
  static Future<Uint8List?> pickImageBytes() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files.single.bytes;
      }
    } catch (e) {
      debugPrint('FileService.pickImageBytes error: $e');
    }
    return null;
  }
}
