import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';

/// Floating sticky top header navigation bar for HomeView.
class HomeNavbar extends StatelessWidget {
  const HomeNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0, bottom: 8.0),
      child: GlassContainer(
        height: AppDimensions.navbarHeight,
        opacity: 0.8,
        blurX: 16,
        blurY: 16,
        borderRadius: BorderRadius.circular(AppDimensions.radiusGlassLg),
        borderColor: AppColors.glassBorder,
        boxShadow: [
          BoxShadow(color: AppColors.glassShadow, blurRadius: 24, spreadRadius: 0, offset: const Offset(0, 8)),
        ],
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool showBadge = constraints.maxWidth >= 720;
            final bool showStartLabel = constraints.maxWidth >= 480;
            return Row(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.art_track_rounded, color: AppColors.textOnPrimary, size: 22),
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
                    if (showBadge) ...[
                      const SizedBox(width: AppDimensions.spacingMd),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.badgeBg,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          '100% Free & Client-Side',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final style = ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: EdgeInsets.symmetric(horizontal: showStartLabel ? 24 : 14, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                      elevation: 3,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    );
                    void start() => context.read<EditorViewModel>().openEditorWithNewProject();
                    const icon = Icon(Icons.rocket_launch_rounded, size: 18);
                    if (!showStartLabel) {
                      return Tooltip(
                        message: 'Start Project',
                        child: ElevatedButton(onPressed: start, style: style, child: icon),
                      );
                    }
                    return ElevatedButton.icon(
                      onPressed: start,
                      style: style,
                      icon: icon,
                      label: const Text(
                        'Start Project',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontMd),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
