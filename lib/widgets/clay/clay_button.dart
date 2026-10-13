import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_decoration.dart';
import 'clay_pressable.dart';
import 'jelly_transform.dart';

enum ClayButtonVariant { primary, gold, neutral, danger }

enum ClayButtonSize { compact, regular, large }

/// Pill clay button. Press sinks, release wobbles. Icon + label.
///
/// Variants: `primary` (green clay), `gold`, `neutral` (clay colour),
/// `danger` (coral). Use [ClayButton.text] for a flat text button with no
/// surface (coral text for destructive actions).
class ClayButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final ClayButtonVariant variant;
  final ClayButtonSize size;
  final bool expand;
  final bool busy;

  /// Replaces the label while [busy] is true.
  final String? busyLabel;

  /// Surface ripple on release (home page hero buttons).
  final bool ripple;

  final Color? textColor;

  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.variant = ClayButtonVariant.primary,
    this.size = ClayButtonSize.regular,
    this.expand = false,
    this.busy = false,
    this.busyLabel,
    this.ripple = false,
    this.textColor,
  });

  const ClayButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.size = ClayButtonSize.regular,
    this.expand = false,
    this.busy = false,
    this.busyLabel,
    this.ripple = false,
    this.textColor,
  }) : variant = ClayButtonVariant.primary;

  const ClayButton.gold({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.size = ClayButtonSize.regular,
    this.expand = false,
    this.busy = false,
    this.busyLabel,
    this.ripple = false,
    this.textColor,
  }) : variant = ClayButtonVariant.gold;

  const ClayButton.neutral({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.size = ClayButtonSize.regular,
    this.expand = false,
    this.busy = false,
    this.busyLabel,
    this.ripple = false,
    this.textColor,
  }) : variant = ClayButtonVariant.neutral;

  const ClayButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.size = ClayButtonSize.regular,
    this.expand = false,
    this.busy = false,
    this.busyLabel,
    this.ripple = false,
    this.textColor,
  }) : variant = ClayButtonVariant.danger;

  /// Flat text button, no surface. Pass `danger: true` for coral.
  static Widget text({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool danger = false,
    bool expand = false,
    ClayButtonSize size = ClayButtonSize.regular,
    Color? color,
  }) {
    return ClayTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      icon: icon,
      danger: danger,
      expand: expand,
      size: size,
      color: color,
    );
  }

  double get _height => switch (size) {
        ClayButtonSize.compact => 36,
        ClayButtonSize.regular => 44,
        ClayButtonSize.large => 56,
      };

  double get _fontSize => switch (size) {
        ClayButtonSize.compact => AppDimensions.fontSm,
        ClayButtonSize.regular => AppDimensions.fontMd,
        ClayButtonSize.large => 16,
      };

  EdgeInsets get _padding => switch (size) {
        ClayButtonSize.compact => const EdgeInsets.symmetric(horizontal: 14),
        ClayButtonSize.regular => const EdgeInsets.symmetric(horizontal: 20),
        ClayButtonSize.large => const EdgeInsets.symmetric(horizontal: 28),
      };

  ClayDecoration _decoration(double hover, double press, double rippleTime) {
    final lift = ui.lerpDouble(14.0, 20.0, hover.clamp(0, 1))!;
    final r = _height / 2;
    return switch (variant) {
      ClayButtonVariant.primary =>
        ClayDecoration.primary(radius: r, lift: lift, pressed: press, rippleTime: rippleTime),
      ClayButtonVariant.gold => ClayDecoration.gold(radius: r, lift: lift, pressed: press, rippleTime: rippleTime),
      ClayButtonVariant.danger =>
        ClayDecoration.danger(radius: r, lift: lift, pressed: press, rippleTime: rippleTime),
      ClayButtonVariant.neutral => ClayDecoration(
          radius: r,
          depth: 5,
          lift: lift,
          pressed: press,
          edgeOpacity: 0.12,
          rippleTime: rippleTime,
        ),
    };
  }

  Color get _foreground {
    if (textColor != null) return textColor!;
    return switch (variant) {
      ClayButtonVariant.primary => AppColors.textOnPrimary,
      ClayButtonVariant.gold => AppColors.textPrimary,
      ClayButtonVariant.danger => Colors.white,
      ClayButtonVariant.neutral => AppColors.textPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final fg = _foreground;
    final iconSize = size == ClayButtonSize.compact ? 16.0 : 18.0;

    final labelWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Text(
        busy ? (busyLabel ?? label) : label,
        key: ValueKey(busy),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: _fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1.1,
        ),
      ),
    );

    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          ),
          const SizedBox(width: 10),
        ] else if (leading != null) ...[
          leading!,
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(child: labelWidget),
      ],
    );

    return Opacity(
      opacity: enabled || busy ? 1 : 0.55,
      child: ClayPressable(
        onTap: enabled ? onPressed : null,
        enabled: enabled,
        surfaceRipple: ripple,
        child: row,
        builder: (context, hover, press, child) {
          final rippleTime = ripple ? JellyRipple.of(context) : -1.0;
          return Transform.scale(
            scale: 1 + 0.02 * hover.clamp(0, 1) - 0.04 * press.clamp(0, 1),
            child: Container(
              height: _height,
              padding: _padding,
              decoration: _decoration(hover, press.clamp(0, 1), rippleTime),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Flat text button with no surface. Press still squashes.
class ClayTextButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool danger;
  final bool expand;
  final ClayButtonSize size;
  final Color? color;

  const ClayTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.danger = false,
    this.expand = false,
    this.size = ClayButtonSize.regular,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final base = color ?? (danger ? AppColors.coralDeep : AppColors.textSecondary);
    final fontSize = size == ClayButtonSize.compact ? AppDimensions.fontSm : AppDimensions.fontMd;
    final height = size == ClayButtonSize.compact ? 32.0 : 40.0;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: ClayPressable(
        onTap: onPressed,
        squash: 0.06,
        builder: (context, hover, press, _) {
          final fg = Color.lerp(base, danger ? AppColors.coral : AppColors.primary, hover.clamp(0, 1))!;
          return Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: (danger ? AppColors.coral : AppColors.mint).withValues(alpha: 0.35 * hover.clamp(0, 1)),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
