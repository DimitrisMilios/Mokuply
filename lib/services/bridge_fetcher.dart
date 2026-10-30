import 'dart:typed_data';
import 'bridge_fetcher_stub.dart' if (dart.library.html) 'bridge_fetcher_web.dart';

/// Fetches a Mokuply template bundle from an external bridge URL
class BridgeFetcher {
  static Future<Uint8List?> fetch(String url) => fetchBridgePackagePlatform(url);
}
