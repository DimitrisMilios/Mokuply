import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';
import '../../../widgets/shared/color_swatch_button.dart';

class TypographyPanel extends StatelessWidget {
  const TypographyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);

    return SidebarCard(
      title: '4. Headlines & Text',
      icon: Icons.title_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: TextEditingController(text: vm.titleText)..selection = TextSelection.collapsed(offset: vm.titleText.length),
            onChanged: (val) => vm.setTitleText(val),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontMd, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              labelText: 'Main Headline',
              labelStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          TextField(
            controller: TextEditingController(text: vm.subtitleText)..selection = TextSelection.collapsed(offset: vm.subtitleText.length),
            onChanged: (val) => vm.setSubtitleText(val),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontMd, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              labelText: 'Subtitle',
              labelStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              const Text(
                'Headline Font:',
                style: TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: StoreSpecs.fontFamilies.contains(vm.titleFont) ? vm.titleFont : StoreSpecs.fontFamilies.first,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                    items: StoreSpecs.fontFamilies
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (f) {
                      if (f != null) vm.setTitleFont(f);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              const Text(
                'Title Color:',
                style: TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ColorSwatchButton(
                color: vm.textColor,
                onColorChanged: (c) => vm.setTextColor(c),
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
