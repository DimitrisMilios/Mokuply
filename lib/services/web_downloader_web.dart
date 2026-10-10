// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a client-side browser download of [bytes].
Future<void> triggerBrowserDownload(Uint8List bytes, String filename, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  // Delay revoking the object URL so the browser has time to finish saving.
  Future.delayed(const Duration(seconds: 4), () {
    html.Url.revokeObjectUrl(url);
  });
}
