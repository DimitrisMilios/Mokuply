import '../../core/constants/store_specs.dart';
import '../../core/layout/layout_anchors.dart';

/// Headline placement from measured edges. Text is positioned by its
/// centre, so these turn a left edge and a top edge (design pixels) into the
/// stored offsets. [widestLine] is the measured width of the longest line.
class LeftHeadline {
  LeftHeadline._();

  /// Line height used by the canvas text renderer.
  static const double lineHeight = 1.15;

  static double offsetX({required double left, required double widestLine}) =>
      (left + widestLine / 2 - DesignSpace.width / 2) / DesignSpace.offsetUnitX;

  /// [anchor] is the layout anchor (fraction of the design height) the text
  /// is stored against; it defaults to the headline anchor.
  static double offsetY({required double top, required String text, required double fontSize, double? anchor}) {
    final lines = '\n'.allMatches(text).length + 1;
    final centre = top + lines * fontSize * lineHeight / 2;
    final anchorY = (anchor ?? LayoutAnchors.forMode(LayoutMode.titleTopDeviceBottom).title) * DesignSpace.height;
    return (centre - anchorY) / DesignSpace.offsetUnitY;
  }
}
