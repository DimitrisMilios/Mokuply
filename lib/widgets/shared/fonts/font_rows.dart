import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../clay/clay.dart';
import 'lazy_font_preview.dart';

/// "Recently used" / "Popular" / "All fonts" label inside the list.
class FontSectionHeader extends StatelessWidget {
  final String label;
  const FontSectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: ClayLabel(label, padding: const EdgeInsets.only(left: 8, bottom: 8)),
    );
  }
}

/// One family: its name and a lazily loaded preview line.
class FontRow extends StatelessWidget {
  final String family;
  final bool selected;
  final VoidCallback onTap;

  const FontRow({super.key, required this.family, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClayTile(
        selected: selected,
        onTap: onTap,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        radius: AppDimensions.radiusClaySm,
        // Script and display fonts can have tall line boxes; clip instead of overflowing.
        child: ClipRect(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                family,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.primaryDeep : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              LazyFontPreview(
                family: family,
                text: 'The quick brown fox jumps',
                fontSize: 17,
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
