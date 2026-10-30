import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../core/layout/layout_anchors.dart';
import '../../models/template_data.dart';

/// Where the phone sits on a starter screen. Every starter set follows the
/// same rhythm so a six-screen strip reads as one story: a headline block at
/// the top (or bottom) and a phone that bleeds off the opposite edge.
///
/// Values are design offset units (X = 1/1000 width, Y = 1/2000 height).
enum Placement {
  /// Phone anchored at the bottom, cropped slightly by the lower edge.
  bleedBottom(LayoutMode.titleTopDeviceBottom, 1.0, 190.0),

  /// Phone anchored at the top (headline below), cropped by the upper edge.
  bleedTop(LayoutMode.titleBottomDeviceTop, 1.0, -170.0),

  /// Phone fully visible in the middle of the screen.
  centered(LayoutMode.deviceCentered, 0.82, 0.0);

  final LayoutMode layout;
  final double scale;
  final double offsetY;
  const Placement(this.layout, this.scale, this.offsetY);
}

/// Typography and backdrop shared by every screen of one starter set.
class StarterStyle {
  /// Breathing room: title nudged down from the edge, subtitle pulled closer to it.
  static const double titleOffsetY = 20.0;
  static const double subtitleOffsetY = -30.0;

  final List<Color> background;
  final Color titleColor;
  final Color subtitleColor;
  final String titleFont;
  final String subtitleFont;
  final double titleSize;
  final double subtitleSize;
  final FontWeight titleWeight;
  final FontWeight subtitleWeight;
  final TargetPlatformType platform;

  const StarterStyle({
    required this.background,
    required this.titleColor,
    required this.subtitleColor,
    required this.titleFont,
    this.subtitleFont = 'Inter',
    required this.titleSize,
    required this.subtitleSize,
    required this.titleWeight,
    required this.subtitleWeight,
    this.platform = TargetPlatformType.appStore,
  });

  /// One screen of the set. [layout], [extraOffsetY] and [rotation] tweak the
  /// placement for hero screens.
  TemplateData screen(
    String title,
    String subtitle,
    Placement placement, {
    LayoutMode? layout,
    double extraOffsetY = 0.0,
    double rotation = 0.0,
  }) {
    return TemplateData(
      platform: platform,
      titleText: title,
      subtitleText: subtitle,
      titleFont: titleFont,
      subtitleFont: subtitleFont,
      titleSize: titleSize,
      subtitleSize: subtitleSize,
      titleWeight: titleWeight,
      subtitleWeight: subtitleWeight,
      textColor: titleColor,
      subtitleColor: subtitleColor,
      textOffsetY: titleOffsetY,
      subtitleOffsetY: subtitleOffsetY,
      customGradientColors: background,
      layoutMode: layout ?? placement.layout,
      deviceScale: placement.scale,
      deviceOffsetY: placement.offsetY + extraOffsetY,
      deviceRotation: rotation,
    );
  }
}

/// Headline placement for left-aligned sets. Text is positioned by its
/// centre, so these turn a left edge and a top edge (design pixels) into the
/// stored offsets. [widestLine] is the measured width of the longest line.
class LeftHeadline {
  LeftHeadline._();

  /// Line height used by the canvas text renderer.
  static const double lineHeight = 1.15;

  static double offsetX({required double left, required double widestLine}) =>
      (left + widestLine / 2 - DesignSpace.width / 2) / DesignSpace.offsetUnitX;

  static double offsetY({required double top, required String text, required double fontSize}) {
    final lines = '\n'.allMatches(text).length + 1;
    final centre = top + lines * fontSize * lineHeight / 2;
    final anchor = LayoutAnchors.forMode(LayoutMode.titleTopDeviceBottom).title * DesignSpace.height;
    return (centre - anchor) / DesignSpace.offsetUnitY;
  }
}
