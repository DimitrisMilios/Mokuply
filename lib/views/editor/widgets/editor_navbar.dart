import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';
import 'export_modal_dialog.dart';
import 'template_builder_dialog.dart';

/// Top header navigation bar for EditorView (Floating Glass Bar).
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
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
      ],
      child: Row(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => vm.goBackToHome(),
                tooltip: 'Back to Store Templates',
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(Icons.art_track_rounded, color: AppColors.textOnPrimary, size: 20),
              ),
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
                  style: const TextStyle(color: AppColors.primary, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Spacer(),
          SegmentedButton<TargetPlatformType>(
            segments: const [
              ButtonSegment(
                value: TargetPlatformType.appStore,
                label: Text('Apple App Store'),
                icon: Icon(Icons.apple, size: 18),
              ),
              ButtonSegment(
                value: TargetPlatformType.googlePlay,
                label: Text('Google Play Store'),
                icon: Icon(Icons.android, size: 18),
              ),
            ],
            selected: {vm.platform},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) {
                vm.setPlatform(selected.first);
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.white.withValues(alpha: 0.6);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.textOnPrimary;
                }
                return AppColors.textPrimary;
              }),
              side: WidgetStateProperty.all(const BorderSide(color: AppColors.glassBorder)),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          TextButton.icon(
            onPressed: () => vm.resetToDefaults(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textPrimary),
            label: const Text('Reset Set', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: AppDimensions.spacingMd),

          // Save / Export Template Builder Button
          OutlinedButton.icon(
            onPressed: () => TemplateBuilderDialog.show(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            ),
            icon: const Icon(Icons.bookmark_add_rounded, size: 18),
            label: const Text('Save Template', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppDimensions.spacingMd),

          // Batch Export Button
          ElevatedButton.icon(
            onPressed: vm.isExporting ? null : () => ExportModalDialog.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              elevation: 3,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            icon: vm.isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: AppColors.textOnPrimary, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 20),
            label: Text(
              vm.isExporting
                  ? 'Exporting ${vm.exportingProgressIndex}/${vm.screenshotsCount}...'
                  : 'Download All (${vm.screenshotsCount}) PNGs',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontLg),
            ),
          ),
        ],
      ),
    );
  }
}
