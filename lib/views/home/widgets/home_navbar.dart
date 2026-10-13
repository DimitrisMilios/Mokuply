import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/brand_logo.dart';

/// Floating sticky top header for HomeView: a clay panel with the logo tile,
/// the wordmark and a gold "Start project" button.
class HomeNavbar extends StatelessWidget {
  const HomeNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0, bottom: 8.0),
      child: ClayPanel(
        height: AppDimensions.navbarHeight,
        radius: AppDimensions.radiusClayXl,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool showStartLabel = constraints.maxWidth >= 480;
            final bool showWordmark = constraints.maxWidth >= 360;
            void start() => context.read<EditorViewModel>().openEditorWithNewProject();

            return Row(
              children: [
                const BrandLogo(size: 40, radius: AppDimensions.radiusMd),
                if (showWordmark) ...[
                  const SizedBox(width: AppDimensions.spacingMd),
                  const Text(
                    'Mockuply',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppDimensions.fontXl,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
                const Spacer(),
                if (showStartLabel)
                  ClayButton.gold(
                    label: 'Start project',
                    icon: Icons.rocket_launch_rounded,
                    onPressed: start,
                  )
                else
                  ClayIconButton(
                    icon: Icons.rocket_launch_rounded,
                    tooltip: 'Start project',
                    color: AppColors.gold,
                    size: 44,
                    radius: 22,
                    onPressed: start,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
