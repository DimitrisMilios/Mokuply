import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';

/// Replaces every `SnackBar`. Clay surface, icon tile, one line of text.
///
/// ```dart
/// ClayToast.show(context, 'Saved');
/// ClayToast.show(context, 'Export failed', error: true);
/// ```
///
/// Slides up from the bottom with a bouncy spring, jiggles on arrival, auto
/// dismisses after 3 s. Swipe down or tap to dismiss early. Only one toast
/// is visible at a time; a new one replaces the current.
class ClayToast {
  ClayToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    IconData? icon,
    Duration duration = ClayDurations.toast,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        error: error,
        icon: icon,
        duration: duration,
        onDone: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    final e = _current;
    _current = null;
    if (e != null && e.mounted) e.remove();
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool error;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDone;

  const _ToastWidget({
    required this.message,
    required this.error,
    required this.icon,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with TickerProviderStateMixin {
  late final AnimationController _y; // 0 hidden (below), 1 shown
  late final AnimationController _icon;
  late final AnimationController _sqX;
  late final AnimationController _sqY;
  bool _closing = false;
  double _dragDy = 0;

  @override
  void initState() {
    super.initState();
    _y = AnimationController.unbounded(vsync: this, value: 0);
    _icon = AnimationController.unbounded(vsync: this, value: 0);
    _sqX = AnimationController.unbounded(vsync: this, value: 1.0);
    _sqY = AnimationController.unbounded(vsync: this, value: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final motion = ClayMotion.of(context);
      _y.springTo(1, spring: motion.bouncy).then((_) {
        if (!mounted) return;
        // Jelly on arrival.
        _sqX.value = 1 + motion.squash * 0.5;
        _sqY.value = 1 - motion.squash * 0.5;
        _sqX.springTo(1, spring: motion.liquid);
        Future<void>.delayed(const Duration(milliseconds: 16), () {
          if (mounted) _sqY.springTo(1, spring: motion.liquid);
        });
      });
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _icon.springTo(1, spring: motion.bouncy);
      });
      Future<void>.delayed(widget.duration, _close);
    });
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    final motion = ClayMotion.of(context);
    _y.springTo(0, spring: motion.snappy).then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _y.dispose();
    _icon.dispose();
    _sqX.dispose();
    _sqY.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconData = widget.icon ?? (widget.error ? Icons.close_rounded : Icons.check_rounded);
    final tileColor = widget.error ? AppColors.coral : AppColors.sage;
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: _closing,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_y, _icon, _sqX, _sqY]),
            builder: (context, child) {
              final t = _y.value;
              final hiddenOffset = 120.0;
              return Transform.translate(
                offset: Offset(0, (1 - t) * hiddenOffset + _dragDy),
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(_sqX.value, _sqY.value, 1),
                    child: child,
                  ),
                ),
              );
            },
            child: GestureDetector(
              onTap: _close,
              onVerticalDragUpdate: (d) {
                if (d.delta.dy > 0 || _dragDy > 0) setState(() => _dragDy = (_dragDy + d.delta.dy).clamp(0, 200));
              },
              onVerticalDragEnd: (d) {
                if (_dragDy > 24 || (d.primaryVelocity ?? 0) > 300) {
                  _close();
                } else {
                  setState(() => _dragDy = 0);
                }
              },
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
                  decoration: const ClayDecoration(
                    color: AppColors.clay,
                    radius: AppDimensions.radiusClay,
                    depth: 5,
                    lift: 14,
                    shadowOpacity: 0.24,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _icon,
                        builder: (context, child) => Transform.scale(scale: _icon.value.clamp(0.0, 1.5), child: child),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: ClayDecoration(
                            color: tileColor,
                            radius: 12,
                            depth: 3,
                            lift: 4,
                            shadowOpacity: 0.2,
                            highlightOpacity: 0.6,
                            shadeOpacity: 0.3,
                            shadeColor: widget.error ? AppColors.coralDeep : AppColors.primaryDeep,
                          ),
                          child: Icon(iconData, size: 20, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
