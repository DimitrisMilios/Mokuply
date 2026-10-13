import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Flat warm sand page background with an optional faint paper grain.
///
/// The grain tile (`assets/clay/grain_tile.png`) is drawn with
/// `ImageRepeat.repeat` at 2 % opacity. If the asset is missing the
/// background is plain sand, so the widget is safe before the Blender
/// render lands.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  final bool grain;
  final Color color;

  const AmbientBackground({
    super.key,
    required this.child,
    this.grain = true,
    this.color = AppColors.sand,
  });

  static const String grainAsset = 'assets/clay/grain_tile.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: color),
        if (grain)
          Positioned.fill(
            child: IgnorePointer(
              // Image.opacity fades the draw itself; an Opacity widget would
              // composite a full-screen offscreen layer on every frame.
              child: RepaintBoundary(
                child: Image.asset(
                  grainAsset,
                  repeat: ImageRepeat.repeat,
                  opacity: const AlwaysStoppedAnimation(0.02),
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}
