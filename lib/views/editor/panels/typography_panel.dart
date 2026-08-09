import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_text_item.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';
import '../../../widgets/shared/color_swatch_button.dart';
import '../../../widgets/shared/labeled_slider.dart';

class TypographyPanel extends StatelessWidget {
  const TypographyPanel({super.key});

  static const Map<String, FontWeight> _weightOptions = {
    'Light': FontWeight.w300,
    'Regular': FontWeight.w400,
    'Medium': FontWeight.w500,
    'SemiBold': FontWeight.w600,
    'Bold': FontWeight.w700,
    'ExtraBold': FontWeight.w800,
    'Black': FontWeight.w900,
  };

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);

    return SidebarCard(
      title: '4. Headlines & Canvas Text',
      icon: Icons.title_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. MAIN TITLE ELEMENT SECTION
          _buildSectionHeader(
            title: '1. Main Title',
            icon: Icons.text_fields_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            label: 'Title Text',
            initialText: vm.titleText,
            onChanged: (val) => vm.setTitleText(val),
          ),
          const SizedBox(height: 10),
          _buildFontDropdownRow(
            label: 'Font Family',
            currentFont: vm.titleFont,
            onChanged: (f) => vm.setTitleFont(f),
          ),
          const SizedBox(height: 10),
          LabeledSlider(
            label: 'Title Size',
            valueText: '${vm.titleSize.toInt()}px',
            value: vm.titleSize,
            min: 28,
            max: 120,
            onChanged: (val) => vm.setTitleSize(val),
          ),
          const SizedBox(height: 10),
          _buildWeightAndColorRow(
            currentWeight: vm.titleWeight,
            currentColor: vm.textColor,
            currentAlignment: vm.titleAlignment,
            onWeightChanged: (w) => vm.setTitleWeight(w),
            onColorChanged: (c) => vm.setTextColor(c),
            onAlignmentChanged: (a) => vm.setTitleAlignment(a),
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 16),

          // 2. SUBTITLE ELEMENT SECTION
          _buildSectionHeader(
            title: '2. Subtitle',
            icon: Icons.notes_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            label: 'Subtitle Text',
            initialText: vm.subtitleText,
            onChanged: (val) => vm.setSubtitleText(val),
          ),
          const SizedBox(height: 10),
          _buildFontDropdownRow(
            label: 'Font Family',
            currentFont: vm.subtitleFont,
            onChanged: (f) => vm.setSubtitleFont(f),
          ),
          const SizedBox(height: 10),
          LabeledSlider(
            label: 'Subtitle Size',
            valueText: '${vm.subtitleSize.toInt()}px',
            value: vm.subtitleSize,
            min: 16,
            max: 72,
            onChanged: (val) => vm.setSubtitleSize(val),
          ),
          const SizedBox(height: 10),
          _buildWeightAndColorRow(
            currentWeight: vm.subtitleWeight,
            currentColor: vm.subtitleColor,
            currentAlignment: vm.subtitleAlignment,
            onWeightChanged: (w) => vm.setSubtitleWeight(w),
            onColorChanged: (c) => vm.setSubtitleColor(c),
            onAlignmentChanged: (a) => vm.setSubtitleAlignment(a),
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 16),

          // 3. EXTRA CUSTOM TEXT ELEMENTS SECTION
          Row(
            children: [
              const Icon(Icons.add_comment_rounded, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              const Text(
                '3. Extra Canvas Text',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => vm.addCustomTextElement(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('+ Add Text', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (vm.customTextItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Text(
                'Click "+ Add Text" to add extra captions, badges, or body text elements on the canvas!',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.customTextItems.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final item = vm.customTextItems[idx];
                return _buildCustomTextCard(ctx, vm, item, idx + 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required String initialText, required ValueChanged<String> onChanged}) {
    return TextField(
      controller: TextEditingController(text: initialText)..selection = TextSelection.collapsed(offset: initialText.length),
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontMd, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildFontDropdownRow({required String label, required String currentFont, required ValueChanged<String> onChanged}) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: StoreSpecs.fontFamilies.contains(currentFont) ? currentFont : StoreSpecs.fontFamilies.first,
              dropdownColor: Colors.white,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
              items: StoreSpecs.fontFamilies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (f) {
                if (f != null) onChanged(f);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightAndColorRow({
    required FontWeight currentWeight,
    required Color currentColor,
    required TextAlign currentAlignment,
    required ValueChanged<FontWeight> onWeightChanged,
    required ValueChanged<Color> onColorChanged,
    required ValueChanged<TextAlign> onAlignmentChanged,
  }) {
    final currentWeightName = _weightOptions.entries.firstWhere(
      (e) => e.value == currentWeight,
      orElse: () => _weightOptions.entries.first,
    ).key;

    return Row(
      children: [
        // Weight Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentWeightName,
              dropdownColor: Colors.white,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 18),
              items: _weightOptions.keys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (k) {
                if (k != null && _weightOptions.containsKey(k)) {
                  onWeightChanged(_weightOptions[k]!);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Alignment Toggle
        Row(
          children: [
            _buildAlignButton(Icons.format_align_left_rounded, TextAlign.left, currentAlignment, onAlignmentChanged),
            _buildAlignButton(Icons.format_align_center_rounded, TextAlign.center, currentAlignment, onAlignmentChanged),
            _buildAlignButton(Icons.format_align_right_rounded, TextAlign.right, currentAlignment, onAlignmentChanged),
          ],
        ),

        const Spacer(),

        // Color Swatch
        ColorSwatchButton(
          color: currentColor,
          onColorChanged: onColorChanged,
          size: 30,
        ),
      ],
    );
  }

  Widget _buildAlignButton(IconData icon, TextAlign alignment, TextAlign current, ValueChanged<TextAlign> onChanged) {
    final isSelected = alignment == current;
    return InkWell(
      onTap: () => onChanged(alignment),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCustomTextCard(BuildContext context, EditorViewModel vm, CanvasTextItem item, int number) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Text #$number',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => vm.removeCustomTextElement(item.id),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                tooltip: 'Delete Text Element',
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildTextField(
            label: 'Content',
            initialText: item.text,
            onChanged: (val) => vm.updateCustomTextElement(item.id, item.copyWith(text: val)),
          ),
          const SizedBox(height: 8),
          _buildFontDropdownRow(
            label: 'Font',
            currentFont: item.font,
            onChanged: (f) => vm.updateCustomTextElement(item.id, item.copyWith(font: f)),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: 'Size',
            valueText: '${item.fontSize.toInt()}px',
            value: item.fontSize,
            min: 14,
            max: 80,
            onChanged: (val) => vm.updateCustomTextElement(item.id, item.copyWith(fontSize: val)),
          ),
          const SizedBox(height: 8),
          _buildWeightAndColorRow(
            currentWeight: item.weight,
            currentColor: item.color,
            currentAlignment: item.alignment,
            onWeightChanged: (w) => vm.updateCustomTextElement(item.id, item.copyWith(weight: w)),
            onColorChanged: (c) => vm.updateCustomTextElement(item.id, item.copyWith(color: c)),
            onAlignmentChanged: (a) => vm.updateCustomTextElement(item.id, item.copyWith(alignment: a)),
          ),
        ],
      ),
    );
  }
}

