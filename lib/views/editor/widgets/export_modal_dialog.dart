import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';
import '../../../services/css_spinner.dart';

class ExportModalDialog extends StatelessWidget {
  const ExportModalDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const ExportModalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: GlassContainer(
        width: 640,
        opacity: 0.95,
        blurX: 24,
        blurY: 24,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 16),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.file_download_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Download Store Screenshots',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select store dimensions for your pixel-perfect PNG export package.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: vm.isExporting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live Export Progress Overlay
            if (vm.isExporting) ...[
              Container(
                key: const ValueKey('export_progress_card'),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SmoothSpinnerWidget(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            vm.exportingStatusText.isNotEmpty
                                ? vm.exportingStatusText
                                : 'Processing Store Package...',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.0,
                        end: vm.exportingTotalSteps > 0
                            ? (vm.exportingProgressIndex / vm.exportingTotalSteps).clamp(0.0, 1.0)
                            : 0.0,
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            key: const ValueKey('export_linear_progress'),
                            value: animValue,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            color: AppColors.primary,
                            minHeight: 6,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 1. BOTH STORES BUNDLE (RECOMMENDED)
            _buildExportOptionCard(
              context: context,
              vm: vm,
              icon: Icons.folder_zip_rounded,
              title: 'Download for Both Stores (ZIP Bundle)',
              badgeText: 'Apple (1320×2868) + Google (1440×2560)',
              description: 'Master ZIP package containing organized folders for both App Store Connect & Google Play Console.',
              isRecommended: true,
              buttonLabel: 'Download Complete Bundle ZIP',
              onTap: () async {
                await vm.exportBothPlatformsPack(context: context);
                if (context.mounted && !vm.isExporting) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Downloading Mokuply_StoreScreenshots_AllPlatforms.zip to Downloads folder!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 14),

            // 2. APPLE APP STORE PACK
            _buildExportOptionCard(
              context: context,
              vm: vm,
              icon: Icons.apple,
              title: 'Apple App Store Only',
              badgeText: '1320 × 2868 px',
              description: 'Formatted for App Store Connect 6.9" Super Retina XDR display specification.',
              isRecommended: false,
              buttonLabel: 'Download Apple ZIP',
              onTap: () async {
                await vm.exportPlatformPack(TargetPlatformType.appStore, context: context);
                if (context.mounted && !vm.isExporting) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Downloading Apple App Store ZIP package to Downloads folder!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 14),

            // 3. GOOGLE PLAY STORE PACK
            _buildExportOptionCard(
              context: context,
              vm: vm,
              icon: Icons.android,
              title: 'Google Play Store Only',
              badgeText: '1440 × 2560 px',
              description: 'High-res portrait export formatted for Google Play Store Console submission.',
              isRecommended: false,
              buttonLabel: 'Download Google ZIP',
              onTap: () async {
                await vm.exportPlatformPack(TargetPlatformType.googlePlay, context: context);
                if (context.mounted && !vm.isExporting) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Downloading Google Play Store ZIP package to Downloads folder!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionCard({
    required BuildContext context,
    required EditorViewModel vm,
    required IconData icon,
    required String title,
    required String badgeText,
    required String description,
    required bool isRecommended,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecommended
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isRecommended ? AppColors.primary : AppColors.glassBorder,
          width: isRecommended ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRecommended ? AppColors.primary : Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isRecommended ? Colors.white : AppColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: vm.isExporting ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecommended ? AppColors.primary : Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
