import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'editor/editor_entry.dart' deferred as editor;

/// Loads the editor as a separate code bundle.
///
/// The editor carries the canvas, the inspectors and the whole Google Fonts
/// catalogue; the home page needs none of it. Splitting it out keeps the
/// first download and the script start-up small, and [preload] fetches it in
/// the background once the home page is up, so opening the editor is instant.
class EditorLoader extends StatelessWidget {
  const EditorLoader({super.key});

  static Future<void>? _loading;
  static bool _loaded = false;

  /// Starts (or joins) the editor download. Safe to call repeatedly.
  static Future<void> preload() => _loading ??= editor.loadLibrary().then((_) => _loaded = true);

  @override
  Widget build(BuildContext context) {
    // Already downloaded (the usual case): no loading frame at all.
    if (_loaded) return editor.buildEditor();
    return FutureBuilder<void>(
      future: preload(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          return editor.buildEditor();
        }
        if (snapshot.hasError) _loading = null; // let the next build retry
        return const _EditorLoading();
      },
    );
  }
}

/// Shown for the moment the editor bundle is still downloading.
class _EditorLoading extends StatelessWidget {
  const _EditorLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.sand,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
        ),
      ),
    );
  }
}
