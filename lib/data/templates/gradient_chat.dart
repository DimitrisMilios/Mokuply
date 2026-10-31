import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../core/layout/layout_anchors.dart';
import '../../models/project_template.dart';
import '../../models/template_data.dart';
import 'left_headline.dart';

/// One blue-to-magenta gradient that flows across all six screens (each
/// screen takes the next slice), light white captions and frameless phones.
/// Screen 1 opens with a big left-aligned three-word line.
ProjectTemplate gradientChatTemplate() {
  return ProjectTemplate(
    id: 'gradient_chat',
    title: 'Gradient Chat',
    category: 'Communication',
    description: 'A blue-to-magenta gradient that flows across all six screens, light captions and frameless phones.',
    previewGradient: const [Color(0xFF3552D6), Color(0xFF9E50D9), Color(0xFFE5508A)],
    platform: TargetPlatformType.googlePlay,
    initialScreenshots: [
      _ChatScreen.opening(),
      _ChatScreen.centred(1, 'Bring your style\nto every chat'),
      _ChatScreen.centred(2, 'Meet up anytime,\nanywhere'),
      _ChatScreen.centred(3, 'Get quick answers\nfrom your AI helper'),
      _ChatScreen.centred(4, 'Share moments\nwith your circle'),
      _ChatScreen.centred(5, 'Stay in touch\nwith everyone'),
    ],
  );
}

/// Geometry for the gradient set, in design pixels unless noted.
class _ChatScreen {
  _ChatScreen._();

  /// Stops of the strip-wide gradient; screen i runs from stop i to i + 1.
  static const List<Color> stops = [
    Color(0xFF3552D6),
    Color(0xFF4F66EE),
    Color(0xFF7A5CE8),
    Color(0xFF9E50D9),
    Color(0xFFC048C6),
    Color(0xFFD94BA6),
    Color(0xFFE5508A),
  ];

  static const String font = 'Inter';
  static const double captionSize = 94;
  static const double captionTop = 176;

  static List<Color> _slice(int screen) => [stops[screen], stops[screen + 1]];

  /// Screen 1: three short lines, left-aligned and slightly translucent,
  /// over a large phone cropped by the bottom edge.
  static TemplateData opening() {
    const text = 'Fast.\nFun.\nPersonal.';
    const size = 148.0;
    return _screen(
      0,
      text: text,
      size: size,
      color: const Color(0xD9FFFFFF),
      alignment: TextAlign.left,
      offsetX: LeftHeadline.offsetX(left: 200, widestLine: 631),
      top: 165,
      phoneScale: 1.25,
      phoneOffsetY: 244,
    );
  }

  /// Screens 2–6: a centred two-line caption over a phone whose top sits at
  /// 577 px, cropped by the bottom edge.
  static TemplateData centred(int screen, String text) => _screen(
        screen,
        text: text,
        size: captionSize,
        color: Colors.white,
        alignment: TextAlign.center,
        offsetX: 0,
        top: captionTop,
        phoneScale: 1.16,
        phoneOffsetY: -5,
      );

  static TemplateData _screen(
    int screen, {
    required String text,
    required double size,
    required Color color,
    required TextAlign alignment,
    required double offsetX,
    required double top,
    required double phoneScale,
    required double phoneOffsetY,
  }) {
    return TemplateData(
      platform: TargetPlatformType.googlePlay,
      titleText: text,
      subtitleText: '',
      titleFont: font,
      titleSize: size,
      titleWeight: FontWeight.w400,
      textColor: color,
      titleAlignment: alignment,
      textOffsetX: offsetX,
      textOffsetY: LeftHeadline.offsetY(
        top: top,
        text: text,
        fontSize: size,
        anchor: LayoutAnchors.forMode(LayoutMode.titleTopDeviceBottom).title,
      ),
      customGradientColors: _slice(screen),
      layoutMode: LayoutMode.titleTopDeviceBottom,
      frameStyle: DeviceFrameStyle.none,
      deviceScale: phoneScale,
      deviceOffsetY: phoneOffsetY,
    );
  }
}
