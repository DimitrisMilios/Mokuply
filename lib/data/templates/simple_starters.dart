import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../models/project_template.dart';
import 'starter_style.dart';

/// Warm stone backdrop with editorial serif headlines.
ProjectTemplate minimalistCleanTemplate() {
  const style = StarterStyle(
    background: [Color(0xFFFBFAF8), Color(0xFFF3F1EC), Color(0xFFE8E4DD)],
    titleColor: Color(0xFF1C1917),
    subtitleColor: Color(0xFF6B6560),
    titleFont: 'Playfair Display',
    titleSize: 100.0,
    subtitleSize: 44.0,
    titleWeight: FontWeight.w600,
    subtitleWeight: FontWeight.w400,
  );
  return ProjectTemplate(
    id: 'minimalist_clean',
    title: 'Clean Minimal Studio',
    category: 'Lifestyle',
    description: 'Warm stone backdrop with editorial serif headlines and generous whitespace.',
    previewGradient: style.background,
    platform: style.platform,
    initialScreenshots: [
      style.screen('Simplicity Redefined', 'Focus on what truly matters to your users', Placement.centered),
      style.screen('Intuitive Navigation', 'Designed for fluid touch interactions', Placement.bleedBottom),
      style.screen('Smart Workspace', 'Organize project tasks effortlessly', Placement.bleedTop),
      style.screen('Custom Widgets', 'Tailor views to your personal workflow', Placement.bleedBottom),
      style.screen('Dark & Light', 'Adapts seamlessly to the device theme', Placement.centered),
      style.screen('Get Started Free', 'No account registration required', Placement.bleedTop),
    ],
  );
}

/// Plum-to-amber gradient for media and social apps (Google Play preview).
ProjectTemplate sunsetGlowTemplate() {
  const style = StarterStyle(
    background: [Color(0xFF2B0E1E), Color(0xFF8F2A4D), Color(0xFFF08A4B)],
    titleColor: Colors.white,
    subtitleColor: Color(0xFFFFE7D9),
    titleFont: 'Montserrat',
    titleSize: 100.0,
    subtitleSize: 44.0,
    titleWeight: FontWeight.w800,
    subtitleWeight: FontWeight.w500,
    platform: TargetPlatformType.googlePlay,
  );
  return ProjectTemplate(
    id: 'sunset_glow',
    title: 'Sunset Glow Luxe',
    category: 'Entertainment',
    description: 'Plum-to-amber gradient with bold geometric headlines for media and social apps.',
    previewGradient: style.background,
    platform: style.platform,
    initialScreenshots: [
      style.screen(
        'Discover New Music',
        'Stream millions of tracks in lossless audio',
        Placement.bleedBottom,
        layout: LayoutMode.angledRightHero,
        extraOffsetY: 40,
        rotation: 12.0,
      ),
      style.screen('Personalized Mixes', 'Playlists crafted daily for your taste', Placement.bleedBottom),
      style.screen('Live Concerts', 'Follow your favorite artists worldwide', Placement.bleedTop),
      style.screen('Offline Playback', 'Save albums and listen anywhere', Placement.bleedBottom),
      style.screen('Studio Sound', 'Fine-tune audio with a custom equalizer', Placement.centered),
      style.screen('Listen Now', 'Available on iOS and Android', Placement.bleedBottom),
    ],
  );
}
