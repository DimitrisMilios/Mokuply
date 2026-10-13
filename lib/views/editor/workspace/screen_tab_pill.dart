import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/clay/clay.dart';
import 'workspace_layout.dart';

/// The look of a screen tab: flat (a faint mint on hover) when idle, a
/// raised clay pill when selected. [selection] runs 0 → 1 with a spring.
class ScreenTabPill extends StatelessWidget {
  final int index;
  final double hover;
  final double press;
  final double selection;

  /// The name, or the rename field while editing.
  final Widget Function(Color foreground) label;

  /// The "…" options button; null in preview mode.
  final Widget Function(Color foreground)? trailing;

  const ScreenTabPill({
    super.key,
    required this.index,
    required this.hover,
    required this.press,
    required this.selection,
    required this.label,
    this.trailing,
  });

  static const double _radius = WorkspaceLayout.tabPillHeight / 2;

  @override
  Widget build(BuildContext context) {
    final double t = selection.clamp(0.0, 1.2);
    final raised = ClayDecoration(
      color: AppColors.clay,
      radius: _radius,
      depth: 4,
      lift: 8,
      pressed: press.clamp(0.0, 1.0),
      shadowOpacity: 0.18,
      edgeOpacity: 0.10,
    );
    final idle = ClayDecoration(
      color: AppColors.mint.withValues(alpha: 0.4 * hover.clamp(0.0, 1.0)),
      radius: _radius,
      depth: 4,
      lift: 0,
      shadowOpacity: 0,
      highlightOpacity: 0,
      shadeOpacity: 0,
      edgeOpacity: 0,
    );
    final Color fg = Color.lerp(AppColors.textMuted, AppColors.textPrimary, t.clamp(0.0, 1.0))!;

    return Container(
      height: WorkspaceLayout.tabPillHeight,
      padding: const EdgeInsets.only(left: 12, right: 3),
      decoration: ClayDecoration.lerp(idle, raised, t),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: TextStyle(
              color: fg.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: label(fg)),
          if (trailing != null) trailing!(fg),
        ],
      ),
    );
  }
}
