import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/library_viewmodel.dart';
import '../../../widgets/clay/clay.dart';

/// "You have an unfinished project" with Resume / Discard. Hidden when
/// there is no draft.
class SavedDraftBanner extends StatelessWidget {
  const SavedDraftBanner({super.key});

  static const String _iconAsset = 'assets/clay/icon_history.png';

  @override
  Widget build(BuildContext context) {
    final hasDraft = context.select<LibraryViewModel, bool>((lib) => lib.hasSavedDraft);
    if (!hasDraft) return const SizedBox.shrink();
    final library = context.read<LibraryViewModel>();

    final Widget iconTile = Image.asset(
      _iconAsset,
      width: 40,
      height: 40,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const ClayContainer(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: ClayDecoration.gold(radius: 14, depth: 4, lift: 8),
        child: Icon(Icons.history_rounded, color: AppColors.textPrimary, size: 22),
      ),
    );

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'You have an unfinished project',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontLg,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'It is saved in this browser.',
          style: TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w600),
        ),
      ],
    );

    final List<Widget> actions = [
      ClayButton.text(label: 'Discard', onPressed: () => library.discardSavedDraft()),
      const SizedBox(width: 8),
      ClayButton.primary(label: 'Resume', icon: Icons.play_arrow_rounded, onPressed: () => library.restoreSavedDraft()),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ClayPanel(
        radius: AppDimensions.radiusClayLg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 560;
            if (wide) {
              return Row(
                children: [
                  iconTile,
                  const SizedBox(width: 14),
                  Expanded(child: text),
                  const SizedBox(width: 12),
                  ...actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconTile,
                    const SizedBox(width: 14),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
              ],
            );
          },
        ),
      ),
    );
  }
}
