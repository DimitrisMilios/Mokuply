import 'dart:io';
import 'dart:typed_data';

Future<String?> saveFileToDesktop(Uint8List bytes, String filename) async {
  try {
    final String userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    final String downloadsPath = '$userHome${Platform.pathSeparator}Downloads';
    final Directory downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final String fullPath = '$downloadsPath${Platform.pathSeparator}$filename';
    final File file = File(fullPath);
    await file.writeAsBytes(bytes);
    return fullPath;
  } catch (_) {
    return null;
  }
}
