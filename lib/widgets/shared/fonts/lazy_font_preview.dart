import 'dart:async';

import 'package:flutter/material.dart';
import '../font_picker_field.dart';

/// Renders [text] in [family], but only after the widget has been on screen
/// for [delay]. Rows that scroll past quickly are disposed before the timer
/// fires, so their font files are never requested.
class LazyFontPreview extends StatefulWidget {
  final String family;
  final String text;
  final double fontSize;
  final FontWeight weight;
  final Color color;
  final Duration delay;

  const LazyFontPreview({
    super.key,
    required this.family,
    required this.text,
    required this.fontSize,
    required this.weight,
    required this.color,
    this.delay = const Duration(milliseconds: 350),
  });

  /// Families whose preview has already been requested; they render at once.
  static final Set<String> _warm = {};

  @override
  State<LazyFontPreview> createState() => _LazyFontPreviewState();
}

class _LazyFontPreviewState extends State<LazyFontPreview> {
  Timer? _timer;
  late bool _ready = LazyFontPreview._warm.contains(widget.family);

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      _timer = Timer(widget.delay, () {
        if (!mounted) return;
        LazyFontPreview._warm.add(widget.family);
        setState(() => _ready = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = _ready
        ? FontPickerField.styleFor(widget.family, fontSize: widget.fontSize, weight: widget.weight, color: widget.color)
        : TextStyle(fontSize: widget.fontSize, fontWeight: widget.weight, color: widget.color.withValues(alpha: 0.45));
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: style,
      child: Text(widget.text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
