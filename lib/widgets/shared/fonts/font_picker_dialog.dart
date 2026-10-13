import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../clay/clay.dart';
import 'font_catalog.dart';
import 'font_rows.dart';

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

  @override
  State<FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends State<FontPickerDialog> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  late List<FontEntry> _entries = FontCatalog.search('');

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
      _entries = FontCatalog.search(value);
    });
  }

  /// Typing fast should not rebuild (and start font downloads) on every key.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) _setQuery(value);
    });
  }

  void _pick(String family) {
    FontCatalog.remember(family);
    Navigator.of(context).pop(family);
  }

  @override
  Widget build(BuildContext context) {
    final int total = FontCatalog.all.length;
    final int matches = _entries.where((e) => e.family != null).length;
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
              final first = _entries.where((e) => e.family != null).firstOrNull;
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
                      _setQuery('');
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
            child: SizedBox(height: listHeight, child: _list()),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    if (_entries.isEmpty) {
      return const Center(
        child: Text('No fonts match that search.', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.builder(
      itemCount: _entries.length,
      itemExtent: 62,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final family = entry.family;
        if (family == null) return FontSectionHeader(entry.header!);
        return FontRow(
          key: ValueKey(family),
          family: family,
          selected: family == widget.current,
          onTap: () => _pick(family),
        );
      },
    );
  }
}
