
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/library_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'hero_render.dart';

/// Hero for HomeView: headline, subtitle and the two calls to action on the
/// left, the Blender hero render on the right. Below 960 px the render drops
/// under the text at 60 % of the available width.
class HeroSection extends StatelessWidget {
  /// Scrolls the page to the template grid ("Browse templates").
  final VoidCallback? onBrowseTemplates;

  const HeroSection({super.key, this.onBrowseTemplates});

  static const double _twoColumnBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= _twoColumnBreakpoint;
        final Widget copy = _HeroCopy(centered: !wide, onBrowseTemplates: onBrowseTemplates);

        if (wide) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: copy),
                const SizedBox(width: 40),
                const Expanded(flex: 6, child: HeroRender()),
              ],
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            copy,
            const SizedBox(height: 32),
            FractionallySizedBox(widthFactor: 0.6, child: const HeroRender()),
          ],
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final bool centered;
  final VoidCallback? onBrowseTemplates;

  const _HeroCopy({required this.centered, this.onBrowseTemplates});

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    final cross = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Store screenshots,\nmade by hand.',
          textAlign: align,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Lay out your App Store and Google Play screenshots on one canvas. '
            'Free, open source, and nothing leaves your browser.',
            textAlign: align,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: AppDimensions.spacingLg,
          runSpacing: AppDimensions.spacingMd,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ClayButton.primary(
              label: 'Start a project',
              icon: Icons.arrow_forward_rounded,
              size: ClayButtonSize.large,
              ripple: true,
              onPressed: () => context.read<LibraryViewModel>().startNewProject(),
            ),
            ClayButton.text(
              label: 'Browse templates',
              icon: Icons.arrow_downward_rounded,
              onPressed: onBrowseTemplates,
            ),
          ],
        ),
      ],
    );
  }
}

