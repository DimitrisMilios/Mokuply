import 'package:flutter/painting.dart';
import '../../../core/constants/store_specs.dart';

/// Geometry of the workspace strip: one tab row, then one row of screen
/// cards per visible store.
class WorkspaceLayout {
  WorkspaceLayout._();

  /// All cards share one height, so the shared design renders at the same
  /// scale on both stores; only the card width follows the store.
  static const double previewHeight = 620.0;
  static const double cardGap = 4.0;

  /// Height of the tab pill, and of the gold underline bar that sits below it.
  static const double tabPillHeight = 32.0;
  static const double underlineHeight = 4.0;
  static const double tabsHeight = tabPillHeight + 4 + underlineHeight;
  static const double tabsGap = 10.0;
  static const double rowHeaderHeight = 36.0;
  static const double rowHeaderGap = 8.0;
  static const double rowSpacing = 28.0;
  static const double addButtonWidth = 56.0;
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 160, vertical: 120);

  static double cardWidthFor(TargetPlatformType store) => previewHeight * store.aspectRatio;

  /// Width of one strip slot (card plus the gap shared with its neighbour).
  static double slotWidthFor(TargetPlatformType store) => cardWidthFor(store) + cardGap;

  /// Size of the whole strip (including padding) for [screenCount] screens
  /// in [rows], used to fit the view to the content.
  static Size contentSize({required int screenCount, required List<TargetPlatformType> rows}) {
    double width = 0;
    for (final store in rows) {
      final rowWidth = screenCount * slotWidthFor(store);
      if (rowWidth > width) width = rowWidth;
    }
    width += addButtonWidth + cardGap;
    final double height =
        tabsHeight +
        tabsGap +
        rows.length * (rowHeaderHeight + rowHeaderGap + previewHeight) +
        (rows.length - 1) * rowSpacing;
    return Size(width + contentPadding.horizontal, height + contentPadding.vertical);
  }
}
