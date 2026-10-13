import 'dart:async';

import '../models/template_data.dart';
import 'storage_service.dart';

/// Saves the open project to browser storage shortly after the last change.
///
/// Debounced: slider drags and typing fire dozens of changes per second, so
/// the draft is serialised once, [delay] after the last one.
class DraftAutosaver {
  final Duration delay;
  Timer? _timer;

  DraftAutosaver({this.delay = const Duration(milliseconds: 700)});

  /// Saves [screens] once no further change arrives within [delay]. The
  /// callback is read when the timer fires, so the latest state is saved.
  void schedule(List<TemplateData> Function() screens) {
    _pending = screens;
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  List<TemplateData> Function()? _pending;

  /// Saves a scheduled draft right away (leaving the editor).
  void flush() {
    _timer?.cancel();
    _timer = null;
    final pending = _pending;
    _pending = null;
    if (pending != null) StorageService.saveActiveDraft(pending());
  }

  void dispose() => _timer?.cancel();
}
