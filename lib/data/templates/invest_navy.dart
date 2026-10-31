import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../core/layout/layout_anchors.dart';
import '../../models/canvas_device_item.dart';
import '../../models/canvas_text_item.dart';
import '../../models/project_template.dart';
import '../../models/template_data.dart';
import 'left_headline.dart';

/// Editorial finance set: serif headlines on navy and white, every screen
/// split by a flat band at 71 % height. Screen 1 is all type (headline,
/// promise and a quote), screen 2 a collage of three angled phones, then
/// centred headlines over large upright phones.
ProjectTemplate investNavyTemplate() {
  return ProjectTemplate(
    id: 'invest_navy',
    title: 'Invest Navy',
    category: 'Finance',
    description: 'Serif headlines on navy and white with a split backdrop, a quote screen and an angled phone collage.',
    previewGradient: const [_InvestScreen.navy, Color(0xFF3A4A9A), Colors.white],
    platform: TargetPlatformType.appStore,
    initialScreenshots: [
      _InvestScreen.typeOnly(),
      _InvestScreen.collage(),
      const _InvestScreen(title: 'Zero Fees', subtitle: 'Trade stocks and ETFs\nwith no commission.').build(),
      const _InvestScreen(title: 'Easy to use', subtitle: 'Start with fractional shares', dark: true).build(),
      const _InvestScreen(title: 'All-in-one', subtitle: 'Learn, plan and invest').build(),
      const _InvestScreen(title: 'Live Markets', subtitle: 'Real-time prices and alerts').build(),
    ],
  );
}

/// Geometry for the navy set, in design pixels unless noted. Left-aligned
/// widths are measured for DM Serif Display at the given sizes.
class _InvestScreen {
  final String title;
  final String subtitle;

  /// Navy top half with white type instead of white with dark type.
  final bool dark;

  const _InvestScreen({required this.title, required this.subtitle, this.dark = false});

  static const Color navy = Color(0xFF22306E);
  static const Color ink = Color(0xFF121633);
  static const Color inkSoft = Color(0xFF3A4060);
  static const Color mist = Color(0xFFDCE1F5);
  static const String serif = 'DM Serif Display';
  static const String sans = 'Inter';
  static const double bandTop = 0.71;

  static const double headlineSize = 180;
  static const double headlineTop = 103;
  static const double lineSize = 72;
  static const double lineTop = 322;

  /// Large upright phone, centred, top at about 590 px over the band.
  static const double phoneScale = 1.21;
  static const double phoneOffsetY = 41;

  static double get _subtitleAnchor => LayoutAnchors.forMode(LayoutMode.titleTopDeviceBottom).subtitle;

  /// Screens 3–6: centred serif headline and a sans line under it.
  TemplateData build() {
    return TemplateData(
      titleText: title,
      subtitleText: subtitle,
      titleFont: serif,
      subtitleFont: sans,
      titleSize: headlineSize,
      subtitleSize: lineSize,
      titleWeight: FontWeight.w400,
      subtitleWeight: FontWeight.w400,
      textColor: dark ? Colors.white : ink,
      subtitleColor: dark ? mist : inkSoft,
      textOffsetY: LeftHeadline.offsetY(top: headlineTop, text: title, fontSize: headlineSize),
      subtitleOffsetY: LeftHeadline.offsetY(
        top: lineTop,
        text: subtitle,
        fontSize: lineSize,
        anchor: _subtitleAnchor,
      ),
      customBackgroundColor: dark ? navy : Colors.white,
      backgroundBandColor: navy,
      backgroundBandTop: bandTop,
      layoutMode: LayoutMode.titleTopDeviceBottom,
      deviceScale: phoneScale,
      deviceOffsetY: phoneOffsetY,
    );
  }

  /// Screen 1: big left-aligned headline and promise on navy, a quote on the
  /// white band. The app keeps one phone per screen, so it waits off the
  /// right edge (select it from Layers to bring it in).
  static TemplateData typeOnly() {
    const left = 142.0;
    const title = 'Smart\nInvesting\nMade\nSimple';
    const promise = 'Grow your\nmoney with\nconfidence';
    const quote = '“The best\ninvesting app\nI have used\nso far”';
    return TemplateData(
      titleText: title,
      subtitleText: promise,
      titleFont: serif,
      subtitleFont: serif,
      titleSize: 217,
      subtitleSize: 136,
      titleWeight: FontWeight.w400,
      subtitleWeight: FontWeight.w400,
      textColor: Colors.white,
      subtitleColor: Colors.white,
      titleAlignment: TextAlign.left,
      subtitleAlignment: TextAlign.left,
      textOffsetX: LeftHeadline.offsetX(left: left, widestLine: 874),
      textOffsetY: LeftHeadline.offsetY(top: 194, text: title, fontSize: 217),
      subtitleOffsetX: LeftHeadline.offsetX(left: left, widestLine: 722),
      subtitleOffsetY: LeftHeadline.offsetY(top: 1358, text: promise, fontSize: 136, anchor: _subtitleAnchor),
      customBackgroundColor: navy,
      backgroundBandColor: Colors.white,
      backgroundBandTop: bandTop,
      layoutMode: LayoutMode.titleTopDeviceBottom,
      devices: const [
        CanvasDeviceItem(id: 'dev_invest_spare', scale: 0.95, offsetX: 1100, offsetY: -234, rotation: 12),
      ],
      customTextItems: [
        CanvasTextItem(
          id: 'txt_invest_quote',
          text: quote,
          font: serif,
          fontSize: 136,
          color: ink,
          weight: FontWeight.w400,
          alignment: TextAlign.left,
          offsetX: LeftHeadline.offsetX(left: left, widestLine: 816),
          offsetY: LeftHeadline.offsetY(top: 2140, text: quote, fontSize: 136, anchor: LayoutAnchors.freeElement),
        ),
      ],
    );
  }

  /// Screen 2: three phones tilted 12° — one bleeding off the left edge, one
  /// off the top right corner, one off the bottom right corner.
  static TemplateData collage() {
    return const TemplateData(
      titleText: '',
      subtitleText: '',
      customBackgroundColor: Colors.white,
      backgroundBandColor: navy,
      backgroundBandTop: bandTop,
      layoutMode: LayoutMode.titleTopDeviceBottom,
      devices: [
        CanvasDeviceItem(id: 'dev_invest_left', scale: 0.95, offsetX: -459, offsetY: -234, rotation: 12),
        CanvasDeviceItem(id: 'dev_invest_top', scale: 0.95, offsetX: 722, offsetY: -926, rotation: 12),
        CanvasDeviceItem(id: 'dev_invest_bottom', scale: 0.95, offsetX: 259, offsetY: 669, rotation: 12),
      ],
    );
  }
}
