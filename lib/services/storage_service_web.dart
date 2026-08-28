// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class PlatformStorage {
  static Future<void> setString(String key, String value) async {
    try {
      html.window.localStorage[key] = value;
    } catch (e) {
      debugPrint('localStorage set error: $e');
    }
  }

  static Future<String?> getString(String key) async {
    try {
      return html.window.localStorage[key];
    } catch (e) {
      debugPrint('localStorage get error: $e');
      return null;
    }
  }

  static Future<void> remove(String key) async {
    try {
      html.window.localStorage.remove(key);
    } catch (e) {
      debugPrint('localStorage remove error: $e');
    }
  }
}
