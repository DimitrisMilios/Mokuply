import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/store_specs.dart';
import 'glass_container.dart';

/// Shows the current font rendered in itself and opens a searchable picker
/// over the whole free Google Fonts catalogue.
class FontPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const FontPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Font',
  });

  static TextStyle styleFor(String family, {double fontSize = 14, FontWeight weight = FontWeight.w600, Color? color}) {
    try {
      return GoogleFonts.getFont(family, fontSize: fontSize, fontWeight: weight, color: color);
    } catch (_) {
      return TextStyle(fontFamily: family, fontSize: fontSize, fontWeight: weight, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await FontPickerDialog.show(context, current: value);
              if (picked != null && picked != value) onChanged(picked);
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styleFor(value, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Searchable list of every Google Fonts family, each row rendered in its own font.
class FontPickerDialog extends StatefulWidget {
  final String current;

  const FontPickerDialog({super.key, required this.current});

  static Future<String?> show(BuildContext context, {required String current}) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => FontPickerDialog(current: current),
    );
  }

  /// All family names in the catalogue, sorted once.
  static final List<String> allFamilies = GoogleFonts.asMap().keys.toList()..sort();

  @override
  State<FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends State<FontPickerDialog> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      // Popular picks first, then the rest of the catalogue.
      final popular = StoreSpecs.popularFonts.where(FontPickerDialog.allFamilies.contains).toList();
      final rest = FontPickerDialog.allFamilies.where((f) => !popular.contains(f));
      return [...popular, ...rest];
    }
    return FontPickerDialog.allFamilies.where((f) => f.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GlassContainer(
        width: 460,
        opacity: 0.96,
        blurX: 20,
        blurY: 20,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.font_download_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Google Fonts (${FontPickerDialog.allFamilies.length})',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _search,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search fonts, e.g. "Inter", "Serif", "Mono"',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: results.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No fonts match that search.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemExtent: 56,
                        itemBuilder: (context, index) {
                          final family = results[index];
                          final selected = family == widget.current;
                          return _FontRow(
                            family: family,
                            selected: selected,
                            onTap: () => Navigator.of(context).pop(family),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontRow extends StatelessWidget {
  final String family;
  final bool selected;
  final VoidCallback onTap;

  const _FontRow({required this.family, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: selected ? AppColors.primary : AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'The quick brown fox jumps',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FontPickerField.styleFor(family, fontSize: 17, weight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
