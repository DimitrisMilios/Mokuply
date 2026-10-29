import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js_interop';
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

  // --- Binary data (IndexedDB) ---
  //
  // localStorage holds about 5 MB of text; IndexedDB stores bytes as they
  // are, with room for many screenshots.

  static const String _dbName = 'mokuply';
  static const String _store = 'files';
  static Future<_IdbDatabase>? _db;

  static Future<_IdbDatabase> _open() {
    return _db ??= () async {
      final request = _indexedDB.open(_dbName, 1);
      request.onupgradeneeded = ((JSAny _) {
        final db = request.result as _IdbDatabase;
        if (!db.objectStoreNames.contains(_store)) db.createObjectStore(_store);
      }).toJS;
      return await _result(request) as _IdbDatabase;
    }();
  }

  static Future<void> setBytes(String key, Uint8List value) async {
    try {
      final tx = (await _open()).transaction(_store, 'readwrite');
      tx.objectStore(_store).put(value.toJS, key);
      await _completed(tx);
    } catch (e) {
      debugPrint('IndexedDB set error: $e');
    }
  }

  static Future<Uint8List?> getBytes(String key) async {
    try {
      final tx = (await _open()).transaction(_store, 'readonly');
      final value = await _result(tx.objectStore(_store).get(key));
      return value != null && value.isA<JSUint8Array>() ? (value as JSUint8Array).toDart : null;
    } catch (e) {
      debugPrint('IndexedDB get error: $e');
      return null;
    }
  }

  static Future<void> removeBytes(String key) async {
    try {
      final tx = (await _open()).transaction(_store, 'readwrite');
      tx.objectStore(_store).delete(key);
      await _completed(tx);
    } catch (e) {
      debugPrint('IndexedDB remove error: $e');
    }
  }

  static Future<JSAny?> _result(_IdbRequest request) {
    final done = Completer<JSAny?>();
    request.onsuccess = ((JSAny _) => done.complete(request.result)).toJS;
    request.onerror = ((JSAny _) => done.completeError(StateError('${request.error}'))).toJS;
    return done.future;
  }

  static Future<void> _completed(_IdbTransaction tx) {
    final done = Completer<void>();
    tx.oncomplete = ((JSAny _) => done.complete()).toJS;
    tx.onerror = ((JSAny _) => done.completeError(StateError('${tx.error}'))).toJS;
    tx.onabort = ((JSAny _) {
      if (!done.isCompleted) done.completeError(StateError('IndexedDB transaction aborted'));
    }).toJS;
    return done.future;
  }
}

// The few IndexedDB calls used above.

@JS('indexedDB')
external _IdbFactory get _indexedDB;

extension type _IdbFactory._(JSObject _) implements JSObject {
  external _IdbRequest open(String name, int version);
}

extension type _IdbRequest._(JSObject _) implements JSObject {
  external JSAny? get result;
  external JSAny? get error;
  external set onsuccess(JSFunction? handler);
  external set onerror(JSFunction? handler);
  external set onupgradeneeded(JSFunction? handler);
}

extension type _IdbDatabase._(JSObject _) implements JSObject {
  external _DomStringList get objectStoreNames;
  external JSObject createObjectStore(String name);
  external _IdbTransaction transaction(String storeName, String mode);
}

extension type _DomStringList._(JSObject _) implements JSObject {
  external bool contains(String value);
}

extension type _IdbTransaction._(JSObject _) implements JSObject {
  external JSAny? get error;
  external _IdbObjectStore objectStore(String name);
  external set oncomplete(JSFunction? handler);
  external set onerror(JSFunction? handler);
  external set onabort(JSFunction? handler);
}

extension type _IdbObjectStore._(JSObject _) implements JSObject {
  external _IdbRequest put(JSAny? value, String key);
  external _IdbRequest get(String key);
  external _IdbRequest delete(String key);
}
