import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../core/layout/layout_anchors.dart';
import '../../models/project_template.dart';
import '../../models/template_data.dart';
import 'left_headline.dart';

/// Deep teal set with calm white two-line captions. Screens alternate: caption
/// on top with the phone cropped by the bottom edge, then the phone cropped by
/// the top edge with the caption below.
ProjectTemplate messengerDarkTemplate() {
  return ProjectTemplate(
    id: 'messenger_dark',
    title: 'Messenger Dark',
    category: 'Social',
    description: 'Deep teal screens with calm white captions that alternate above and below upright phones.',
    previewGradient: _MessengerScreen.background,
    platform: TargetPlatformType.appStore,
    initialScreenshots: [
      _MessengerScreen.captionTop('Simple, private\nreal-time chat'),
      _MessengerScreen.captionBottom('Share photos\nand videos instantly'),
      _MessengerScreen.captionTop('Talk faster\nwith voice messages'),
      _MessengerScreen.captionBottom('Share your live\nlocation with friends'),
      _MessengerScreen.captionTop('Express yourself\nwith emojis and more'),
      _MessengerScreen.captionBottom('Private chats,\nlocked by default'),
    ],
  );
}

/// Geometry for the messenger set, in design pixels unless noted.
class _MessengerScreen {
  _MessengerScreen._();

  static const List<Color> background = [Color(0xFF1E3F38), Color(0xFF1B3A33), Color(0xFF17322C)];
  static const String font = 'Inter';
  static const double captionSize = 104;
  static const double phoneScale = 1.07;

  /// Caption box top when the caption sits above the phone, and the phone's
  /// offset (units) that puts its top at 854 px, cropped by the bottom edge.
  static const double topCaptionTop = 308;
  static const double bottomBleedOffsetY = 124;

  /// Caption box top when it sits below the phone, and the phone's offset
  /// (units) that puts its bottom at 1995 px, cropped by the top edge.
  static const double bottomCaptionTop = 2303;
  static const double topBleedOffsetY = -97;

  static TemplateData captionTop(String caption) => _screen(
        caption,
        layout: LayoutMode.titleTopDeviceBottom,
        captionTop: topCaptionTop,
        deviceOffsetY: bottomBleedOffsetY,
      );

  static TemplateData captionBottom(String caption) => _screen(
        caption,
        layout: LayoutMode.titleBottomDeviceTop,
        captionTop: bottomCaptionTop,
        deviceOffsetY: topBleedOffsetY,
      );

  static TemplateData _screen(
    String caption, {
    required LayoutMode layout,
    required double captionTop,
    required double deviceOffsetY,
  }) {
    return TemplateData(
      titleText: caption,
      subtitleText: '',
      titleFont: font,
      titleSize: captionSize,
      titleWeight: FontWeight.w400,
      textColor: Colors.white,
      textOffsetY: LeftHeadline.offsetY(
        top: captionTop,
        text: caption,
        fontSize: captionSize,
        anchor: LayoutAnchors.forMode(layout).title,
      ),
      customGradientColors: background,
      layoutMode: layout,
      deviceScale: phoneScale,
      deviceOffsetY: deviceOffsetY,
    );
  }
}
