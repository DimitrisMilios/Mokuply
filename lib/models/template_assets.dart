import 'package:flutter/foundation.dart';

/// Stores image bytes beside the JSON (in a template zip) and returns the
/// reference written in their place. Without one, `toJson` leaves images
/// out: browser storage is far too small for screenshots.
typedef AssetWriter = String Function(Uint8List bytes);

/// Returns the bytes stored under a reference from an [AssetWriter].
typedef AssetReader = Uint8List? Function(String ref);

/// Bytes for the JSON value [ref], or null when there is no image or reader.
Uint8List? readAsset(Object? ref, AssetReader? assets) => ref is String && assets != null ? assets(ref) : null;
