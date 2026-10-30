// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Web implementation using browser HttpRequest with arraybuffer
Future<Uint8List?> fetchBridgePackagePlatform(String url) async {
  try {
    final request = await html.HttpRequest.request(url, responseType: 'arraybuffer');
    if (request.status == 200 && request.response != null) {
      final buffer = request.response as ByteBuffer;
      return Uint8List.view(buffer);
    }
  } catch (e) {
    debugPrint('Bridge fetch error: $e');
  }
  return null;
}
