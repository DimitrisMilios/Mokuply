import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../models/canvas_device_item.dart';
import '../../models/project_template.dart';
import '../../models/template_data.dart';
import 'starter_style.dart';

/// Airy light-blue set opening with an angled two-phone hero, then boards,
/// messaging and scheduling. The default project.
ProjectTemplate teamOrganizeTemplate() {
  const bg = [Color(0xFFF7F9FC), Color(0xFFEEF3FA), Color(0xFFE2EAF6)];
  const title = Color(0xFF1E40AF);
  const style = StarterStyle(
    background: bg,
    titleColor: title,
    subtitleColor: Color(0xFF475569),
    titleFont: 'Outfit',
    titleSize: 104.0,
    subtitleSize: 46.0,
    titleWeight: FontWeight.w800,
    subtitleWeight: FontWeight.w600,
  );

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
          CanvasDeviceItem(id: 'dev_screen1_peer', scale: 1.28, offsetX: 940.0, offsetY: -60.0, rotation: -22.0),
          CanvasDeviceItem(id: 'dev_screen1_main', scale: 0.92, offsetX: -120.0, offsetY: 280.0, rotation: -22.0),
        ],
      ),
      // 2. Continuation: zoomed hero phone with the first phone's corner entering from the left
      const TemplateData(
        titleText: '',
        subtitleText: '',
        customGradientColors: bg,
        layoutMode: LayoutMode.angledLeftHero,
        devices: [
          CanvasDeviceItem(id: 'dev_screen2_peer', scale: 0.92, offsetX: -1120.0, offsetY: 280.0, rotation: -22.0),
          CanvasDeviceItem(id: 'dev_screen2_main', scale: 1.28, offsetX: -60.0, offsetY: -60.0, rotation: -22.0),
        ],
      ),
      style.screen('Stay connected', 'Team chat, threads and mentions in one place', Placement.bleedBottom),
      style.screen('Edit campaigns', 'Plan, assign and ship work together', Placement.bleedTop),
      style.screen('Keep your schedule', 'Calendar and reminders that stay in sync', Placement.bleedBottom),
      style.screen('Track success', 'Dashboards that show progress at a glance', Placement.bleedTop),
    ],
  );
}
