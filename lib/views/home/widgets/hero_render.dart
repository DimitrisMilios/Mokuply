import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/clay/clay.dart';

/// The Blender hero render (`assets/clay/hero_phone_stack.webp`, 720×560 at
/// 2x), scaled down with the available width.
///
/// Motion: a slow 4 s float of 6 px plus a 1.5° rotate. It plays twice on
/// arrival and then rests, and plays again while the pointer is over the
/// render (which also tilts it up to 4° toward the pointer). A click gives a
/// jelly squash. All of it is off with reduced motion.
///
/// The float never loops on its own: an endless animation makes the browser
/// redraw the whole page every frame for as long as the page is open.
class HeroRender extends StatefulWidget {
  const HeroRender({super.key});

  static const String assetPath = 'assets/clay/hero_phone_stack.webp';
  static const double renderWidth = 720;
  static const double renderHeight = 560;

  @override
  State<HeroRender> createState() => _HeroRenderState();
}

class _HeroRenderState extends State<HeroRender> with TickerProviderStateMixin {
  static const double _floatPx = 6;
  static const double _floatRad = 1.5 * math.pi / 180;
  static const double _tiltRad = 4 * math.pi / 180;
  static const int _arrivalCycles = 2;

  /// A loop, not a control, so a linear repeat with a sine is fine here.
  /// Values 0 and 1 are the same pose, so it can stop at either.
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  late final AnimationController _tiltX = AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _tiltY = AnimationController.unbounded(vsync: this, value: 0);
  final JellyController _jelly = JellyController();
  bool _motionEnabled = true;
  bool _arrived = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionEnabled = ClayMotion.of(context).enabled;
    if (!_motionEnabled) {
      _float
        ..stop()
        ..value = 0;
      _tiltX.value = 0;
      _tiltY.value = 0;
    } else if (!_arrived) {
      _arrived = true;
      _float.repeat(count: _arrivalCycles);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _tiltX.dispose();
    _tiltY.dispose();
    super.dispose();
  }

  void _onEnter() {
    if (_motionEnabled && !_float.isAnimating) _float.repeat();
  }

  void _onHover(PointerEvent event, Size size) {
    if (!_motionEnabled || size.isEmpty) return;
    final nx = ((event.localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny = ((event.localPosition.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
    final spring = ClayMotion.of(context).gentle;
    // Tilt toward the pointer: pointer right → rotate about Y so the right
    // edge dips; pointer down → rotate about X so the bottom edge dips.
    _tiltY.springTo(nx * _tiltRad, spring: spring);
    _tiltX.springTo(-ny * _tiltRad, spring: spring);
  }

  void _onExit() {
    final spring = ClayMotion.of(context).gentle;
    _tiltX.springTo(0, spring: spring);
    _tiltY.springTo(0, spring: spring);
    // Finish the current float cycle, then rest.
    if (_float.isAnimating) {
      _float.animateTo(1.0).whenComplete(() {
        if (mounted && !_float.isAnimating) _float.value = 0;
      });
    }
  }

  Matrix4 _transform() {
    final phase = _float.value * 2 * math.pi;
    final dy = _motionEnabled ? _floatPx * math.sin(phase) : 0.0;
    final rz = _motionEnabled ? _floatRad * math.sin(phase + math.pi / 3) : 0.0;
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..translateByDouble(0.0, dy, 0.0, 1.0)
      ..rotateX(_tiltX.value)
      ..rotateY(_tiltY.value)
      ..rotateZ(rz);
  }

  @override
  Widget build(BuildContext context) {
    final int decodeWidth = (HeroRender.renderWidth * MediaQuery.devicePixelRatioOf(context)).round();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: HeroRender.renderWidth),
      child: AspectRatio(
        aspectRatio: HeroRender.renderWidth / HeroRender.renderHeight,
        child: LayoutBuilder(
          builder: (context, constraints) => MouseRegion(
            onEnter: (_) => _onEnter(),
            onHover: (e) => _onHover(e, constraints.biggest),
            onExit: (_) => _onExit(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _jelly.tap(squash: 0.06),
              child: AnimatedBuilder(
                animation: Listenable.merge([_float, _tiltX, _tiltY]),
                builder: (context, child) =>
                    Transform(transform: _transform(), alignment: Alignment.center, child: child),
                child: JellyTransform(
                  controller: _jelly,
                  child: RepaintBoundary(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        HeroRender.assetPath,
                        width: HeroRender.renderWidth,
                        height: HeroRender.renderHeight,
                        // The file is 2x; decode only what the screen can show.
                        cacheWidth: math.min(decodeWidth, HeroRender.renderWidth.toInt() * 2),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        semanticLabel: 'A stack of phones showing store screenshots',
                        errorBuilder: (_, _, _) => const _HeroRenderPlaceholder(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown if the render cannot load: a clay panel of the same aspect.
class _HeroRenderPlaceholder extends StatelessWidget {
  const _HeroRenderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ClayPanel(
      width: HeroRender.renderWidth,
      height: HeroRender.renderHeight,
      radius: AppDimensions.radiusClayXl,
      alignment: Alignment.center,
      child: Text(
        'hero render',
        style: TextStyle(color: AppColors.textMuted, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      ),
    );
  }
}
