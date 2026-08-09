import 'dart:typed_data';
import 'desktop_saver_stub.dart'
    if (dart.library.io) 'desktop_saver_io.dart';

class DesktopSaver {
  static Future<String?> saveToDownloads(Uint8List bytes, String filename) {
    return saveFileToDesktop(bytes, filename);
  }
}
