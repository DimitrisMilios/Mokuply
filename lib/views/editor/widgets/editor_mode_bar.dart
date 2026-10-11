import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/shared/glass_container.dart';

/// Floating bottom-centre switch between editing and a clean preview of the
/// strip (no panels, no selection chrome).
class EditorModeBar extends StatelessWidget {
  final bool previewing;
  final ValueChanged<bool> onChanged;

  const EditorModeBar({super.key, required this.previewing, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.88,
      blurX: 14,
      blurY: 14,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(4),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            tooltip: 'Edit the screens',
            active: !previewing,
            onTap: () => onChanged(false),
          ),
          _ModeButton(
            icon: Icons.visibility_rounded,
            label: 'Preview',
            tooltip: 'Preview the strip without panels (Esc to leave)',
            active: previewing,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? AppColors.textOnPrimary : AppColors.textPrimary;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
