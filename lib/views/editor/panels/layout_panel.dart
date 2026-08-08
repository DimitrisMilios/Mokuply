import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';

class LayoutPanel extends StatelessWidget {
  const LayoutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);

    return SidebarCard(
      title: '2. Preset Store Layout',
      icon: Icons.dashboard_customize_rounded,
      child: Column(
        children: LayoutMode.values.map((mode) {
          final isSelected = vm.layoutMode == mode;
          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.glassBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                tileColor: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.5),
                title: Text(
                  mode.title,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: AppDimensions.fontMd,
                  ),
                ),
                subtitle: Text(
                  mode.description,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontSm),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                    : null,
                onTap: () => vm.setLayoutMode(mode),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
