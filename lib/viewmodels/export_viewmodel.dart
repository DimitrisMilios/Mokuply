import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/constants/store_specs.dart';
import '../services/export_service.dart';
import '../services/screen_renderer.dart';
import 'editor/editor_viewmodel.dart';

/// Renders the open project to store PNGs and zips them, reporting progress.
///
/// Kept apart from [EditorViewModel] so progress updates only rebuild the
/// widgets that show them, not the canvas.
class ExportViewModel extends ChangeNotifier {
  ExportViewModel({required EditorViewModel editor}) : _editor = editor;

  final EditorViewModel _editor;

  bool _isExporting = false;
  int _progressIndex = 0;
  int _totalSteps = 1;
  String _statusText = '';

  bool get isExporting => _isExporting;
  int get progressIndex => _progressIndex;
  int get totalSteps => _totalSteps;
  String get statusText => _statusText;

  /// 0..1 share of screens rendered.
  double get progress => _totalSteps > 0 ? (_progressIndex / _totalSteps).clamp(0.0, 1.0) : 0.0;

  /// Exports one store as a ZIP bundle (both stores share the 1320×2868 canvas).
  Future<void> exportPlatformPack(TargetPlatformType target, {required BuildContext context}) {
    return _run(_editor.screenshotsCount, 'Preparing screenshots...', () async {
      final files = await _renderStore(target, context, progressOffset: 0);
      await _downloadZip(files, 'Mockuply_${target.exportFolderName}.zip', 'Packaging 100% lossless ZIP archive...');
    });
  }

  /// Exports both stores in one ZIP bundle. The export dialog keeps the
  /// editor mounted for the whole run, so [context] stays valid between stores.
  Future<void> exportBothPlatformsPack({required BuildContext context}) {
    final count = _editor.screenshotsCount;
    return _run(count * 2, 'Preparing store bundles...', () async {
      final files = await _renderStore(TargetPlatformType.appStore, context, progressOffset: 0);
      // ignore: use_build_context_synchronously
      files.addAll(await _renderStore(TargetPlatformType.googlePlay, context, progressOffset: count));
      await _downloadZip(
        files,
        'Mockuply_StoreScreenshots_AllPlatforms.zip',
        'Packaging complete dual-store ZIP bundle...',
      );
    });
  }

  Future<Map<String, Uint8List>> _renderStore(
    TargetPlatformType target,
    BuildContext context, {
    required int progressOffset,
  }) async {
    final screens = _editor.screenshots;
    final files = <String, Uint8List>{};
    for (int i = 0; i < screens.length; i++) {
      _report(progressOffset + i + 1, 'Rendering ${target.shortName} screen #${i + 1} of ${screens.length}...');
      // Let the progress frame paint before the render blocks the thread.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // ignore: use_build_context_synchronously
      files[ScreenRenderer.zipPath(target, i)] = await ScreenRenderer.renderPng(screens[i], target, context);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    return files;
  }

  Future<void> _downloadZip(Map<String, Uint8List> files, String filename, String status) async {
    _report(_progressIndex, status);
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await ExportService.downloadFileWeb(
      bytes: ExportService.createZipArchive(files),
      filename: filename,
      mimeType: 'application/zip',
    );
  }

  Future<void> _run(int totalSteps, String preparingText, Future<void> Function() body) async {
    _isExporting = true;
    _totalSteps = totalSteps;
    _report(0, preparingText);
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      await body();
    } finally {
      _isExporting = false;
      _report(0, '');
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _report(int index, String status) {
    // Leaving the editor mid-export disposes this view model.
    if (_disposed) return;
    _progressIndex = index;
    _statusText = status;
    notifyListeners();
  }
}
