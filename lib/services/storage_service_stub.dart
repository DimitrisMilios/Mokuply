class PlatformStorage {
  static final Map<String, String> _memoryStore = {};

  static Future<void> setString(String key, String value) async {
    _memoryStore[key] = value;
  }

  static Future<String?> getString(String key) async {
    return _memoryStore[key];
  }

  static Future<void> remove(String key) async {
    _memoryStore.remove(key);
  }
}
