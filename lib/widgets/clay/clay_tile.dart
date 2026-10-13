import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';
import 'clay_pressable.dart';

/// Selectable row/tile (layout presets, frame styles, font rows, layer rows).
/// Raised mint puck when selected, flat on the well when not.
///
/// Selection raises with `bouncy`, deselection lowers with `snappy`.
class ClayTile extends StatefulWidget {
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Surface colour when selected. Defaults to mint.
  final Color selectedColor;

  /// Surface colour when idle. Defaults to transparent (flat on the well).
  /// Pass `AppColors.clay` for a tile that is always a slab.
  final Color? idleColor;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const ClayTile({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.radius = AppDimensions.radiusClaySm,
    this.selectedColor = AppColors.mint,
    this.idleColor,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  State<ClayTile> createState() => _ClayTileState();
}

class _ClayTileState extends State<ClayTile> with SingleTickerProviderStateMixin {
  late final AnimationController _sel;

  @override
  void initState() {
    super.initState();
    _sel = AnimationController.unbounded(vsync: this, value: widget.selected ? 1 : 0);
  }

  @override
  void didUpdateWidget(ClayTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final motion = ClayMotion.of(context);
      _sel.springTo(widget.selected ? 1 : 0, spring: widget.selected ? motion.bouncy : motion.snappy);
    }
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDeco = ClayDecoration(
      color: widget.selectedColor,
      radius: widget.radius,
      depth: 4,
      lift: 10,
      shadowOpacity: 0.16,
      edgeOpacity: 0.08,
    );
    final idleDeco = widget.idleColor == null
        ? selectedDeco.hidden
        : ClayDecoration(
            color: widget.idleColor!,
            radius: widget.radius,
            depth: 4,
            lift: 6,
            shadowOpacity: 0.10,
          );

    return ClayPressable(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      squash: 0.05,
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: widget.child,
      builder: (context, hover, press, child) {
        return AnimatedBuilder(
          animation: _sel,
          child: child,
          builder: (context, child) {
            final t = _sel.value.clamp(0.0, 1.0);
            final h = hover.clamp(0.0, 1.0);
            var deco = ClayDecoration.lerp(idleDeco, selectedDeco, t)!;
            if (t < 0.99 && h > 0) {
              // Hover fill for idle tiles: a faint mint tint, no lift.
              final hoverDeco = idleDeco.copyWith(
                color: Color.lerp(idleDeco.color, AppColors.mint.withValues(alpha: 0.5), h),
              );
              deco = ClayDecoration.lerp(deco, hoverDeco, h * (1 - t))!;
            }
            deco = deco.copyWith(pressed: press.clamp(0.0, 1.0) * 0.5);
            return Container(
              width: widget.width,
              height: widget.height,
              alignment: widget.alignment,
              padding: widget.padding,
              decoration: deco,
              child: child,
            );
          },
        );
      },
    );
  }
}
