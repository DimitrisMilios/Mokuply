import 'dart:math' as math;
import 'dart:ui';

import '../constants/store_specs.dart';

/// Maps the shared [DesignSpace] onto a concrete canvas (a preview card or an
/// export target of any size).
///
/// The design is fit inside the canvas with a single uniform [scale] and
/// centred, so every element keeps the same relative position and size on
/// every store. The background always fills the whole canvas; only the design
/// content is scaled.
class CanvasGeometry {
  final Size canvasSize;

  /// Design pixels → canvas pixels.
  final double scale;

  CanvasGeometry(this.canvasSize)
      : scale = math.min(
          canvasSize.width / DesignSpace.width,
          canvasSize.height / DesignSpace.height,
        );

  Offset get canvasCenter => Offset(canvasSize.width / 2, canvasSize.height / 2);

  /// Size of the scaled design area inside the canvas.
  Size get designAreaSize => Size(DesignSpace.width * scale, DesignSpace.height * scale);

  /// Multiplier applied to model font sizes so text renders 1:1 on the Apple export.
  double get textScale => scale * DesignSpace.textScale;

  /// Widest a headline may be before it wraps, in canvas pixels.
  double get maxTextWidth => DesignSpace.width * DesignSpace.maxTextWidthFraction * scale;

  /// Canvas Y of a point that sits at [fraction] of the design height.
  double anchorY(double fraction) => canvasCenter.dy + (fraction - 0.5) * DesignSpace.height * scale;

  /// Canvas centre of an element anchored at [anchorFraction] of the design
  /// height and displaced by stored offset units ([offsetX], [offsetY]).
  Offset elementCenter({
    required double anchorFraction,
    required double offsetX,
    required double offsetY,
  }) {
    return Offset(
      canvasCenter.dx + offsetX * DesignSpace.offsetUnitX * scale,
      anchorY(anchorFraction) + offsetY * DesignSpace.offsetUnitY * scale,
    );
  }

  /// Converts a pointer drag delta in canvas pixels into stored offset units.
  Offset deltaToOffsetUnits(Offset canvasDelta) {
    return Offset(
      canvasDelta.dx / (DesignSpace.offsetUnitX * scale),
      canvasDelta.dy / (DesignSpace.offsetUnitY * scale),
    );
  }
}
