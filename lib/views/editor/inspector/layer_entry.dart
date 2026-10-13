import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/element_kind.dart';
import '../../../models/template_data.dart';

/// One row of the layers list, derived from a screen.
@immutable
class LayerEntry {
  final String id;
  final IconData icon;
  final String name;
  final String detail;

  /// Greyed out: an empty headline, or a frame without a screenshot.
  final bool muted;
  final bool canDelete;
  final String deleteTooltip;
  final Uint8List? thumbnail;

  const LayerEntry({
    required this.id,
    required this.icon,
    required this.name,
    required this.detail,
    this.muted = false,
    this.canDelete = true,
    required this.deleteTooltip,
    this.thumbnail,
  });

  /// Every element of [screen], bottom to top as the inspector lists them.
  static List<LayerEntry> of(TemplateData screen, TargetPlatformType platform) {
    final devices = screen.effectiveDevices;
    return [
      LayerEntry(
        id: ElementKind.titleId,
        icon: Icons.title_rounded,
        name: 'Headline',
        detail: screen.titleText.isEmpty ? 'Empty' : screen.titleText,
        muted: screen.titleText.isEmpty,
        canDelete: screen.titleText.isNotEmpty,
        deleteTooltip: 'Clear headline',
      ),
      LayerEntry(
        id: ElementKind.subtitleId,
        icon: Icons.notes_rounded,
        name: 'Subtitle',
        detail: screen.subtitleText.isEmpty ? 'Empty' : screen.subtitleText,
        muted: screen.subtitleText.isEmpty,
        canDelete: screen.subtitleText.isNotEmpty,
        deleteTooltip: 'Clear subtitle',
      ),
      for (final (i, d) in devices.indexed)
        LayerEntry(
          id: d.id,
          icon: Icons.smartphone_rounded,
          name: 'Phone frame #${i + 1}',
          detail: d.hasAnyScreenshot ? d.frameStyle.labelFor(platform) : 'No screenshot yet',
          muted: !d.hasAnyScreenshot,
          canDelete: devices.length > 1,
          deleteTooltip: 'Remove frame',
        ),
      for (final (i, img) in screen.customImageItems.indexed)
        LayerEntry(
          id: img.id,
          icon: Icons.image_rounded,
          name: 'Image #${i + 1}',
          detail: '${(img.scale * 100).toInt()}% · ${img.rotation.toInt()}°',
          deleteTooltip: 'Delete image',
          thumbnail: img.imageBytes,
        ),
      for (final (i, t) in screen.customTextItems.indexed)
        LayerEntry(
          id: t.id,
          icon: Icons.text_fields_rounded,
          name: 'Text #${i + 1}',
          detail: t.text,
          deleteTooltip: 'Delete text',
        ),
    ];
  }
}
