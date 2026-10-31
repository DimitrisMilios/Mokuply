import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../core/layout/layout_anchors.dart';
import '../../models/canvas_device_item.dart';
import '../../models/project_template.dart';
import '../../models/template_data.dart';
import 'left_headline.dart';

/// Airy light-blue set: a big blue keyword over a dark navy second line,
/// opening with two tilted phones that span screens 1 and 2, then upright
/// phones for boards, messaging and scheduling. The default project.
ProjectTemplate teamOrganizeTemplate() {
  return ProjectTemplate(
    id: 'team_organize',
    title: 'Team Task & Workflow Hub',
    category: 'Productivity',
    description: 'Airy light-blue set with big blue keywords, a two-phone angled hero and upright phones after it.',
    previewGradient: _TeamScreen.background,
    previewImage: 'assets/template_previews/team_organize.webp',
    platform: TargetPlatformType.appStore,
    initialScreenshots: [
      // 1. Left-aligned headline; the first tilted phone, with the second
      //    phone's corner entering from the right edge on top of it.
      _TeamScreen.build(
        title: 'Organize',
        subtitle: 'Your company.',
        titleWidth: 739,
        subtitleWidth: 740,
        devices: const [
          CanvasDeviceItem(
            id: 'dev_team_first',
            scale: _TeamScreen.firstScale,
            offsetX: _TeamScreen.firstOffsetX,
            offsetY: _TeamScreen.firstOffsetY,
            rotation: _TeamScreen.firstRotation,
          ),
          CanvasDeviceItem(
            id: 'dev_team_second',
            scale: _TeamScreen.secondScale,
            offsetX: _TeamScreen.secondOffsetX + 1000,
            offsetY: _TeamScreen.secondOffsetY,
            rotation: _TeamScreen.secondRotation,
          ),
        ],
      ),
      // 2. No headline: the large second phone, with the first phone's corner
      //    entering from the left edge behind it.
      _TeamScreen.build(
        devices: const [
          CanvasDeviceItem(
            id: 'dev_team_first',
            scale: _TeamScreen.firstScale,
            offsetX: _TeamScreen.firstOffsetX - 1000,
            offsetY: _TeamScreen.firstOffsetY,
            rotation: _TeamScreen.firstRotation,
          ),
          CanvasDeviceItem(
            id: 'dev_team_second',
            scale: _TeamScreen.secondScale,
            offsetX: _TeamScreen.secondOffsetX,
            offsetY: _TeamScreen.secondOffsetY,
            rotation: _TeamScreen.secondRotation,
          ),
        ],
      ),
      // 3–6. Centred keyword and second line over an upright phone.
      _TeamScreen.build(title: 'Stay', subtitle: 'connected'),
      _TeamScreen.build(title: 'Edit', subtitle: 'campaigns'),
      _TeamScreen.build(title: 'Keep', subtitle: 'your schedule'),
      _TeamScreen.build(title: 'Track', subtitle: 'your success'),
    ],
  );
}

/// Geometry for the team set, in design pixels unless noted. Headline widths
/// are measured for Poppins at the sizes below.
class _TeamScreen {
  _TeamScreen._();

  static const List<Color> background = [Color(0xFFF7F9FC), Color(0xFFEEF3FA), Color(0xFFE2EAF6)];
  static const Color titleColor = Color(0xFF2F6FE0);
  static const Color subtitleColor = Color(0xFF141A4A);
  static const String font = 'Poppins';
  static const double titleSize = 160;
  static const double subtitleSize = 100;

  /// Left edge of the screen 1 headline, and the top edges of both lines.
  static const double textLeft = 137;
  static const double titleTop = 120;
  static const double subtitleTop = 312;

  /// Upright phone, centred, top at 572 px and fully visible (offset units).
  static const double uprightScale = 1.08;
  static const double uprightOffsetY = -66;

  /// First tilted phone: top-left corner a third of the way down screen 1's
  /// left side, running off the right and bottom edges (offset units).
  static const double firstScale = 1.03;
  static const double firstOffsetX = 260;
  static const double firstOffsetY = -64;
  static const double firstRotation = -23;

  /// Second tilted phone: large, tilted the other way, filling screen 2.
  static const double secondScale = 1.37;
  static const double secondOffsetX = -52;
  static const double secondOffsetY = -67;
  static const double secondRotation = 12;

  /// Screen 1 aligns both lines left at [textLeft]; the other screens centre
  /// them (no width needed).
  static TemplateData build({
    String title = '',
    String subtitle = '',
    double? titleWidth,
    double? subtitleWidth,
    List<CanvasDeviceItem> devices = const [],
  }) {
    final left = titleWidth != null;
    final subtitleAnchor = LayoutAnchors.forMode(LayoutMode.titleTopDeviceBottom).subtitle;
    return TemplateData(
      titleText: title,
      subtitleText: subtitle,
      titleFont: font,
      subtitleFont: font,
      titleSize: titleSize,
      subtitleSize: subtitleSize,
      titleWeight: FontWeight.w700,
      subtitleWeight: FontWeight.w600,
      textColor: titleColor,
      subtitleColor: subtitleColor,
      titleAlignment: left ? TextAlign.left : TextAlign.center,
      subtitleAlignment: left ? TextAlign.left : TextAlign.center,
      textOffsetX: left ? LeftHeadline.offsetX(left: textLeft, widestLine: titleWidth) : 0,
      textOffsetY: LeftHeadline.offsetY(top: titleTop, text: title, fontSize: titleSize),
      subtitleOffsetX: left ? LeftHeadline.offsetX(left: textLeft, widestLine: subtitleWidth ?? 0) : 0,
      subtitleOffsetY: LeftHeadline.offsetY(
        top: subtitleTop,
        text: subtitle,
        fontSize: subtitleSize,
        anchor: subtitleAnchor,
      ),
      customGradientColors: background,
      layoutMode: LayoutMode.titleTopDeviceBottom,
      deviceScale: uprightScale,
      deviceOffsetY: uprightOffsetY,
      devices: devices,
    );
  }
}
