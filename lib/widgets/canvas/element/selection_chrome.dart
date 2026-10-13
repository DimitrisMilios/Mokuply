import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../clay/clay.dart';

/// Preview-only outline painted UNDER an element's content. It skews with
/// the jelly while dragging and its shadow spreads with [lift]; the content
/// itself is never transformed, so what the user sees is what gets exported.
class SelectionOutline extends StatelessWidget {
  final JellyController jelly;

  /// 0 resting, 1 held (unbounded spring, may overshoot).
  final Animation<double> lift;
  final bool highlighted;
  final double borderWidth;
  final double borderRadius;

  /// Counter-scale so chrome keeps a constant on-screen size.
  final double unit;

  const SelectionOutline({
    super.key,
    required this.jelly,
    required this.lift,
    required this.highlighted,
    required this.borderWidth,
    required this.borderRadius,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: JellyTransform(
        controller: jelly,
        child: AnimatedBuilder(
          animation: lift,
          builder: (context, _) {
            final double t = lift.value.clamp(0.0, 1.3);
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: highlighted ? AppColors.gold : Colors.transparent, width: borderWidth),
                borderRadius: BorderRadius.circular(borderRadius),
                color: highlighted ? AppColors.gold.withValues(alpha: 0.05) : Colors.transparent,
                boxShadow: t > 0.01
                    ? [
                        BoxShadow(
                          color: AppColors.clayShadow.withValues(alpha: 0.18 * t),
                          blurRadius: 26 * unit * t,
                          spreadRadius: 2 * unit * t,
                          offset: Offset(0, 10 * unit * t),
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The live angle shown above an element while its rotate handle is dragged.
class RotationBadge extends StatelessWidget {
  final double degrees;
  final double unit;

  const RotationBadge({super.key, required this.degrees, required this.unit});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Transform.scale(
          scale: unit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${degrees.round()}°',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

/// Right-click menu of a canvas element. Returns the chosen action.
enum ElementMenuAction { duplicate, reset, straighten, delete }

Future<ElementMenuAction?> showElementMenu({
  required BuildContext context,
  required Offset position,
  required bool canDuplicate,
  required bool canStraighten,
  required bool canDelete,
  required bool isHeadline,
}) {
  return showClayMenu<ElementMenuAction>(
    context: context,
    position: position,
    items: [
      if (canDuplicate)
        const ClayMenuItem(value: ElementMenuAction.duplicate, label: 'Duplicate', icon: Icons.content_copy_rounded),
      const ClayMenuItem(
        value: ElementMenuAction.reset,
        label: 'Reset position',
        icon: Icons.center_focus_weak_rounded,
      ),
      if (canStraighten)
        const ClayMenuItem(
          value: ElementMenuAction.straighten,
          label: 'Straighten (0°)',
          icon: Icons.straighten_rounded,
        ),
      if (canDelete)
        ClayMenuItem(
          value: ElementMenuAction.delete,
          label: isHeadline ? 'Clear text' : 'Delete',
          icon: Icons.delete_outline_rounded,
          danger: true,
        ),
    ],
  );
}
