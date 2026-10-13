import 'dart:math' as math;
import 'dart:ui';

import '../../../core/constants/app_dimensions.dart';

/// Where the floating editor panels sit, kept in one place so the panel
/// flights, the layout and the "fit" region agree.
class EditorShellLayout {
  EditorShellLayout._();

  static const double navTop = 14.0;
  static const double edge = 16.0;
  static const double panelTop = 98.0;
  static const double inspectorBottom = 86.0;
  static const double bottomBarInset = 20.0;
  static const double modeBarLeft = 108.0;
  static const double modeBarRight = 200.0;

  /// How far the mode bar shifts right when the side panels leave, so it
  /// sits in the centre of the whole viewport instead of the free region.
  static const double modeBarPreviewShift = (modeBarRight - modeBarLeft) / 2;

  /// Region of a [viewport] not covered by floating panels.
  static Rect visibleRegion(Size viewport, {required bool previewing}) {
    if (previewing) {
      return Rect.fromLTRB(24, 24, viewport.width - 24, viewport.height - 80);
    }
    final double right = viewport.width - (edge + AppDimensions.sidebarWidth + edge);
    return Rect.fromLTRB(
      edge + AppDimensions.railWidth + 24,
      panelTop + 8,
      math.max(right, 400),
      viewport.height - inspectorBottom,
    );
  }
}
