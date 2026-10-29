import 'dart:typed_data';

class PlatformStorage {
  static final Map<String, String> _memoryStore = {};
  static final Map<String, Uint8List> _bytesStore = {};

  static Future<void> setString(String key, String value) async {
    _memoryStore[key] = value;
  }

  static Future<String?> getString(String key) async {
    return _memoryStore[key];
  }

  static Future<void> remove(String key) async {
    _memoryStore.remove(key);
  }

  static Future<void> setBytes(String key, Uint8List value) async {
    _bytesStore[key] = value;
  }

  static Future<Uint8List?> getBytes(String key) async {
    return _bytesStore[key];
  }

  static Future<void> removeBytes(String key) async {
    _bytesStore.remove(key);
  }
}
