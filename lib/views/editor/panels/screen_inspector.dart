import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import 'background_panel.dart';

/// Shown when nothing on the canvas is selected: layout presets, background,
/// a layers list to pick elements, and screen-level actions.
class ScreenInspector extends StatelessWidget {
  const ScreenInspector({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Screen actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => vm.duplicateScreenshot(vm.selectedIndex),
                style: _actionStyle(AppColors.textPrimary),
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('Duplicate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.screenshotsCount > 1 ? () => vm.removeScreenshot(vm.selectedIndex) : null,
                style: _actionStyle(AppColors.error),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Section switch
        SegmentedButton<ScreenInspectorSection>(
          segments: const [
            ButtonSegment(
              value: ScreenInspectorSection.layout,
              label: Text('Layout'),
              icon: Icon(Icons.dashboard_customize_rounded, size: 14),
            ),
            ButtonSegment(
              value: ScreenInspectorSection.background,
              label: Text('Backdrop'),
              icon: Icon(Icons.palette_rounded, size: 14),
            ),
            ButtonSegment(
              value: ScreenInspectorSection.layers,
              label: Text('Layers'),
              icon: Icon(Icons.layers_rounded, size: 14),
            ),
          ],
          selected: {vm.screenSection},
          showSelectedIcon: false,
          onSelectionChanged: (s) => vm.showScreenSection(s.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColors.textOnPrimary : AppColors.textPrimary,
            ),
            side: WidgetStateProperty.all(const BorderSide(color: AppColors.glassBorder)),
          ),
        ),
        const SizedBox(height: 14),

        switch (vm.screenSection) {
          ScreenInspectorSection.layout => _LayoutSection(vm: vm),
          ScreenInspectorSection.background => const BackgroundSection(),
          ScreenInspectorSection.layers => _LayersSection(vm: vm),
        },
      ],
    );
  }

  ButtonStyle _actionStyle(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
    );
  }
}

class _LayoutSection extends StatelessWidget {
  final EditorViewModel vm;
  const _LayoutSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Presets reposition the headline and phone. You can still drag anything afterwards.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 8),
        for (final mode in LayoutMode.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  side: BorderSide(
                    color: vm.layoutMode == mode ? AppColors.primary : AppColors.glassBorder,
                    width: vm.layoutMode == mode ? 1.8 : 1,
                  ),
                ),
                tileColor: vm.layoutMode == mode
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.5),
                title: Text(
                  mode.title,
                  style: TextStyle(
                    color: vm.layoutMode == mode ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(mode.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                trailing: vm.layoutMode == mode
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18)
                    : null,
                onTap: () => vm.setLayoutMode(mode),
              ),
            ),
          ),
      ],
    );
  }
}

class _LayersSection extends StatelessWidget {
  final EditorViewModel vm;
  const _LayersSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _LayerRow(
        icon: Icons.title_rounded,
        name: 'Headline',
        detail: vm.titleText.isEmpty ? 'Empty — tap to add' : vm.titleText,
        muted: vm.titleText.isEmpty,
        onTap: () => vm.selectElement('title'),
      ),
      _LayerRow(
        icon: Icons.notes_rounded,
        name: 'Subtitle',
        detail: vm.subtitleText.isEmpty ? 'Empty — tap to add' : vm.subtitleText,
        muted: vm.subtitleText.isEmpty,
        onTap: () => vm.selectElement('subtitle'),
      ),
      for (final (i, d) in vm.devices.indexed)
        _LayerRow(
          icon: Icons.smartphone_rounded,
          name: 'Phone frame #${i + 1}',
          detail: d.hasAnyScreenshot ? d.frameStyle.labelFor(vm.platform) : 'No screenshot yet',
          muted: !d.hasAnyScreenshot,
          onTap: () => vm.selectElement(d.id),
        ),
      for (final (i, img) in vm.customImageItems.indexed)
        _LayerRow(
          icon: Icons.image_rounded,
          name: 'Image #${i + 1}',
          detail: '${(img.scale * 100).toInt()}% · ${img.rotation.toInt()}°',
          onTap: () => vm.selectElement(img.id),
          thumbnail: img.imageBytes,
        ),
      for (final (i, t) in vm.customTextItems.indexed)
        _LayerRow(
          icon: Icons.text_fields_rounded,
          name: 'Text #${i + 1}',
          detail: t.text,
          onTap: () => vm.selectElement(t.id),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tap an item to edit it. You can also click it directly on the canvas.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}

class _LayerRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String detail;
  final bool muted;
  final VoidCallback onTap;
  final dynamic thumbnail;

  const _LayerRow({
    required this.icon,
    required this.name,
    required this.detail,
    this.muted = false,
    required this.onTap,
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            if (thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(width: 24, height: 24, child: Image.memory(thumbnail, fit: BoxFit.cover)),
              )
            else
              Icon(icon, size: 20, color: muted ? AppColors.textMuted : AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
