import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import 'canvas_device_item.dart';
import 'template_data.dart';

/// Preset Project Template definition for the Store landing page.
class ProjectTemplate {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<Color> previewGradient;
  final TargetPlatformType platform;
  final List<TemplateData> initialScreenshots;

  const ProjectTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.previewGradient,
    required this.platform,
    required this.initialScreenshots,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'previewGradient': previewGradient.map((c) => c.toARGB32()).toList(),
      'platform': platform.name,
      'initialScreenshots': initialScreenshots.map((s) => s.toJson()).toList(),
    };
  }

  factory ProjectTemplate.fromJson(Map<String, dynamic> json) {
    return ProjectTemplate(
      id: json['id'] as String? ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Custom Template',
      category: json['category'] as String? ?? 'Custom',
      description: json['description'] as String? ?? '',
      previewGradient: (json['previewGradient'] as List?)
              ?.map((c) => Color(c as int))
              .toList() ??
          const [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFF3B82F6)],
      platform: TargetPlatformType.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => TargetPlatformType.appStore,
      ),
      initialScreenshots: (json['initialScreenshots'] as List?)
              ?.map((s) => TemplateData.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared composition values (design offset units: X = 1/1000 width, Y = 1/2000 height)
  //
  // Every starter set follows the same rhythm so a six-screen strip reads as one
  // story: a headline block at the top (or bottom) and a phone that bleeds off
  // the opposite edge, the way store listings usually present it.
  // ---------------------------------------------------------------------------

  /// Phone anchored at the bottom, cropped slightly by the lower edge.
  static const double _bleedBottomScale = 1.0;
  static const double _bleedBottomOffsetY = 190.0;

  /// Phone anchored at the top (headline below), cropped by the upper edge.
  static const double _bleedTopScale = 1.0;
  static const double _bleedTopOffsetY = -170.0;

  /// Phone fully visible in the middle of the screen.
  static const double _centeredScale = 0.82;

  /// Breathing room: title nudged down from the edge, subtitle pulled closer to it.
  static const double _titleOffsetY = 20.0;
  static const double _subtitleOffsetY = -30.0;

  /// Default SaaS / Modern App 6-Screenshot Starter Template
  static ProjectTemplate saasModern() {
    const bg = [Color(0xFF0B1120), Color(0xFF131C3B), Color(0xFF1D2E6B)];
    const title = Colors.white;
    const subtitle = Color(0xFFB6C2E2);

    TemplateData screen({
      required String titleText,
      required String subtitleText,
      required LayoutMode layoutMode,
      required double deviceScale,
      double deviceOffsetY = 0.0,
    }) {
      return TemplateData(
        titleText: titleText,
        subtitleText: subtitleText,
        titleFont: 'Outfit',
        subtitleFont: 'Inter',
        titleSize: 104.0,
        subtitleSize: 44.0,
        titleWeight: FontWeight.w800,
        subtitleWeight: FontWeight.w500,
        textColor: title,
        subtitleColor: subtitle,
        textOffsetY: _titleOffsetY,
        subtitleOffsetY: _subtitleOffsetY,
        customGradientColors: bg,
        layoutMode: layoutMode,
        deviceScale: deviceScale,
        deviceOffsetY: deviceOffsetY,
      );
    }

    return ProjectTemplate(
      id: 'saas_modern',
      title: 'SaaS & Productivity Suite',
      category: 'Productivity',
      description: 'Deep navy set with bold white headlines and a calm, consistent backdrop across all six screens.',
      previewGradient: bg,
      platform: TargetPlatformType.appStore,
      initialScreenshots: [
        screen(
          titleText: 'Build Stunning Apps',
          subtitleText: 'Design high-res store screenshots in seconds',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Realtime Analytics',
          subtitleText: 'Track your growth and metrics live',
          layoutMode: LayoutMode.titleBottomDeviceTop,
          deviceScale: _bleedTopScale,
          deviceOffsetY: _bleedTopOffsetY,
        ),
        screen(
          titleText: 'Seamless Integration',
          subtitleText: 'Connect with all your favorite dev tools',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Blazing Fast',
          subtitleText: 'Built for speed, scale, and high output',
          layoutMode: LayoutMode.deviceCentered,
          deviceScale: _centeredScale,
        ),
        screen(
          titleText: 'Secure Cloud Sync',
          subtitleText: '100% end-to-end encrypted storage',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Export Anywhere',
          subtitleText: 'Download store-ready PNGs instantly',
          layoutMode: LayoutMode.titleBottomDeviceTop,
          deviceScale: _bleedTopScale,
          deviceOffsetY: _bleedTopOffsetY,
        ),
      ],
    );
  }

  /// Minimalist Editorial Template
  static ProjectTemplate minimalistClean() {
    const bg = [Color(0xFFFBFAF8), Color(0xFFF3F1EC), Color(0xFFE8E4DD)];
    const title = Color(0xFF1C1917);
    const subtitle = Color(0xFF6B6560);

    TemplateData screen({
      required String titleText,
      required String subtitleText,
      required LayoutMode layoutMode,
      required double deviceScale,
      double deviceOffsetY = 0.0,
    }) {
      return TemplateData(
        titleText: titleText,
        subtitleText: subtitleText,
        titleFont: 'Playfair Display',
        subtitleFont: 'Inter',
        titleSize: 100.0,
        subtitleSize: 44.0,
        titleWeight: FontWeight.w600,
        subtitleWeight: FontWeight.w400,
        textColor: title,
        subtitleColor: subtitle,
        textOffsetY: _titleOffsetY,
        subtitleOffsetY: _subtitleOffsetY,
        customGradientColors: bg,
        layoutMode: layoutMode,
        deviceScale: deviceScale,
        deviceOffsetY: deviceOffsetY,
      );
    }

    return ProjectTemplate(
      id: 'minimalist_clean',
      title: 'Clean Minimal Studio',
      category: 'Lifestyle',
      description: 'Warm stone backdrop with editorial serif headlines and generous whitespace.',
      previewGradient: bg,
      platform: TargetPlatformType.appStore,
      initialScreenshots: [
        screen(
          titleText: 'Simplicity Redefined',
          subtitleText: 'Focus on what truly matters to your users',
          layoutMode: LayoutMode.deviceCentered,
          deviceScale: _centeredScale,
        ),
        screen(
          titleText: 'Intuitive Navigation',
          subtitleText: 'Designed for fluid touch interactions',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Smart Workspace',
          subtitleText: 'Organize project tasks effortlessly',
          layoutMode: LayoutMode.titleBottomDeviceTop,
          deviceScale: _bleedTopScale,
          deviceOffsetY: _bleedTopOffsetY,
        ),
        screen(
          titleText: 'Custom Widgets',
          subtitleText: 'Tailor views to your personal workflow',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Dark & Light',
          subtitleText: 'Adapts seamlessly to the device theme',
          layoutMode: LayoutMode.deviceCentered,
          deviceScale: _centeredScale,
        ),
        screen(
          titleText: 'Get Started Free',
          subtitleText: 'No account registration required',
          layoutMode: LayoutMode.titleBottomDeviceTop,
          deviceScale: _bleedTopScale,
          deviceOffsetY: _bleedTopOffsetY,
        ),
      ],
    );
  }

  /// Sunset Glow Media Template (Google Play preview)
  static ProjectTemplate sunsetGlow() {
    const bg = [Color(0xFF2B0E1E), Color(0xFF8F2A4D), Color(0xFFF08A4B)];
    const title = Colors.white;
    const subtitle = Color(0xFFFFE7D9);

    TemplateData screen({
      required String titleText,
      required String subtitleText,
      required LayoutMode layoutMode,
      required double deviceScale,
      double deviceOffsetY = 0.0,
      double deviceRotation = 0.0,
    }) {
      return TemplateData(
        platform: TargetPlatformType.googlePlay,
        titleText: titleText,
        subtitleText: subtitleText,
        titleFont: 'Montserrat',
        subtitleFont: 'Inter',
        titleSize: 100.0,
        subtitleSize: 44.0,
        titleWeight: FontWeight.w800,
        subtitleWeight: FontWeight.w500,
        textColor: title,
        subtitleColor: subtitle,
        textOffsetY: _titleOffsetY,
        subtitleOffsetY: _subtitleOffsetY,
        customGradientColors: bg,
        layoutMode: layoutMode,
        deviceScale: deviceScale,
        deviceOffsetY: deviceOffsetY,
        deviceRotation: deviceRotation,
      );
    }

    return ProjectTemplate(
      id: 'sunset_glow',
      title: 'Sunset Glow Luxe',
      category: 'Entertainment',
      description: 'Plum-to-amber gradient with bold geometric headlines for media and social apps.',
      previewGradient: bg,
      platform: TargetPlatformType.googlePlay,
      initialScreenshots: [
        screen(
          titleText: 'Discover New Music',
          subtitleText: 'Stream millions of tracks in lossless audio',
          layoutMode: LayoutMode.angledRightHero,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY + 40,
          deviceRotation: 12.0,
        ),
        screen(
          titleText: 'Personalized Mixes',
          subtitleText: 'Playlists crafted daily for your taste',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Live Concerts',
          subtitleText: 'Follow your favorite artists worldwide',
          layoutMode: LayoutMode.titleBottomDeviceTop,
          deviceScale: _bleedTopScale,
          deviceOffsetY: _bleedTopOffsetY,
        ),
        screen(
          titleText: 'Offline Playback',
          subtitleText: 'Save albums and listen anywhere',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Studio Sound',
          subtitleText: 'Fine-tune audio with a custom equalizer',
          layoutMode: LayoutMode.deviceCentered,
          deviceScale: _centeredScale,
        ),
        screen(
          titleText: 'Listen Now',
          subtitleText: 'Available on iOS and Android',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
      ],
    );
  }

  /// Productivity & Team Task Organization 6-Screenshot Suite
  static ProjectTemplate teamOrganize() {
    const bg = [Color(0xFFF7F9FC), Color(0xFFEEF3FA), Color(0xFFE2EAF6)];
    const title = Color(0xFF1E40AF);
    const subtitle = Color(0xFF475569);

    TemplateData screen({
      required String titleText,
      required String subtitleText,
      required LayoutMode layoutMode,
      required double deviceScale,
      double deviceOffsetY = 0.0,
    }) {
      return TemplateData(
        titleText: titleText,
        subtitleText: subtitleText,
        titleFont: 'Outfit',
        subtitleFont: 'Inter',
        titleSize: 104.0,
        subtitleSize: 46.0,
        titleWeight: FontWeight.w800,
        subtitleWeight: FontWeight.w600,
        textColor: title,
        subtitleColor: subtitle,
        textOffsetY: _titleOffsetY,
        subtitleOffsetY: _subtitleOffsetY,
        customGradientColors: bg,
        layoutMode: layoutMode,
        deviceScale: deviceScale,
        deviceOffsetY: deviceOffsetY,
      );
    }

    return ProjectTemplate(
      id: 'team_organize',
      title: 'Team Task & Workflow Hub',
      category: 'Productivity',
      description: 'Airy light-blue set opening with an angled two-phone hero, then boards, messaging and scheduling.',
      previewGradient: bg,
      platform: TargetPlatformType.appStore,
      initialScreenshots: [
        // 1. Angled hero pair: main phone left, peer phone entering from the right edge
        const TemplateData(
          titleText: 'Organize',
          subtitleText: 'Your company.',
          titleFont: 'Outfit',
          subtitleFont: 'Inter',
          titleSize: 112.0,
          subtitleSize: 52.0,
          titleWeight: FontWeight.w800,
          subtitleWeight: FontWeight.w700,
          textColor: title,
          subtitleColor: Color(0xFF0F172A),
          titleAlignment: TextAlign.left,
          subtitleAlignment: TextAlign.left,
          textOffsetX: -150.0,
          textOffsetY: -40.0,
          subtitleOffsetX: -150.0,
          subtitleOffsetY: -40.0,
          customGradientColors: bg,
          layoutMode: LayoutMode.angledLeftHero,
          devices: [
            CanvasDeviceItem(
              id: 'dev_screen1_peer',
              scale: 1.28,
              offsetX: 940.0,
              offsetY: -60.0,
              rotation: -22.0,
            ),
            CanvasDeviceItem(
              id: 'dev_screen1_main',
              scale: 0.92,
              offsetX: -120.0,
              offsetY: 280.0,
              rotation: -22.0,
            ),
          ],
        ),
        // 2. Continuation: zoomed hero phone with the first phone's corner entering from the left
        const TemplateData(
          titleText: '',
          subtitleText: '',
          customGradientColors: bg,
          layoutMode: LayoutMode.angledLeftHero,
          devices: [
            CanvasDeviceItem(
              id: 'dev_screen2_peer',
              scale: 0.92,
              offsetX: -1120.0,
              offsetY: 280.0,
              rotation: -22.0,
            ),
            CanvasDeviceItem(
              id: 'dev_screen2_main',
              scale: 1.28,
              offsetX: -60.0,
              offsetY: -60.0,
              rotation: -22.0,
            ),
          ],
        ),
        screen(
          titleText: 'Stay connected',
          subtitleText: 'Team chat, threads and mentions in one place',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Edit campaigns',
          subtitleText: 'Plan, assign and ship work together',
          layoutMode: LayoutMode.titleBottomDeviceTop,
          deviceScale: _bleedTopScale,
          deviceOffsetY: _bleedTopOffsetY,
        ),
        screen(
          titleText: 'Keep your schedule',
          subtitleText: 'Calendar and reminders that stay in sync',
          layoutMode: LayoutMode.titleTopDeviceBottom,
          deviceScale: _bleedBottomScale,
          deviceOffsetY: _bleedBottomOffsetY,
        ),
        screen(
          titleText: 'Track success',
          subtitleText: 'Dashboards that show progress at a glance',
          layoutMode: LayoutMode.titleBottomDeviceTop,
          deviceScale: _bleedTopScale,
          deviceOffsetY: _bleedTopOffsetY,
        ),
      ],
    );
  }

  /// In-memory user-created custom templates
  static final List<ProjectTemplate> _userCustomTemplates = [];

  static List<ProjectTemplate> get customTemplates => List.unmodifiable(_userCustomTemplates);

  static void addCustomTemplate(ProjectTemplate template) {
    _userCustomTemplates.removeWhere((t) => t.id == template.id);
    _userCustomTemplates.insert(0, template);
  }

  static void setCustomTemplates(List<ProjectTemplate> templates) {
    _userCustomTemplates.clear();
    _userCustomTemplates.addAll(templates);
  }

  static void clearCustomTemplates() {
    _userCustomTemplates.clear();
  }

  /// List of all available store templates
  static List<ProjectTemplate> get allTemplates => [
        ..._userCustomTemplates,
        teamOrganize(),
        saasModern(),
        minimalistClean(),
        sunsetGlow(),
      ];
}
