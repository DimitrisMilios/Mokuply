import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';
import '../../../widgets/shared/brand_logo.dart';
import 'export_modal_dialog.dart';
import 'template_builder_dialog.dart';

/// Top header navigation bar for EditorView (floating glass bar).
///
/// Adapts to the available width: full labels on wide windows, short labels
/// on medium ones, and icon-only controls with tooltips on narrow ones, so it
/// never overflows.
class EditorNavbar extends StatelessWidget {
  const EditorNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();

    return GlassContainer(
      height: AppDimensions.navbarHeight,
      opacity: 0.85,
      blurX: 16.0,
      blurY: 16.0,
      borderRadius: BorderRadius.circular(AppDimensions.radiusGlassLg),
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool wide = width >= 1280;
          final bool medium = width >= 940;
          final bool showBrand = width >= 700;

          return Row(
            children: [
              // Left cluster: back, logo, brand, screen count
              IconButton(
                onPressed: () => vm.goBackToHome(),
                tooltip: 'Back to Store Templates',
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              const BrandLogo(size: 36, radius: AppDimensions.radiusMd),
              if (showBrand) ...[
                const SizedBox(width: AppDimensions.spacingMd),
                const Text(
                  'Mocuply',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
              if (medium) ...[
                const SizedBox(width: AppDimensions.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${vm.screenshotsCount} Screenshots Set',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),

              // Active store switch
              Tooltip(
                message: 'Active store: uploads and single-store downloads target it.\n'
                    'Both stores are shown as rows on the canvas and always exported.',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (wide) ...[
                      const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      const Text(
                        'Active store',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: AppDimensions.fontSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                    ],
                    SegmentedButton<TargetPlatformType>(
                      segments: [
                        ButtonSegment(
                          value: TargetPlatformType.appStore,
                          label: medium ? Text(wide ? 'App Store · ${TargetPlatformType.appStore.dimensionsLabel}' : 'App Store') : null,
                          icon: const Icon(Icons.apple, size: 18),
                          tooltip: 'App Store (${TargetPlatformType.appStore.dimensionsLabel})',
                        ),
                        ButtonSegment(
                          value: TargetPlatformType.googlePlay,
                          label: medium ? Text(wide ? 'Google Play · ${TargetPlatformType.googlePlay.dimensionsLabel}' : 'Google Play') : null,
                          icon: const Icon(Icons.android, size: 18),
                          tooltip: 'Google Play (${TargetPlatformType.googlePlay.dimensionsLabel})',
                        ),
                      ],
                      selected: {vm.platform},
                      showSelectedIcon: false,
                      onSelectionChanged: (selected) {
                        if (selected.isNotEmpty) vm.setPlatform(selected.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          return states.contains(WidgetState.selected)
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.6);
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          return states.contains(WidgetState.selected) ? AppColors.textOnPrimary : AppColors.textPrimary;
                        }),
                        side: WidgetStateProperty.all(const BorderSide(color: AppColors.glassBorder)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: medium ? AppDimensions.spacingLg : AppDimensions.spacingSm),

              // Reset
              _NavAction(
                icon: Icons.refresh_rounded,
                label: 'Reset Set',
                showLabel: wide,
                onPressed: () => vm.resetToDefaults(),
                style: _NavActionStyle.text,
              ),
              SizedBox(width: medium ? AppDimensions.spacingMd : AppDimensions.spacingXs),

              // Save template
              _NavAction(
                icon: Icons.bookmark_add_rounded,
                label: 'Save Template',
                showLabel: medium,
                onPressed: () => TemplateBuilderDialog.show(context),
                style: _NavActionStyle.outlined,
              ),
              SizedBox(width: medium ? AppDimensions.spacingMd : AppDimensions.spacingXs),

              // Export
              _NavAction(
                icon: Icons.download_rounded,
                label: vm.isExporting
                    ? 'Exporting ${vm.exportingProgressIndex}/${vm.exportingTotalSteps}...'
                    : (wide ? 'Download All (${vm.screenshotsCount}) PNGs' : 'Download (${vm.screenshotsCount})'),
                showLabel: medium,
                busy: vm.isExporting,
                onPressed: vm.isExporting ? null : () => ExportModalDialog.show(context),
                style: _NavActionStyle.filled,
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _NavActionStyle { text, outlined, filled }

/// A navbar button that collapses to an icon with a tooltip when space is tight.
class _NavAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showLabel;
  final bool busy;
  final VoidCallback? onPressed;
  final _NavActionStyle style;

  const _NavAction({
    required this.icon,
    required this.label,
    required this.showLabel,
    this.busy = false,
    required this.onPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: AppColors.textOnPrimary, strokeWidth: 2),
          )
        : Icon(icon, size: 18);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd));
    final labelWidget = Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontMd));

    Widget button;
    switch (style) {
      case _NavActionStyle.text:
        button = showLabel
            ? TextButton.icon(
                onPressed: onPressed,
                style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
                icon: iconWidget,
                label: labelWidget,
              )
            : IconButton(
                onPressed: onPressed,
                color: AppColors.textPrimary,
                icon: iconWidget,
              );
        break;
      case _NavActionStyle.outlined:
        final buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 16 : 10, vertical: 16),
          shape: shape,
        );
        button = showLabel
            ? OutlinedButton.icon(onPressed: onPressed, style: buttonStyle, icon: iconWidget, label: labelWidget)
            : OutlinedButton(onPressed: onPressed, style: buttonStyle, child: iconWidget);
        break;
      case _NavActionStyle.filled:
        final buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 20 : 12, vertical: 16),
          shape: shape,
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        );
        button = showLabel
            ? ElevatedButton.icon(onPressed: onPressed, style: buttonStyle, icon: iconWidget, label: labelWidget)
            : ElevatedButton(onPressed: onPressed, style: buttonStyle, child: iconWidget);
        break;
    }

    return showLabel ? button : Tooltip(message: label, child: button);
  }
}
