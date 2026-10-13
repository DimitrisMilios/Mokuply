import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';

/// Narrow left rail with the essential actions. Adding something selects it,
/// so the inspector on the right opens its controls immediately.
///
/// Each action is a 56 px clay tile: raised when idle, sunken when active.
/// The icons are Blender clay renders from `assets/clay/icon_<name>.png`,
/// with Material icons as the fallback until the renders land.
class ActionRail extends StatelessWidget {
  static const double width = AppDimensions.railWidth;

  const ActionRail({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    final motion = ClayMotion.of(context);
    final bool nothingSelected = vm.selectedElementId == null;

    final items = <Widget>[
      const _RailSectionLabel('Add'),
      _RailButton(
        asset: 'frame',
        icon: Icons.smartphone_rounded,
        label: 'Frame',
        tooltip: 'Add a phone frame',
        onTap: () => vm.addDeviceFrame(),
      ),
      _RailButton(
        asset: 'text',
        icon: Icons.text_fields_rounded,
        label: 'Text',
        tooltip: 'Add a text element',
        onTap: () => vm.addCustomTextElement(),
      ),
      _RailButton(
        asset: 'image',
        icon: Icons.add_photo_alternate_rounded,
        label: 'Image',
        tooltip: 'Add a logo, badge or graphic',
        onTap: () => vm.pickAndAddCustomImageItem(),
      ),
      _RailButton(
        asset: 'upload',
        icon: Icons.upload_rounded,
        label: 'Shot',
        tooltip: 'Upload a ${vm.platform.screenshotLabel} screenshot into the selected frame',
        onTap: () => vm.uploadScreenshotToSelectedFrame(),
      ),
      const _RailGap(),
      const _RailSectionLabel('Screen'),
      _RailButton(
        asset: 'layout',
        icon: Icons.dashboard_customize_rounded,
        label: 'Layout',
        tooltip: 'Layout presets',
        active: nothingSelected && vm.screenSection == ScreenInspectorSection.layout,
        onTap: () => vm.showScreenSection(ScreenInspectorSection.layout),
      ),
      _RailButton(
        asset: 'backdrop',
        icon: Icons.palette_rounded,
        label: 'Backdrop',
        tooltip: 'Background colour, gradient or image',
        active: nothingSelected && vm.screenSection == ScreenInspectorSection.background,
        onTap: () => vm.showScreenSection(ScreenInspectorSection.background),
      ),
      const _RailGap(),
      const _RailSectionLabel('View'),
      _RailButton(
        asset: vm.showBothStores ? 'rows_both' : 'rows_one',
        icon: vm.showBothStores ? Icons.view_agenda_rounded : Icons.crop_portrait_rounded,
        label: vm.showBothStores ? 'Both' : 'One',
        tooltip: vm.showBothStores
            ? 'Showing both stores as rows. Click to show only the active store.'
            : 'Showing the ${vm.platform.shortName} only. Click to show both stores.',
        active: vm.showBothStores,
        onTap: () => vm.setShowBothStores(!vm.showBothStores),
      ),
      const _RailGap(),
      _RailButton(
        asset: 'reset',
        icon: Icons.restart_alt_rounded,
        label: 'Reset',
        tooltip: 'Reset positions, sizes and tilts on this screen',
        onTap: () => vm.resetCanvasOffsets(),
      ),
    ];

    // Buttons stagger in top to bottom; the first one waits for the rail
    // itself to arrive (the editor staggers the panels 35 ms apart, and the
    // rail is second in line).
    var staggerIndex = 4;

    return ClayPanel(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (final item in items)
              if (item is _RailButton)
                ClayStagger(index: staggerIndex++, delay: motion.stagger, rise: 8, child: item)
              else
                item,
          ],
        ),
      ),
    );
  }
}

class _RailSectionLabel extends StatelessWidget {
  final String text;
  const _RailSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return ClayLabel(text, padding: const EdgeInsets.only(top: 2, bottom: 6));
  }
}

class _RailGap extends StatelessWidget {
  const _RailGap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 16);
}

class _RailButton extends StatelessWidget {
  /// Name of the Blender clay icon: `assets/clay/icon_<asset>.png`.
  final String asset;
  final IconData icon;
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _RailButton({
    required this.asset,
    required this.icon,
    required this.label,
    required this.tooltip,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? AppColors.primary : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClayIconButton(
            size: 56,
            iconSize: 28,
            radius: AppDimensions.radiusClaySm + 2,
            active: active,
            tooltip: tooltip,
            onPressed: onTap,
            image: Image.asset(
              'assets/clay/icon_$asset.png',
              width: 28,
              height: 28,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => Icon(icon, size: 28, color: iconColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
