import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'background_panel.dart';

/// Shown when nothing on the canvas is selected: layout presets, background,
/// and screen-level actions. (Layers are listed above, in the inspector.)
class ScreenInspector extends StatelessWidget {
  const ScreenInspector({super.key});

  @override
  Widget build(BuildContext context) {
    final (index, count, section, layout) =
        context.select<EditorViewModel, (int, int, ScreenInspectorSection, LayoutMode)>(
      (vm) => (vm.selectedIndex, vm.screenshotsCount, vm.screenSection, vm.layoutMode),
    );
    final vm = context.read<EditorViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Screen actions
        Row(
          children: [
            Expanded(
              child: ClayButton.neutral(
                label: 'Duplicate',
                icon: Icons.copy_rounded,
                size: ClayButtonSize.compact,
                expand: true,
                onPressed: () => vm.duplicateScreenshot(index),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClayButton.neutral(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                size: ClayButtonSize.compact,
                expand: true,
                textColor: AppColors.coralDeep,
                onPressed: count > 1 ? () => vm.removeScreenshot(index) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Section switch
        ClaySegmented<ScreenInspectorSection>(
          expand: true,
          segments: const [
            ClaySegment(
              value: ScreenInspectorSection.layout,
              label: 'Layout',
              icon: Icons.dashboard_customize_rounded,
            ),
            ClaySegment(
              value: ScreenInspectorSection.background,
              label: 'Backdrop',
              icon: Icons.palette_rounded,
            ),
          ],
          selected: section,
          onChanged: vm.showScreenSection,
        ),
        const SizedBox(height: 16),

        switch (section) {
          ScreenInspectorSection.layout => _LayoutSection(layout: layout, onChanged: vm.setLayoutMode),
          ScreenInspectorSection.background => const BackgroundSection(),
        },
      ],
    );
  }
}

class _LayoutSection extends StatelessWidget {
  final LayoutMode layout;
  final ValueChanged<LayoutMode> onChanged;
  const _LayoutSection({required this.layout, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Presets move the headline and phone. Drag to adjust.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 10),
        ClayWell(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final mode in LayoutMode.values)
                Padding(
                  padding: EdgeInsets.only(bottom: mode == LayoutMode.values.last ? 0 : 4),
                  child: _PresetTile(
                    mode: mode,
                    selected: layout == mode,
                    onTap: () => onChanged(mode),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  final LayoutMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClayTile(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode.title,
            style: TextStyle(
              color: selected ? AppColors.primaryDeep : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            mode.description,
            style: TextStyle(
              color: selected ? AppColors.textSecondary : AppColors.textMuted,
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
