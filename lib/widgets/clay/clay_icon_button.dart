import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_decoration.dart';
import 'clay_pressable.dart';
import 'jelly_transform.dart';

/// Square clay tile (40 or 44 px) with an icon. Replaces every `IconButton`
/// in the chrome.
///
/// [active] sinks the tile (used by the action rail and toggle-style tools).
/// Pass [image] instead of [icon] for a Blender clay icon; it gets the
/// rotate wobble on hover.
class ClayIconButton extends StatefulWidget {
  final IconData? icon;
  final Widget? image;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool active;
  final Color? iconColor;
  final Color color;
  final double radius;

  /// Flat (no surface) until hovered. For dense rows.
  final bool flat;
  final bool danger;

  const ClayIconButton({
    super.key,
    this.icon,
    this.image,
    this.onPressed,
    this.tooltip,
    this.size = 40,
    this.iconSize = 20,
    this.active = false,
    this.iconColor,
    this.color = AppColors.clay,
    this.radius = AppDimensions.radiusClaySm,
    this.flat = false,
    this.danger = false,
  }) : assert(icon != null || image != null);

  @override
  State<ClayIconButton> createState() => _ClayIconButtonState();
}

class _ClayIconButtonState extends State<ClayIconButton> {
  final _jelly = JellyController();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final baseColor = widget.iconColor ?? (widget.danger ? AppColors.coralDeep : AppColors.textPrimary);

    Widget button = ClayPressable(
      onTap: widget.onPressed,
      enabled: enabled,
      jelly: _jelly,
      builder: (context, hover, press, _) {
        final h = hover.clamp(0.0, 1.0);
        final p = press.clamp(0.0, 1.0);
        if (widget.image != null && h > 0.5 && !_wobbled) {
          _wobbled = true;
          _jelly.wobble(radians: 0.1);
        } else if (h < 0.5) {
          _wobbled = false;
        }

        final ClayDecoration deco;
        if (widget.active) {
          deco = ClayDecoration.well(color: AppColors.clayDeep, radius: widget.radius, depth: 4);
        } else {
          final raised = ClayDecoration(
            color: widget.color,
            radius: widget.radius,
            depth: 4,
            lift: ui.lerpDouble(8, 12, h)!,
            pressed: p,
            shadowOpacity: 0.16,
            edgeOpacity: 0.10,
          );
          deco = widget.flat ? ClayDecoration.lerp(raised.hidden, raised, h)! : raised;
        }

        final iconColor = widget.active ? AppColors.primary : Color.lerp(baseColor, widget.danger ? AppColors.coral : AppColors.primary, h * 0.6)!;

        return Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: deco,
            child: widget.image ??
                Icon(widget.icon, size: widget.iconSize, color: iconColor),
          ),
        );
      },
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }

  bool _wobbled = false;
}
