import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'inspector_target.dart';

/// Screen name, "n/total" and the collapse button.
class InspectorHeader extends StatelessWidget {
  final InspectorFocus selection;
  final VoidCallback onCollapse;

  const InspectorHeader({super.key, required this.selection, required this.onCollapse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 4),
      child: Row(
        children: [
          const Icon(Icons.crop_portrait_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selection.screenName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            '${selection.screenIndex + 1}/${selection.screenCount}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          ClayIconButton(
            icon: Icons.keyboard_double_arrow_right_rounded,
            tooltip: 'Collapse inspector',
            size: 32,
            iconSize: 18,
            flat: true,
            iconColor: AppColors.primary,
            onPressed: onCollapse,
          ),
        ],
      ),
    );
  }
}

/// Icon, title and hint of what is being edited, with a "back to screen" button.
class InspectorTargetRow extends StatelessWidget {
  final InspectorTarget target;
  final bool elementSelected;

  const InspectorTargetRow({super.key, required this.target, required this.elementSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClayContainer(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const ClayDecoration.well(radius: 12, depth: 4),
          child: Icon(target.icon, color: AppColors.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                target.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppDimensions.fontBody,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                target.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (elementSelected)
          ClayIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Back to screen settings (Esc)',
            size: 28,
            iconSize: 16,
            radius: 10,
            flat: true,
            iconColor: AppColors.textMuted,
            onPressed: () => context.read<EditorViewModel>().selectElement(null),
          ),
      ],
    );
  }
}

/// The outgoing body of the crossfade stays mounted for a moment after the
/// selection changes. If its element was just deleted, build nothing instead
/// of asking a panel for an element that no longer exists.
class InspectorSafeBody extends StatelessWidget {
  final String? elementId;
  final Widget child;

  const InspectorSafeBody({super.key, required this.elementId, required this.child});

  @override
  Widget build(BuildContext context) {
    final id = elementId;
    if (id == null) return child;
    final exists = context.select<EditorViewModel, bool>((vm) => vm.elementExists(id));
    return exists ? child : const SizedBox.shrink();
  }
}

/// "LAYERS"-style section label with an optional trailing control.
class InspectorSectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const InspectorSectionHeader({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        children: [
          Expanded(child: ClayLabel(label)),
          ?trailing,
        ],
      ),
    );
  }
}
