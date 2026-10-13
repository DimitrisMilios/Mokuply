import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import '../models/template_data.dart';

/// Dart source for a built-in template that reproduces the open project,
/// for contributors who want to ship it with the app.
class TemplateCodeGenerator {
  TemplateCodeGenerator._();

  static String _formatColor(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return 'Color(0x$hex)';
  }

  static String generate({
    required String title,
    required String category,
    required String description,
    required TargetPlatformType platform,
    required List<TemplateData> screenshots,
  }) {
    final methodName = title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final safeMethodName = methodName.isEmpty
        ? 'customTemplate'
        : '${methodName[0].toLowerCase()}${methodName.substring(1)}';
    final templateId = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    final buffer = StringBuffer();
    buffer.writeln('  /// $title ($category)');
    buffer.writeln('  static ProjectTemplate $safeMethodName() {');
    buffer.writeln('    return ProjectTemplate(');
    buffer.writeln("      id: '$templateId',");
    buffer.writeln("      title: '$title',");
    buffer.writeln("      category: '$category',");
    buffer.writeln("      description: '$description',");
    buffer.writeln('      previewGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFF3B82F6)],');
    buffer.writeln('      platform: TargetPlatformType.${platform.name},');
    buffer.writeln('      initialScreenshots: [');

    for (int i = 0; i < screenshots.length; i++) {
      final s = screenshots[i];
      buffer.writeln('        // Screenshot ${i + 1}');
      buffer.writeln('        const TemplateData(');
      buffer.writeln("          titleText: '${s.titleText.replaceAll("'", r"\'")}',");
      buffer.writeln("          subtitleText: '${s.subtitleText.replaceAll("'", r"\'")}',");
      buffer.writeln("          titleFont: '${s.titleFont}',");
      buffer.writeln("          subtitleFont: '${s.subtitleFont}',");
      buffer.writeln('          titleSize: ${s.titleSize},');
      buffer.writeln('          subtitleSize: ${s.subtitleSize},');
      buffer.writeln('          titleWeight: FontWeight.${s.titleWeight.toString().split('.').last},');
      buffer.writeln('          subtitleWeight: FontWeight.${s.subtitleWeight.toString().split('.').last},');
      buffer.writeln('          textColor: ${_formatColor(s.textColor)},');
      buffer.writeln('          subtitleColor: ${_formatColor(s.subtitleColor)},');
      buffer.writeln('          titleAlignment: TextAlign.${s.titleAlignment.name},');
      buffer.writeln('          subtitleAlignment: TextAlign.${s.subtitleAlignment.name},');
      buffer.writeln('          textOffsetX: ${s.textOffsetX},');
      buffer.writeln('          textOffsetY: ${s.textOffsetY},');
      buffer.writeln('          subtitleOffsetX: ${s.subtitleOffsetX},');
      buffer.writeln('          subtitleOffsetY: ${s.subtitleOffsetY},');
      buffer.writeln('          selectedGradientIndex: ${s.selectedGradientIndex},');

      if (s.customGradientColors != null && s.customGradientColors!.isNotEmpty) {
        final colorsList = s.customGradientColors!.map((c) => _formatColor(c)).join(', ');
        buffer.writeln('          customGradientColors: [$colorsList],');
      }
      buffer.writeln('          layoutMode: LayoutMode.${s.layoutMode.name},');

      if (s.devices.isNotEmpty) {
        buffer.writeln('          devices: [');
        for (final d in s.devices) {
          buffer.writeln('            CanvasDeviceItem(');
          buffer.writeln("              id: '${d.id}',");
          buffer.writeln('              frameStyle: DeviceFrameStyle.${d.frameStyle.name},');
          buffer.writeln('              scale: ${d.scale},');
          buffer.writeln('              offsetX: ${d.offsetX},');
          buffer.writeln('              offsetY: ${d.offsetY},');
          buffer.writeln('              rotation: ${d.rotation},');
          buffer.writeln('              hasShadow: ${d.hasShadow},');
          buffer.writeln('            ),');
        }
        buffer.writeln('          ],');
      } else {
        buffer.writeln('          deviceRotation: ${s.deviceRotation},');
        buffer.writeln('          deviceScale: ${s.deviceScale},');
        buffer.writeln('          deviceOffsetX: ${s.deviceOffsetX},');
        buffer.writeln('          deviceOffsetY: ${s.deviceOffsetY},');
      }

      if (s.customTextItems.isNotEmpty) {
        buffer.writeln('          customTextItems: [');
        for (final t in s.customTextItems) {
          buffer.writeln('            CanvasTextItem(');
          buffer.writeln("              id: '${t.id}',");
          buffer.writeln("              text: '${t.text.replaceAll("'", r"\'")}',");
          buffer.writeln("              font: '${t.font}',");
          buffer.writeln('              fontSize: ${t.fontSize},');
          buffer.writeln('              color: ${_formatColor(t.color)},');
          buffer.writeln('              weight: FontWeight.${t.weight.toString().split('.').last},');
          buffer.writeln('              alignment: TextAlign.${t.alignment.name},');
          buffer.writeln('              offsetX: ${t.offsetX},');
          buffer.writeln('              offsetY: ${t.offsetY},');
          buffer.writeln('              rotation: ${t.rotation},');
          buffer.writeln('            ),');
        }
        buffer.writeln('          ],');
      }

      buffer.writeln('        ),');
    }

    buffer.writeln('      ],');
    buffer.writeln('    );');
    buffer.writeln('  }');
    return buffer.toString();
  }
}
