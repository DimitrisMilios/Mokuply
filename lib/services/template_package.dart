import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../models/project_template.dart';
import 'export_service.dart';

/// The downloadable template file: a zip holding `template.json` and every
/// image the screens use (screenshots, backgrounds, image layers), so a
/// project comes back exactly as it was saved.
///
/// Older `.mokuply` files are plain JSON without images and still import.
class TemplatePackage {
  static const String jsonEntry = 'template.json';
  static const String imagesFolder = 'images/';

  static Uint8List encode(ProjectTemplate template) {
    final images = <String, Uint8List>{};
    // A screenshot shared by both stores is the same list; store it once.
    final names = Map<Uint8List, String>.identity();
    String writeAsset(Uint8List bytes) => names.putIfAbsent(bytes, () {
          final name = '$imagesFolder${names.length + 1}.${_extension(bytes)}';
          images[name] = bytes;
          return name;
        });
    final json = utf8.encode(jsonEncode(template.toJson(assets: writeAsset)));
    return ExportService.createZipArchive({jsonEntry: json, ...images});
  }

  /// Reads a template zip or a legacy JSON `.mokuply`.
  /// Throws [FormatException] when [bytes] is neither.
  static ProjectTemplate decode(Uint8List bytes) {
    try {
      if (!_isZip(bytes)) return _fromJson(bytes);
      final archive = ZipDecoder().decodeBytes(bytes);
      // Re-zipping an extracted folder nests everything one level down.
      final entry = archive.files.firstWhere(
        (f) => f.isFile && !f.name.startsWith('__MACOSX/') && f.name.split('/').last == jsonEntry,
        orElse: () => throw const FormatException('No $jsonEntry in the zip'),
      );
      final root = entry.name.substring(0, entry.name.length - jsonEntry.length);
      return _fromJson(entry.content, assets: (ref) => archive.findFile('$root$ref')?.readBytes());
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Not a template file: $e');
    }
  }

  /// Text is UTF-8 (Greek, Cyrillic, emoji...). A leading BOM from editors
  /// such as Notepad would otherwise break `jsonDecode`.
  static ProjectTemplate _fromJson(Uint8List bytes, {Uint8List? Function(String ref)? assets}) {
    var text = utf8.decode(bytes);
    if (text.startsWith('﻿')) text = text.substring(1);
    return ProjectTemplate.fromJson(jsonDecode(text) as Map<String, dynamic>, assets: assets);
  }

  static bool _isZip(Uint8List b) => b.length >= 4 && b[0] == 0x50 && b[1] == 0x4B && b[2] == 0x03 && b[3] == 0x04;

  /// File extension from the image's magic bytes, so the zip opens normally.
  static String _extension(Uint8List b) {
    bool starts(List<int> sig) => b.length >= sig.length && Iterable<int>.generate(sig.length).every((i) => b[i] == sig[i]);
    if (starts(const [0x89, 0x50, 0x4E, 0x47])) return 'png';
    if (starts(const [0xFF, 0xD8, 0xFF])) return 'jpg';
    if (starts(const [0x47, 0x49, 0x46])) return 'gif';
    if (b.length >= 12 && starts(const [0x52, 0x49, 0x46, 0x46]) && b[8] == 0x57 && b[9] == 0x45) return 'webp';
    return 'bin';
  }
}
