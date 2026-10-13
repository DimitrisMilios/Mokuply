import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/store_specs.dart';
import '../clay/clay.dart';

/// Shows the current font and opens a searchable picker over the whole free
/// Google Fonts catalogue.
class FontPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const FontPickerField({super.key, required this.value, required this.onChanged, this.label = 'Font'});

  static TextStyle styleFor(String family, {double fontSize = 14, FontWeight weight = FontWeight.w600, Color? color}) {
    try {
      return GoogleFonts.getFont(family, fontSize: fontSize, fontWeight: weight, color: color);
    } catch (_) {
      return TextStyle(fontFamily: family, fontSize: fontSize, fontWeight: weight, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayDropdown<String>(
      value: value,
      displayText: value,
      label: label,
      // A small sample glyph rendered in the font itself, so the field still
      // previews the choice.
      leading: Text(
        'Aa',
        style: styleFor(value, fontSize: 15, weight: FontWeight.w700, color: AppColors.primary),
      ),
      onOpen: () async {
        final picked = await FontPickerDialog.show(context, current: value);
        if (picked != null && picked != value) onChanged(picked);
      },
    );
  }
}

/// Searchable list of every Google Fonts family.
///
/// Font files are fetched from the network the first time a family is
/// rendered, so the list never renders a preview for a row that is merely
/// scrolled past: a row shows its name in the UI font first and switches to
/// a live preview only after it has stayed on screen for a moment. Only the
/// fonts you actually look at are downloaded.
class FontPickerDialog extends StatefulWidget {
  final String current;

  const FontPickerDialog({super.key, required this.current});

  static Future<String?> show(BuildContext context, {required String current}) {
    return showClayDialog<String>(
      context: context,
      builder: (_) => FontPickerDialog(current: current),
    );
  }

  /// All family names in the catalogue, sorted once.
  static final List<String> allFamilies = GoogleFonts.asMap().keys.toList()..sort();

  /// Families picked during this session, most recent first.
  static final List<String> recentFamilies = [];

  static void _remember(String family) {
    recentFamilies.remove(family);
    recentFamilies.insert(0, family);
    if (recentFamilies.length > 8) recentFamilies.removeLast();
  }

  @override
  State<FontPickerDialog> createState() => _FontPickerDialogState();
}

/// A row of the picker: either a section header or a font family.
class _Entry {
  final String? header;
  final String? family;
  const _Entry.header(this.header) : family = null;
  const _Entry.family(this.family) : header = null;
}

class _FontPickerDialogState extends State<FontPickerDialog> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Typing fast should not rebuild (and start font downloads) on every key.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _query = value);
    });
  }

  List<_Entry> get _entries {
    final q = _query.trim().toLowerCase();
    final all = FontPickerDialog.allFamilies;

    if (q.isEmpty) {
      final recent = FontPickerDialog.recentFamilies.where(all.contains).toList();
      final popular = StoreSpecs.popularFonts.where((f) => all.contains(f) && !recent.contains(f)).toList();
      final shown = {...recent, ...popular};
      return [
        if (recent.isNotEmpty) const _Entry.header('Recently used'),
        for (final f in recent) _Entry.family(f),
        const _Entry.header('Popular'),
        for (final f in popular) _Entry.family(f),
        const _Entry.header('All fonts A–Z'),
        for (final f in all)
          if (!shown.contains(f)) _Entry.family(f),
      ];
    }

    // Prefix matches first, then anything that contains the query.
    final starts = <String>[];
    final contains = <String>[];
    for (final f in all) {
      final lower = f.toLowerCase();
      if (lower.startsWith(q)) {
        starts.add(f);
      } else if (lower.contains(q)) {
        contains.add(f);
      }
    }
    return [for (final f in starts) _Entry.family(f), for (final f in contains) _Entry.family(f)];
  }

  void _pick(String family) {
    FontPickerDialog._remember(family);
    Navigator.of(context).pop(family);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final int matches = entries.where((e) => e.family != null).length;
    final int total = FontPickerDialog.allFamilies.length;
    // The list must stay bounded so only the rows on screen are built; an
    // unbounded (shrink-wrapped) list would mount every row and request
    // every font file.
    final double listHeight = (MediaQuery.sizeOf(context).height * 0.8 - 220).clamp(220.0, 520.0);

    return ClayDialog(
      width: 520,
      title: 'Fonts',
      subtitle: _query.trim().isEmpty ? '$total Google Fonts' : '$matches of $total fonts',
      headerIcon: const Icon(Icons.font_download_rounded, color: AppColors.primary, size: 22),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClayField(
            controller: _search,
            autofocus: true,
            onChanged: _onSearchChanged,
            onSubmitted: (_) {
              final first = entries.where((e) => e.family != null).firstOrNull;
              if (first != null) _pick(first.family!);
            },
            hint: 'Search fonts, e.g. "Inter", "Serif", "Mono"',
            prefix: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
            suffix: _search.text.isEmpty
                ? null
                : ClayIconButton(
                    icon: Icons.clear_rounded,
                    tooltip: 'Clear',
                    size: 32,
                    iconSize: 16,
                    flat: true,
                    onPressed: () {
                      _search.clear();
                      _debounce?.cancel();
                      setState(() => _query = '');
                    },
                  ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Previews load as you scroll, only for the fonts you look at.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 10),
          ClayWell(
            padding: const EdgeInsets.all(6),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: listHeight,
              child: entries.isEmpty
                  ? const Center(
                      child: Text('No fonts match that search.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemExtent: 62,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        if (entry.header != null) return _SectionHeaderRow(entry.header!);
                        final family = entry.family!;
                        return _FontRow(
                          key: ValueKey(family),
                          family: family,
                          selected: family == widget.current,
                          onTap: () => _pick(family),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  final String label;
  const _SectionHeaderRow(this.label);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: ClayLabel(label, padding: const EdgeInsets.only(left: 8, bottom: 8)),
    );
  }
}

class _FontRow extends StatelessWidget {
  final String family;
  final bool selected;
  final VoidCallback onTap;

  const _FontRow({super.key, required this.family, required this.selected, required this.onTap});

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

/// Renders [text] in [family], but only after the widget has been on screen
/// for [delay]. Rows that scroll past quickly are disposed before the timer
/// fires, so their font files are never requested.
class LazyFontPreview extends StatefulWidget {
  final String family;
  final String text;
  final double fontSize;
  final FontWeight weight;
  final Color color;
  final Duration delay;

  const LazyFontPreview({
    super.key,
    required this.family,
    required this.text,
    required this.fontSize,
    required this.weight,
    required this.color,
    this.delay = const Duration(milliseconds: 350),
  });

  /// Families whose preview has already been requested; they render at once.
  static final Set<String> _warm = {};

  @override
  State<LazyFontPreview> createState() => _LazyFontPreviewState();
}

class _LazyFontPreviewState extends State<LazyFontPreview> {
  Timer? _timer;
  late bool _ready = LazyFontPreview._warm.contains(widget.family);

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      _timer = Timer(widget.delay, () {
        if (!mounted) return;
        LazyFontPreview._warm.add(widget.family);
        setState(() => _ready = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = _ready
        ? FontPickerField.styleFor(widget.family, fontSize: widget.fontSize, weight: widget.weight, color: widget.color)
        : TextStyle(fontSize: widget.fontSize, fontWeight: widget.weight, color: widget.color.withValues(alpha: 0.45));
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: style,
      child: Text(widget.text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
