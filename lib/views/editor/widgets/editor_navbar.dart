import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/brand_logo.dart';
import 'export_modal_dialog.dart';
import 'template_builder_dialog.dart';

/// Top header navigation bar for EditorView (floating clay bar).
///
/// Adapts to the available width: full labels on wide windows, short labels
/// on medium ones, and icon-only controls with tooltips on narrow ones, so it
/// never overflows.
class EditorNavbar extends StatelessWidget {
  const EditorNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();

    return ClayPanel(
      height: AppDimensions.navbarHeight,
      radius: AppDimensions.radiusClayXl,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool wide = width >= 1280;
          final bool medium = width >= 940;
          final bool showBrand = width >= 700;

          final storeSwitch = Tooltip(
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                ],
                ClaySegmented<TargetPlatformType>(
                  selected: vm.platform,
                  onChanged: vm.setPlatform,
                  puckColor: AppColors.primary,
                  height: 40,
                  segments: [
                    ClaySegment(
                      value: TargetPlatformType.appStore,
                      icon: Icons.apple,
                      label: medium ? 'App Store' : null,
                      tooltip: 'App Store (${TargetPlatformType.appStore.dimensionsLabel})',
                    ),
                    ClaySegment(
                      value: TargetPlatformType.googlePlay,
                      icon: Icons.android,
                      label: medium ? 'Google Play' : null,
                      tooltip: 'Google Play (${TargetPlatformType.googlePlay.dimensionsLabel})',
                    ),
                  ],
                ),
              ],
            ),
          );

          final count = vm.screenshotsCount;
          final exporting = vm.isExporting;
          final progress = '${vm.exportingProgressIndex}/${vm.exportingTotalSteps}';

          return Row(
            children: [
              // Left cluster: back, logo, wordmark
              ClayIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back to templates',
                size: 40,
                iconSize: 20,
                iconColor: AppColors.primary,
                onPressed: () => vm.goBackToHome(),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              const BrandLogo(size: 36, radius: AppDimensions.radiusMd),
              if (showBrand) ...[
                const SizedBox(width: AppDimensions.spacingMd),
                const Text(
                  'Mockuply',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
              const Spacer(),

              // Active store switch
              storeSwitch,
              SizedBox(width: medium ? AppDimensions.spacingLg : AppDimensions.spacingSm),

              // Reset
              if (wide)
                ClayButton.text(
                  label: 'Reset set',
                  icon: Icons.refresh_rounded,
                  onPressed: () => vm.resetToDefaults(),
                )
              else
                ClayIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Reset set',
                  flat: true,
                  iconColor: AppColors.textSecondary,
                  onPressed: () => vm.resetToDefaults(),
                ),
              SizedBox(width: medium ? AppDimensions.spacingMd : AppDimensions.spacingXs),

              // Save template
              if (medium)
                ClayButton.neutral(
                  label: 'Save template',
                  icon: Icons.bookmark_add_rounded,
                  onPressed: () => TemplateBuilderDialog.show(context),
                )
              else
                ClayIconButton(
                  icon: Icons.bookmark_add_rounded,
                  tooltip: 'Save template',
                  size: 44,
                  iconSize: 20,
                  onPressed: () => TemplateBuilderDialog.show(context),
                ),
              SizedBox(width: medium ? AppDimensions.spacingMd : AppDimensions.spacingSm),

              // Download
              if (medium)
                ClayButton.primary(
                  label: 'Download ($count)',
                  icon: Icons.download_rounded,
                  busy: exporting,
                  busyLabel: 'Exporting $progress',
                  onPressed: exporting ? null : () => ExportModalDialog.show(context),
                )
              else
                Tooltip(
                  message: 'Download ($count)',
                  child: ClayButton.primary(
                    label: '$count',
                    icon: Icons.download_rounded,
                    busy: exporting,
                    busyLabel: progress,
                    onPressed: exporting ? null : () => ExportModalDialog.show(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
