import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/clay/clay.dart';

/// Floating bottom-centre switch between editing and a clean preview of the
/// strip (no panels, no selection chrome). A sunken clay track with a
/// sliding puck.
class EditorModeBar extends StatelessWidget {
  final bool previewing;
  final ValueChanged<bool> onChanged;

  const EditorModeBar({super.key, required this.previewing, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      radius: 28,
      padding: const EdgeInsets.all(6),
      lift: 14,
      depth: 5,
      child: ClaySegmented<bool>(
        selected: previewing,
        onChanged: onChanged,
        puckColor: AppColors.primary,
        height: 44,
        segments: const [
          ClaySegment(
            value: false,
            label: 'Edit',
            icon: Icons.edit_rounded,
            tooltip: 'Edit the screens',
          ),
          ClaySegment(
            value: true,
            label: 'Preview',
            icon: Icons.visibility_rounded,
            tooltip: 'Preview the strip without panels (Esc to leave)',
          ),
        ],
      ),
    );
  }
}
