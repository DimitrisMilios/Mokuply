import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';

/// The clay surface. Paints, inside a rounded rect:
///
/// 1. an outer floating shadow (object floats), skipped when [sunken];
/// 2. the fill;
/// 3. an inner highlight top-left and an inner shade bottom-right
///    (object is thick). When [pressed] or [sunken] the pair swaps sides.
///
/// Every parameter lerps, so it works with `DecorationTween`,
/// `AnimatedContainer`, and the spring-driven controls in the kit.
///
/// Performance: blur radii are constant. Hover and press animate [lift],
/// [pressed] and opacities only, never the blur.
class ClayDecoration extends Decoration {
  final Color color;
  final double radius;

  /// Inner shadow offset. Larger reads as thicker clay.
  final double depth;

  /// Outer shadow y offset. Larger reads as floating higher.
  final double lift;

  /// 0..1. At 1 the lift collapses to 2, inner shadows swap, fill darkens 6 %.
  final double pressed;

  /// Inset well: no outer shadow, shade on top-left, highlight bottom-right.
  final bool sunken;

  final double shadowOpacity;
  final double highlightOpacity;
  final double shadeOpacity;

  /// Opacity of the tight second shadow (blur 8, offset 4) that makes the
  /// bottom edge of raised buttons read. 0 disables it.
  final double edgeOpacity;

  final Color highlightColor;
  final Color shadeColor;
  final Color shadowColor;

  /// Surface ripple time in seconds since the last poke. Negative or zero
  /// means no ripple. Only large surfaces should use this.
  final double rippleTime;
  final double rippleAmp;

  const ClayDecoration({
    this.color = AppColors.clay,
    this.radius = AppDimensions.radiusClay,
    this.depth = AppDimensions.clayDepth,
    this.lift = AppDimensions.clayLift,
    this.pressed = 0.0,
    this.sunken = false,
    this.shadowOpacity = 0.20,
    this.highlightOpacity = 0.9,
    this.shadeOpacity = 0.16,
    this.edgeOpacity = 0.0,
    this.highlightColor = AppColors.clayLight,
    this.shadeColor = AppColors.clayShade,
    this.shadowColor = AppColors.clayShadow,
    this.rippleTime = -1,
    this.rippleAmp = 3.0,
  });

  /// A raised surface in brand green with lighter highlight / darker shade.
  const ClayDecoration.primary({
    this.radius = AppDimensions.radiusClay,
    this.depth = 5,
    this.lift = 14,
    this.pressed = 0.0,
    this.rippleTime = -1,
    this.rippleAmp = 3.0,
    this.edgeOpacity = 0.25,
  })  : color = AppColors.primary,
        sunken = false,
        shadowOpacity = 0.28,
        highlightOpacity = 0.55,
        shadeOpacity = 0.55,
        highlightColor = AppColors.primaryLight,
        shadeColor = AppColors.primaryDeep,
        shadowColor = AppColors.primaryDeep;

  /// A raised surface in gold.
  const ClayDecoration.gold({
    this.radius = AppDimensions.radiusClay,
    this.depth = 5,
    this.lift = 14,
    this.pressed = 0.0,
    this.rippleTime = -1,
    this.rippleAmp = 3.0,
    this.edgeOpacity = 0.25,
  })  : color = AppColors.gold,
        sunken = false,
        shadowOpacity = 0.30,
        highlightOpacity = 0.75,
        shadeOpacity = 0.6,
        highlightColor = AppColors.goldLight,
        shadeColor = AppColors.goldDeep,
        shadowColor = AppColors.goldDeep;

  /// A raised surface in coral (danger).
  const ClayDecoration.danger({
    this.radius = AppDimensions.radiusClay,
    this.depth = 5,
    this.lift = 14,
    this.pressed = 0.0,
    this.rippleTime = -1,
    this.rippleAmp = 3.0,
    this.edgeOpacity = 0.25,
  })  : color = AppColors.coral,
        sunken = false,
        shadowOpacity = 0.30,
        highlightOpacity = 0.6,
        shadeOpacity = 0.6,
        highlightColor = const Color(0xFFFFC2B8),
        shadeColor = AppColors.coralDeep,
        shadowColor = AppColors.coralDeep;

  /// A sunken well.
  const ClayDecoration.well({
    this.color = AppColors.clayDeep,
    this.radius = AppDimensions.radiusClaySm,
    this.depth = 5,
    this.shadeOpacity = 0.14,
    this.highlightOpacity = 0.8,
  })  : lift = 0,
        pressed = 0,
        sunken = true,
        shadowOpacity = 0,
        edgeOpacity = 0,
        highlightColor = AppColors.clayLight,
        shadeColor = AppColors.clayShade,
        shadowColor = AppColors.clayShadow,
        rippleTime = -1,
        rippleAmp = 0;

  /// An invisible decoration with the same shape, for lerping a surface
  /// in and out (idle tiles, hover fills).
  ClayDecoration get hidden => copyWith(
        color: color.withValues(alpha: 0),
        lift: 0,
        shadowOpacity: 0,
        highlightOpacity: 0,
        shadeOpacity: 0,
        edgeOpacity: 0,
      );

  ClayDecoration copyWith({
    Color? color,
    double? radius,
    double? depth,
    double? lift,
    double? pressed,
    bool? sunken,
    double? shadowOpacity,
    double? highlightOpacity,
    double? shadeOpacity,
    double? edgeOpacity,
    Color? highlightColor,
    Color? shadeColor,
    Color? shadowColor,
    double? rippleTime,
    double? rippleAmp,
  }) {
    return ClayDecoration(
      color: color ?? this.color,
      radius: radius ?? this.radius,
      depth: depth ?? this.depth,
      lift: lift ?? this.lift,
      pressed: pressed ?? this.pressed,
      sunken: sunken ?? this.sunken,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      highlightOpacity: highlightOpacity ?? this.highlightOpacity,
      shadeOpacity: shadeOpacity ?? this.shadeOpacity,
      edgeOpacity: edgeOpacity ?? this.edgeOpacity,
      highlightColor: highlightColor ?? this.highlightColor,
      shadeColor: shadeColor ?? this.shadeColor,
      shadowColor: shadowColor ?? this.shadowColor,
      rippleTime: rippleTime ?? this.rippleTime,
      rippleAmp: rippleAmp ?? this.rippleAmp,
    );
  }

  static ClayDecoration? lerp(ClayDecoration? a, ClayDecoration? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!.hidden._lerpTo(b, t);
    if (b == null) return a._lerpTo(a.hidden, t);
    return a._lerpTo(b, t);
  }

  ClayDecoration _lerpTo(ClayDecoration b, double t) {
    return ClayDecoration(
      color: Color.lerp(color, b.color, t)!,
      radius: ui.lerpDouble(radius, b.radius, t)!,
      depth: ui.lerpDouble(depth, b.depth, t)!,
      lift: ui.lerpDouble(lift, b.lift, t)!,
      pressed: ui.lerpDouble(pressed, b.pressed, t)!,
      sunken: t < 0.5 ? sunken : b.sunken,
      shadowOpacity: ui.lerpDouble(shadowOpacity, b.shadowOpacity, t)!,
      highlightOpacity: ui.lerpDouble(highlightOpacity, b.highlightOpacity, t)!,
      shadeOpacity: ui.lerpDouble(shadeOpacity, b.shadeOpacity, t)!,
      edgeOpacity: ui.lerpDouble(edgeOpacity, b.edgeOpacity, t)!,
      highlightColor: Color.lerp(highlightColor, b.highlightColor, t)!,
      shadeColor: Color.lerp(shadeColor, b.shadeColor, t)!,
      shadowColor: Color.lerp(shadowColor, b.shadowColor, t)!,
      rippleTime: t < 0.5 ? rippleTime : b.rippleTime,
      rippleAmp: ui.lerpDouble(rippleAmp, b.rippleAmp, t)!,
    );
  }

  @override
  ClayDecoration? lerpFrom(Decoration? a, double t) {
    if (a is ClayDecoration?) return ClayDecoration.lerp(a, this, t);
    return super.lerpFrom(a, t) as ClayDecoration?;
  }

  @override
  ClayDecoration? lerpTo(Decoration? b, double t) {
    if (b is ClayDecoration?) return ClayDecoration.lerp(this, b, t);
    return super.lerpTo(b, t) as ClayDecoration?;
  }

  @override
  EdgeInsetsGeometry get padding => EdgeInsets.zero;

  @override
  bool get isComplex => true;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) {
    return Path()..addRRect(_rrect(rect));
  }

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) {
    return _rrect(Offset.zero & size).contains(position);
  }

  RRect _rrect(Rect rect) {
    final r = math.min(radius, math.min(rect.width, rect.height) / 2);
    return RRect.fromRectAndRadius(rect, Radius.circular(r));
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _ClayBoxPainter(this, onChanged);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClayDecoration &&
        other.color == color &&
        other.radius == radius &&
        other.depth == depth &&
        other.lift == lift &&
        other.pressed == pressed &&
        other.sunken == sunken &&
        other.shadowOpacity == shadowOpacity &&
        other.highlightOpacity == highlightOpacity &&
        other.shadeOpacity == shadeOpacity &&
        other.edgeOpacity == edgeOpacity &&
        other.highlightColor == highlightColor &&
        other.shadeColor == shadeColor &&
        other.shadowColor == shadowColor &&
        other.rippleTime == rippleTime &&
        other.rippleAmp == rippleAmp;
  }

  @override
  int get hashCode => Object.hash(color, radius, depth, lift, pressed, sunken, shadowOpacity, highlightOpacity,
      shadeOpacity, edgeOpacity, highlightColor, shadeColor, shadowColor, rippleTime, rippleAmp);
}

class _ClayBoxPainter extends BoxPainter {
  final ClayDecoration d;

  _ClayBoxPainter(this.d, VoidCallback? onChanged) : super(onChanged);

  static const double _outerSigma = 14.0; // ~ blur 28
  static const double _edgeSigma = 4.0; // ~ blur 8

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    final rect = offset & size;
    final shape = _shapePath(rect);

    final press = d.pressed.clamp(0.0, 1.0);
    // 0 = raised lighting, 1 = inverted lighting.
    final invert = d.sunken ? 1.0 : press;

    // 1. Outer shadows (object floats). Skipped on wells.
    if (!d.sunken && d.shadowOpacity > 0.001) {
      final lift = ui.lerpDouble(d.lift, 2.0, press)!;
      final opacity = d.shadowOpacity * (1 - 0.6 * press);
      final shadowPaint = Paint()
        ..color = d.shadowColor.withValues(alpha: opacity.clamp(0, 1))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _outerSigma);
      canvas.drawPath(shape.shift(Offset(0, lift)), shadowPaint);

      if (d.edgeOpacity > 0.001) {
        final edgePaint = Paint()
          ..color = d.shadowColor.withValues(alpha: (d.edgeOpacity * (1 - press)).clamp(0, 1))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _edgeSigma);
        canvas.drawPath(shape.shift(Offset(0, ui.lerpDouble(4, 1, press)!)), edgePaint);
      }
    }

    // 2. Fill. Darkens 6 % when pressed.
    final fill = press > 0 ? Color.lerp(d.color, _darken(d.color, 0.06), press)! : d.color;
    canvas.drawPath(shape, Paint()..color = fill);

    // 3. Inner lighting. Clip to the shape and stroke an offset copy; only the
    //    part inside the clip survives, which gives the inset shadow look.
    final depth = d.depth;
    if (depth > 0.01 && (d.highlightOpacity > 0.001 || d.shadeOpacity > 0.001)) {
      final offsetAmount = depth * (1 - 2 * invert); // +depth raised, -depth inverted
      canvas.save();
      canvas.clipPath(shape, doAntiAlias: true);

      final strokeWidth = depth * 2;

      if (d.highlightOpacity > 0.001) {
        final highlight = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = d.highlightColor.withValues(alpha: d.highlightOpacity.clamp(0, 1))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth);
        canvas.drawPath(shape.shift(Offset(-offsetAmount, -offsetAmount)), highlight);
      }
      if (d.shadeOpacity > 0.001) {
        final shade = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = d.shadeColor.withValues(alpha: d.shadeOpacity.clamp(0, 1))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth);
        canvas.drawPath(shape.shift(Offset(offsetAmount, offsetAmount)), shade);
      }
      canvas.restore();
    }
  }

  Path _shapePath(Rect rect) {
    final r = math.min(d.radius, math.min(rect.width, rect.height) / 2);
    if (d.rippleTime <= 0 || d.rippleAmp <= 0) {
      return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
    }
    // Surface ripple: nudge each corner by a damped sine, alternating sign so
    // the outline wobbles rather than scales.
    final a = rippleAt(d.rippleTime, amp: d.rippleAmp);
    final b = rippleAt(d.rippleTime + 0.08, amp: d.rippleAmp);
    final l = rect.left + a;
    final t = rect.top - b;
    final rr = rect.right - a;
    final bt = rect.bottom + b;
    final wobbled = Rect.fromLTRB(l, t, rr, bt);
    final rad = math.min(r + a, math.min(wobbled.width, wobbled.height) / 2);
    return Path()..addRRect(RRect.fromRectAndRadius(wobbled, Radius.circular(rad)));
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
