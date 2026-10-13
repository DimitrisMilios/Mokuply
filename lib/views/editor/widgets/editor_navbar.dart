import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../viewmodels/export_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/brand_logo.dart';
import '../export/export_modal_dialog.dart';
import '../templates/template_builder_dialog.dart';

/// Top header navigation bar for EditorView (floating clay bar).
///
/// Adapts to the available width: full labels on wide windows, short labels
/// on medium ones, and icon-only controls with tooltips on narrow ones, so it
/// never overflows.
class EditorNavbar extends StatelessWidget {
  const EditorNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditorViewModel>();
    return ClayPanel(
      height: AppDimensions.navbarHeight,
      radius: AppDimensions.radiusClayXl,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool wide = width >= 1280;
          final bool medium = width >= 940;

          return Row(
            children: [
              ClayIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back to templates',
                size: 40,
                iconSize: 20,
                iconColor: AppColors.primary,
                onPressed: vm.goBackToHome,
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              const BrandLogo(size: 36, radius: AppDimensions.radiusMd),
              if (width >= 700) ...[const SizedBox(width: AppDimensions.spacingMd), const _Wordmark()],
              const Spacer(),
              _StoreSwitch(wide: wide, medium: medium),
              SizedBox(width: medium ? AppDimensions.spacingLg : AppDimensions.spacingSm),
              if (wide)
                ClayButton.text(label: 'Reset set', icon: Icons.refresh_rounded, onPressed: vm.resetToDefaults)
              else
                ClayIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Reset set',
                  flat: true,
                  iconColor: AppColors.textSecondary,
                  onPressed: vm.resetToDefaults,
                ),
              SizedBox(width: medium ? AppDimensions.spacingMd : AppDimensions.spacingXs),
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
              _DownloadButton(medium: medium),
            ],
          );
        },
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Mockuply',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: AppDimensions.fontXl,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
      ),
    );
  }
}

/// App Store / Google Play switch for the active store.
class _StoreSwitch extends StatelessWidget {
  final bool wide;
  final bool medium;

  const _StoreSwitch({required this.wide, required this.medium});

  @override
  Widget build(BuildContext context) {
    final platform = context.select<EditorViewModel, TargetPlatformType>((vm) => vm.platform);
    return Tooltip(
      message:
          'Active store: uploads and single-store downloads target it.\n'
          'Both stores are shown as rows on the canvas and always exported.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wide) ...[
            const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            const Text(
              'Active store',
              style: TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
          ],
          ClaySegmented<TargetPlatformType>(
            selected: platform,
            onChanged: context.read<EditorViewModel>().setPlatform,
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
  }
}

/// "Download (n)": opens the export dialog, shows progress while exporting.
class _DownloadButton extends StatelessWidget {
  final bool medium;

  const _DownloadButton({required this.medium});

  @override
  Widget build(BuildContext context) {
    final count = context.select<EditorViewModel, int>((vm) => vm.screenshotsCount);
    final export = context.watch<ExportViewModel>();
    final exporting = export.isExporting;
    final progress = '${export.progressIndex}/${export.totalSteps}';
    final VoidCallback? open = exporting ? null : () => ExportModalDialog.show(context);

    if (medium) {
      return ClayButton.primary(
        label: 'Download ($count)',
        icon: Icons.download_rounded,
        busy: exporting,
        busyLabel: 'Exporting $progress',
        onPressed: open,
      );
    }
    return Tooltip(
      message: 'Download ($count)',
      child: ClayButton.primary(
        label: '$count',
        icon: Icons.download_rounded,
        busy: exporting,
        busyLabel: progress,
        onPressed: open,
      ),
    );
  }
}
