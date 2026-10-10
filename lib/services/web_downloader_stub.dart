import 'dart:typed_data';

/// Non-web platforms never reach this; see [ExportService.downloadFileWeb].
Future<void> triggerBrowserDownload(Uint8List bytes, String filename, String mimeType) async {}
