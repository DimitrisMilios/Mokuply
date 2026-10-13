import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/store_specs.dart';

/// A row of the font picker: a section header or a font family.
class FontEntry {
  final String? header;
  final String? family;

  const FontEntry.header(this.header) : family = null;
  const FontEntry.family(this.family) : header = null;
}

/// The Google Fonts catalogue and the picker's search over it.
class FontCatalog {
  FontCatalog._();

  /// All family names, sorted once.
  static final List<String> all = GoogleFonts.asMap().keys.toList()..sort();

  /// Families picked during this session, most recent first.
  static final List<String> recent = [];

  static void remember(String family) {
    recent
      ..remove(family)
      ..insert(0, family);
    if (recent.length > 8) recent.removeLast();
  }

  /// Rows for [query]: with no query, recent and popular families followed
  /// by everything A–Z; otherwise prefix matches first, then other matches.
  static List<FontEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      final recentShown = recent.where(all.contains).toList();
      final popular = StoreSpecs.popularFonts.where((f) => all.contains(f) && !recentShown.contains(f)).toList();
      final shown = {...recentShown, ...popular};
      return [
        if (recentShown.isNotEmpty) const FontEntry.header('Recently used'),
        for (final f in recentShown) FontEntry.family(f),
        const FontEntry.header('Popular'),
        for (final f in popular) FontEntry.family(f),
        const FontEntry.header('All fonts A–Z'),
        for (final f in all)
          if (!shown.contains(f)) FontEntry.family(f),
      ];
    }
    final starts = <FontEntry>[];
    final contains = <FontEntry>[];
    for (final f in all) {
      final lower = f.toLowerCase();
      if (lower.startsWith(q)) {
        starts.add(FontEntry.family(f));
      } else if (lower.contains(q)) {
        contains.add(FontEntry.family(f));
      }
    }
    return [...starts, ...contains];
  }
}
