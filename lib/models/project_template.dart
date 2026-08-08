import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
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

  /// Default SaaS / Modern App 6-Screenshot Starter Template
  static ProjectTemplate saasModern() {
    return ProjectTemplate(
      id: 'saas_modern',
      title: 'SaaS & Productivity Suite',
      category: 'Productivity',
      description: 'Modern 6-card listing set with high-contrast headlines and vibrant gradient backdrop.',
      previewGradient: const [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0284C7)],
      platform: TargetPlatformType.appStore,
      initialScreenshots: [
        const TemplateData(
          titleText: 'Build Stunning Apps',
          subtitleText: 'Design high-res store screenshots in seconds',
          selectedGradientIndex: 0,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          titleText: 'Realtime Analytics',
          subtitleText: 'Track your growth and metrics live',
          selectedGradientIndex: 1,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          titleText: 'Seamless Integration',
          subtitleText: 'Connect with all your favorite dev tools',
          selectedGradientIndex: 2,
          layoutMode: LayoutMode.deviceCentered,
        ),
        const TemplateData(
          titleText: 'Ultra-Fast Performance',
          subtitleText: 'Built for speed, scale, and high output',
          selectedGradientIndex: 3,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          titleText: 'Secure Cloud Sync',
          subtitleText: '100% end-to-end client encrypted storage',
          selectedGradientIndex: 4,
          layoutMode: LayoutMode.fullBleedHero,
        ),
        const TemplateData(
          titleText: 'Export Anywhere',
          subtitleText: 'Download App Store ready PNGs instantly',
          selectedGradientIndex: 0,
          layoutMode: LayoutMode.titleBottomDeviceTop,
        ),
      ],
    );
  }

  /// Minimalist Tech Template
  static ProjectTemplate minimalistClean() {
    return ProjectTemplate(
      id: 'minimalist_clean',
      title: 'Clean Minimal Studio',
      category: 'Lifestyle',
      description: 'Sleek, minimalist studio aesthetic with subtle typography focus.',
      previewGradient: const [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
      platform: TargetPlatformType.appStore,
      initialScreenshots: [
        const TemplateData(
          titleText: 'Simplicity Redefined',
          subtitleText: 'Focus on what truly matters to your users',
          textColor: Color(0xFF0F172A),
          subtitleColor: Color(0xFF334155),
          selectedGradientIndex: 5,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          titleText: 'Intuitive Navigation',
          subtitleText: 'Designed for fluid touch interactions',
          textColor: Color(0xFF0F172A),
          subtitleColor: Color(0xFF334155),
          selectedGradientIndex: 5,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          titleText: 'Smart Workspace',
          subtitleText: 'Organize project tasks effortlessly',
          textColor: Color(0xFF0F172A),
          subtitleColor: Color(0xFF334155),
          selectedGradientIndex: 5,
          layoutMode: LayoutMode.deviceCentered,
        ),
        const TemplateData(
          titleText: 'Custom Widgets',
          subtitleText: 'Tailor views to your personal workflow',
          textColor: Color(0xFF0F172A),
          subtitleColor: Color(0xFF334155),
          selectedGradientIndex: 5,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          titleText: 'Dark & Light Modes',
          subtitleText: 'Adapts seamlessly to device theme',
          textColor: Color(0xFF0F172A),
          subtitleColor: Color(0xFF334155),
          selectedGradientIndex: 5,
          layoutMode: LayoutMode.fullBleedHero,
        ),
        const TemplateData(
          titleText: 'Get Started Free',
          subtitleText: 'No account registration required',
          textColor: Color(0xFF0F172A),
          subtitleColor: Color(0xFF334155),
          selectedGradientIndex: 5,
          layoutMode: LayoutMode.titleBottomDeviceTop,
        ),
      ],
    );
  }

  /// Sunset Glow Mobile Template
  static ProjectTemplate sunsetGlow() {
    return ProjectTemplate(
      id: 'sunset_glow',
      title: 'Sunset Glow Luxe',
      category: 'Entertainment',
      description: 'Vibrant warm orange and rose gradients for media and social apps.',
      previewGradient: const [Color(0xFF4C0519), Color(0xFF9F1239), Color(0xFFF97316)],
      platform: TargetPlatformType.googlePlay,
      initialScreenshots: [
        const TemplateData(
          platform: TargetPlatformType.googlePlay,
          frameStyle: DeviceFrameStyle.samsungS26Ultra,
          titleText: 'Discover New Music',
          subtitleText: 'Stream millions of tracks in lossless audio',
          selectedGradientIndex: 2,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          platform: TargetPlatformType.googlePlay,
          frameStyle: DeviceFrameStyle.samsungS26Ultra,
          titleText: 'Personalized Mixes',
          subtitleText: 'Playlists crafted daily just for your taste',
          selectedGradientIndex: 2,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          platform: TargetPlatformType.googlePlay,
          frameStyle: DeviceFrameStyle.samsungS26Ultra,
          titleText: 'Live Concert Feeds',
          subtitleText: 'Follow your favorite artists worldwide',
          selectedGradientIndex: 2,
          layoutMode: LayoutMode.deviceCentered,
        ),
        const TemplateData(
          platform: TargetPlatformType.googlePlay,
          frameStyle: DeviceFrameStyle.samsungS26Ultra,
          titleText: 'Offline Playback',
          subtitleText: 'Save albums and listen anywhere without data',
          selectedGradientIndex: 2,
          layoutMode: LayoutMode.titleTopDeviceBottom,
        ),
        const TemplateData(
          platform: TargetPlatformType.googlePlay,
          frameStyle: DeviceFrameStyle.samsungS26Ultra,
          titleText: 'High Quality EQ',
          subtitleText: 'Fine-tune sound with custom equalizer settings',
          selectedGradientIndex: 2,
          layoutMode: LayoutMode.fullBleedHero,
        ),
        const TemplateData(
          platform: TargetPlatformType.googlePlay,
          frameStyle: DeviceFrameStyle.samsungS26Ultra,
          titleText: 'Listen Now',
          subtitleText: 'Available on iOS and Android',
          selectedGradientIndex: 2,
          layoutMode: LayoutMode.titleBottomDeviceTop,
        ),
      ],
    );
  }

  /// List of all available store templates
  static List<ProjectTemplate> get allTemplates => [
        saasModern(),
        minimalistClean(),
        sunsetGlow(),
      ];
}
