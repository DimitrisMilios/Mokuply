import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';

/// Narrow left rail with the essential actions. Adding something selects it,
/// so the inspector on the right opens its controls immediately.
class ActionRail extends StatelessWidget {
  static const double width = 76.0;

  const ActionRail({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    final bool nothingSelected = vm.selectedElementId == null;

    return GlassContainer(
      width: width,
      opacity: 0.85,
      blurX: 16.0,
      blurY: 16.0,
      borderRadius: BorderRadius.circular(AppDimensions.radiusGlassLg),
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.symmetric(vertical: 10),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 28,
          spreadRadius: 2,
          offset: const Offset(0, 10),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          children: [
            _RailSectionLabel('Add'),
            _RailButton(
              icon: Icons.smartphone_rounded,
              label: 'Frame',
              tooltip: 'Add a phone frame',
              onTap: () => vm.addDeviceFrame(),
            ),
            _RailButton(
              icon: Icons.text_fields_rounded,
              label: 'Text',
              tooltip: 'Add a text element',
              onTap: () => vm.addCustomTextElement(),
            ),
            _RailButton(
              icon: Icons.add_photo_alternate_rounded,
              label: 'Image',
              tooltip: 'Add a logo, badge or graphic',
              onTap: () => vm.pickAndAddCustomImageItem(),
            ),
            _RailButton(
              icon: Icons.upload_rounded,
              label: 'Shot',
              tooltip: 'Upload a ${vm.platform.screenshotLabel} screenshot into the selected frame',
              onTap: () => vm.uploadScreenshotToSelectedFrame(),
            ),
            const _RailDivider(),
            _RailSectionLabel('Screen'),
            _RailButton(
              icon: Icons.dashboard_customize_rounded,
              label: 'Layout',
              tooltip: 'Layout presets',
              active: nothingSelected && vm.screenSection == ScreenInspectorSection.layout,
              onTap: () => vm.showScreenSection(ScreenInspectorSection.layout),
            ),
            _RailButton(
              icon: Icons.palette_rounded,
              label: 'Backdrop',
              tooltip: 'Background colour, gradient or image',
              active: nothingSelected && vm.screenSection == ScreenInspectorSection.background,
              onTap: () => vm.showScreenSection(ScreenInspectorSection.background),
            ),
            _RailButton(
              icon: Icons.layers_rounded,
              label: 'Layers',
              tooltip: 'Everything on this screen',
              active: nothingSelected && vm.screenSection == ScreenInspectorSection.layers,
              onTap: () => vm.showScreenSection(ScreenInspectorSection.layers),
            ),
            const _RailDivider(),
            _RailButton(
              icon: Icons.restart_alt_rounded,
              label: 'Reset',
              tooltip: 'Reset positions, sizes and tilts on this screen',
              onTap: () => vm.resetCanvasOffsets(),
            ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _RailDivider extends StatelessWidget {
  const _RailDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.glassBorder, height: 14, indent: 14, endIndent: 14);
  }
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _RailButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          width: 60,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: active ? AppColors.textOnPrimary : AppColors.primary),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.textOnPrimary : AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
