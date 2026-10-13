import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../../widgets/shared/ambient_background.dart';
import 'widgets/action_rail.dart';
import 'widgets/canvas_zoom_bar.dart';
import 'widgets/editor_mode_bar.dart';
import 'widgets/editor_navbar.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/multi_canvas_workspace.dart';

/// Full-screen editor: a pan/zoom strip of screens with floating clay
/// panels, keyboard shortcuts and a clean preview mode.
///
/// Shortcuts: arrows nudge the selection (Shift = ×10), Delete removes it,
/// Esc deselects / leaves preview, Ctrl+D duplicates the selection (or the
/// screen), + / − zoom, 0 fits the strip, 1 is 100%.
///
/// Motion (F.5): on start the panels assemble with a 35 ms stagger; Edit ↔
/// Preview flies them off screen in their own directions and springs the
/// canvas to fit. Panels move with `Transform.translate` driven by unbounded
/// controllers, never with `AnimatedPositioned`, and stay outside the
/// `InteractiveViewer` subtree.
class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> with TickerProviderStateMixin {
  static const double _minZoom = 0.15;
  static const double _maxZoom = 4.0;

  // Panel geometry (kept in one place so the flights and the layout agree).
  static const double _navTop = 14.0;
  static const double _edge = 16.0;
  static const double _panelTop = 98.0;
  static const double _bottomBarInset = 20.0;
  static const double _modeBarLeft = 108.0;
  static const double _modeBarRight = 200.0;

  /// How far the mode bar shifts right when the side panels leave, so it sits
  /// in the centre of the whole viewport instead of the free region.
  static const double _modeBarPreviewShift = (_modeBarRight - _modeBarLeft) / 2;

  late final TransformationController _transformationController;
  final FocusNode _shortcutsFocus = FocusNode(debugLabel: 'editor-shortcuts');
  bool _previewing = false;
  Size _viewport = Size.zero;
  bool _didInitialFit = false;
  bool _didAssemble = false;

  late final _PanelFlight _navbar;
  late final _PanelFlight _rail;
  late final _PanelFlight _inspector;
  late final _PanelFlight _modeBar;
  late final _PanelFlight _zoomBar;
  late final AnimationController _modeShift; // 0 = edit position, 1 = preview position

  late final AnimationController _fitAnim;
  Matrix4? _fitFrom;
  Matrix4? _fitTo;
  Matrix4? _lastFitValue;

  ClayMotion _motion = const ClayMotion(enabled: true);

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);

    _navbar = _PanelFlight(vsync: this, direction: const Offset(0, -1));
    _rail = _PanelFlight(vsync: this, direction: const Offset(-1, 0));
    _inspector = _PanelFlight(vsync: this, direction: const Offset(1, 0));
    _modeBar = _PanelFlight(vsync: this, direction: const Offset(0, 1));
    _zoomBar = _PanelFlight(vsync: this, direction: const Offset(0, 1));
    _modeShift = AnimationController.unbounded(vsync: this, value: 0);

    _fitAnim = AnimationController.unbounded(vsync: this, value: 0);
    _fitAnim.addListener(_onFitTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = ClayMotion.of(context);
    if (!_didAssemble) {
      _didAssemble = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _assemble();
      });
    }
  }

  @override
  void dispose() {
    _fitAnim.removeListener(_onFitTick);
    _fitAnim.dispose();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _shortcutsFocus.dispose();
    for (final f in [_navbar, _rail, _inspector, _modeBar, _zoomBar]) {
      f.dispose();
    }
    _modeShift.dispose();
    super.dispose();
  }

  // --- Panel flights ---

  double get _navbarTravel => _navTop + AppDimensions.navbarHeight + 60;
  double get _railTravel => _edge + AppDimensions.railWidth + 60;
  double get _inspectorTravel => _edge + AppDimensions.sidebarWidth + 80;
  double get _zoomBarTravel => _bottomBarInset + 56 + 60;

  /// App start: panels assemble one after another.
  void _assemble() {
    final m = _motion;
    final step = m.stagger;
    _navbar.fly(show: true, travel: 16, fade: true, motion: m, delay: step * 0);
    _rail.fly(show: true, travel: _railTravel, fade: true, motion: m, delay: step * 1);
    _inspector.fly(show: true, travel: _inspectorTravel, fade: true, motion: m, delay: step * 2);
    _modeBar.fly(show: true, travel: 24, fade: true, motion: m, delay: step * 3);
    _zoomBar.fly(show: true, travel: 24, fade: true, motion: m, delay: step * 4);
  }

  /// Edit → Preview: rail left, inspector right, navbar up, zoom bar down.
  /// Preview → Edit brings them back in reverse order.
  void _flyPanels({required bool previewing}) {
    final m = _motion;
    final step = m.stagger;
    final show = !previewing;
    final order = previewing ? [_rail, _inspector, _navbar, _zoomBar] : [_zoomBar, _navbar, _inspector, _rail];
    final travel = {
      _rail: _railTravel,
      _inspector: _inspectorTravel,
      _navbar: _navbarTravel,
      _zoomBar: _zoomBarTravel,
    };
    for (var i = 0; i < order.length; i++) {
      final panel = order[i];
      panel.fly(show: show, travel: travel[panel]!, fade: false, motion: m, delay: step * i);
    }
    _modeShift.springTo(previewing ? 1 : 0, spring: m.gentle);
  }

  // --- Zoom helpers ---

  double get _zoom => _transformationController.value.getMaxScaleOnAxis();

  /// Region of the viewport not covered by floating panels.
  Rect _visibleRegion() {
    if (_previewing) {
      return Rect.fromLTRB(24, 24, _viewport.width - 24, _viewport.height - 80);
    }
    final double right = _viewport.width - (_edge + AppDimensions.sidebarWidth + _edge);
    return Rect.fromLTRB(
      _edge + AppDimensions.railWidth + 24,
      _panelTop + 8,
      math.max(right, 400),
      _viewport.height - 86,
    );
  }

  Matrix4 _fitMatrix() {
    final vm = context.read<EditorViewModel>();
    final total = MultiCanvasWorkspace.contentSize(vm);
    const pad = MultiCanvasWorkspace.contentPadding;
    final inner = Size(total.width - pad.horizontal, total.height - pad.vertical);
    final region = _visibleRegion();

    final double scale = math.min(region.width / inner.width, region.height / inner.height).clamp(_minZoom, _maxZoom);
    final innerCenter = Offset(pad.left + inner.width / 2, pad.top + inner.height / 2);
    final tx = region.center.dx - scale * innerCenter.dx;
    final ty = region.center.dy - scale * innerCenter.dy;
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  /// Fits the strip into the visible region. Animated with the gentle spring
  /// unless [animate] is false (the very first fit, before anything is shown).
  void _fitToContent({bool animate = true}) {
    if (_viewport.isEmpty) return;
    final target = _fitMatrix();
    if (!animate) {
      _fitAnim.stop();
      _transformationController.value = target;
      return;
    }
    _fitFrom = _transformationController.value.clone();
    _fitTo = target;
    _fitAnim.value = 0;
    _fitAnim.springTo(1, spring: _motion.gentle, velocity: 0).then((_) {
      if (!mounted || _fitTo != target) return;
      // Land exactly on the target; the spring stops within its tolerance.
      _lastFitValue = target;
      _transformationController.value = target;
      _fitFrom = null;
      _fitTo = null;
    });
  }

  void _onFitTick() {
    final from = _fitFrom;
    final to = _fitTo;
    if (from == null || to == null) return;
    final m = _lerpTransform(from, to, _fitAnim.value);
    _lastFitValue = m;
    _transformationController.value = m;
  }

  /// A pan or zoom from anywhere else interrupts the fit animation.
  void _onTransformChanged() {
    if (!_fitAnim.isAnimating) return;
    final last = _lastFitValue;
    if (last != null && _transformationController.value != last) {
      _fitAnim.stop();
      _fitFrom = null;
      _fitTo = null;
    }
  }

  /// The strip matrix is translation × uniform scale, so lerping the two
  /// parts directly is exact and cheaper than a full decomposition.
  static Matrix4 _lerpTransform(Matrix4 a, Matrix4 b, double t) {
    final sa = a.getMaxScaleOnAxis();
    final sb = b.getMaxScaleOnAxis();
    final ta = a.getTranslation();
    final tb = b.getTranslation();
    final s = ui.lerpDouble(sa, sb, t)!;
    final tx = ui.lerpDouble(ta.x, tb.x, t)!;
    final ty = ui.lerpDouble(ta.y, tb.y, t)!;
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, s, 1);
  }

  /// Zooms by [factor] about the centre of the visible region.
  void _zoomBy(double factor) {
    final current = _zoom;
    final target = (current * factor).clamp(_minZoom, _maxZoom);
    final ratio = target / current;
    if ((ratio - 1).abs() < 1e-6) return;
    final focal = _visibleRegion().center;
    final m = _transformationController.value.clone();
    // Keep the focal point fixed: translate to focal, scale, translate back.
    final before = Matrix4.identity()..translateByDouble(focal.dx, focal.dy, 0, 1);
    final scale = Matrix4.identity()..scaleByDouble(ratio, ratio, ratio, 1);
    final after = Matrix4.identity()..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    _transformationController.value = before * scale * after * m;
  }

  void _zoomTo(double target) => _zoomBy(target / _zoom);

  // --- Preview mode ---

  void _setPreviewing(bool value) {
    if (_previewing == value) return;
    setState(() => _previewing = value);
    _flyPanels(previewing: value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitToContent();
    });
  }

  // --- Keyboard ---

  bool _typingInTextField() {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null || focused == _shortcutsFocus) return false;
    final ctx = focused.context;
    return ctx != null && ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final vm = context.read<EditorViewModel>();
    final bool typing = _typingInTextField();
    final bool shift = HardwareKeyboard.instance.isShiftPressed;
    final bool ctrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (key == LogicalKeyboardKey.escape) {
      if (_previewing) {
        _setPreviewing(false);
      } else if (typing) {
        _shortcutsFocus.requestFocus();
      } else {
        vm.selectElement(null);
      }
      return KeyEventResult.handled;
    }
    if (typing || _previewing) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
      vm.removeSelectedElement();
      return KeyEventResult.handled;
    }
    final double step = shift ? 10 : 1;
    if (key == LogicalKeyboardKey.arrowLeft) {
      vm.nudgeSelected(-step, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      vm.nudgeSelected(step, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      vm.nudgeSelected(0, -step);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      vm.nudgeSelected(0, step);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyD) {
      final id = vm.selectedElementId;
      if (id != null && (id.startsWith('dev_') || id.startsWith('img_') || id.startsWith('txt_'))) {
        vm.duplicateElement(id);
      } else {
        vm.duplicateScreenshot(vm.selectedIndex);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      _zoomBy(1.2);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      _zoomBy(1 / 1.2);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _fitToContent();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _zoomTo(1.0);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: Focus(
        focusNode: _shortcutsFocus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: AmbientBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              if (size != _viewport) {
                _viewport = size;
                if (!_didInitialFit && !size.isEmpty) {
                  _didInitialFit = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fitToContent(animate: false);
                  });
                }
              }

              return Stack(
                children: [
                  // Layer 0: the strip of screens (pan & zoom)
                  Positioned.fill(
                    child: Listener(
                      // Clicking the canvas returns keyboard focus to the editor
                      // so shortcuts work right after typing in the inspector.
                      onPointerDown: (_) => _shortcutsFocus.requestFocus(),
                      child: MultiCanvasWorkspace(
                        transformationController: _transformationController,
                        previewing: _previewing,
                      ),
                    ),
                  ),

                  // Layer 1: top navigation
                  Positioned(
                    top: _navTop,
                    left: _edge,
                    right: _edge,
                    child: _FlyingPanel(flight: _navbar, child: const EditorNavbar()),
                  ),

                  // Layer 2: left action rail
                  Positioned(
                    top: _panelTop,
                    bottom: _edge,
                    left: _edge,
                    child: _FlyingPanel(flight: _rail, child: const ActionRail()),
                  ),

                  // Layer 3: right inspector (layers + properties)
                  Positioned(
                    top: _panelTop,
                    bottom: 86,
                    right: _edge,
                    child: _FlyingPanel(flight: _inspector, child: const InspectorPanel()),
                  ),

                  // Layer 4: bottom-centre mode switch. Laid out in the edit
                  // position; a spring shifts it to the viewport centre in
                  // preview so the stack never re-lays out.
                  Positioned(
                    bottom: _bottomBarInset,
                    left: _modeBarLeft,
                    right: _modeBarRight,
                    child: AnimatedBuilder(
                      animation: _modeShift,
                      child: Center(
                        child: _FlyingPanel(
                          flight: _modeBar,
                          child: EditorModeBar(previewing: _previewing, onChanged: _setPreviewing),
                        ),
                      ),
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_modeBarPreviewShift * _modeShift.value, 0),
                        child: child,
                      ),
                    ),
                  ),

                  // Layer 5: bottom-right zoom
                  Positioned(
                    bottom: _bottomBarInset,
                    right: _bottomBarInset,
                    child: _FlyingPanel(
                      flight: _zoomBar,
                      child: CanvasZoomBar(
                        transformationController: _transformationController,
                        onZoomIn: () => _zoomBy(1.2),
                        onZoomOut: () => _zoomBy(1 / 1.2),
                        onFit: _fitToContent,
                        onActualSize: () => _zoomTo(1.0),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One floating panel's entrance / exit state: a spring from 0 (hidden, off
/// along [direction] by [travel]) to 1 (in place), plus a skew along the
/// travel axis that follows the velocity and settles with a bounce.
class _PanelFlight {
  final AnimationController progress;
  final AnimationController skew;

  /// Unit vector pointing to where the panel hides.
  final Offset direction;

  double travel = 0;
  bool fade = true;
  bool _skewEnabled = false;
  int _generation = 0;
  bool _disposed = false;

  _PanelFlight({required TickerProvider vsync, required this.direction})
      : progress = AnimationController.unbounded(vsync: vsync, value: 0),
        skew = AnimationController.unbounded(vsync: vsync, value: 0) {
    progress.addListener(_trackVelocity);
  }

  bool get horizontal => direction.dx != 0;

  void _trackVelocity() {
    if (!_skewEnabled || !progress.isAnimating) return;
    // Position along the axis = -dir * travel * (1 - value), so the velocity
    // in px/s is -dir * travel * progress.velocity. Halved so a panel-sized
    // surface leans without hitting the 10° clamp on every flight.
    final axis = horizontal ? direction.dx : direction.dy;
    final v = -axis * travel * progress.velocity;
    skew.value = skewForVelocity(v * 0.5);
  }

  void fly({
    required bool show,
    required double travel,
    required bool fade,
    required ClayMotion motion,
    Duration delay = Duration.zero,
  }) {
    final gen = ++_generation;
    void start() {
      if (_disposed || gen != _generation) return;
      this.travel = travel;
      this.fade = fade;
      _skewEnabled = motion.skew;
      final target = show ? 1.0 : 0.0;
      progress.springTo(target, spring: motion.gentle).then((_) {
        if (_disposed || gen != _generation) return;
        progress.value = target;
        if (_skewEnabled) skew.springTo(0, spring: motion.bouncy);
      });
    }

    if (delay == Duration.zero) {
      start();
    } else {
      Future<void>.delayed(delay, start);
    }
  }

  void dispose() {
    _disposed = true;
    progress.removeListener(_trackVelocity);
    progress.dispose();
    skew.dispose();
  }
}

/// Paints a panel at its flight offset. Fully hidden panels are taken
/// offstage with their tickers stopped (F.6) but keep their state, so the
/// inspector remembers its collapse and scroll position across preview.
class _FlyingPanel extends StatelessWidget {
  final _PanelFlight flight;
  final Widget child;

  const _FlyingPanel({required this.flight, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([flight.progress, flight.skew]),
      child: child,
      builder: (context, child) {
        final t = flight.progress.value;
        final hidden = !flight.progress.isAnimating && t < 0.01;
        if (hidden) {
          return Offstage(offstage: true, child: TickerMode(enabled: false, child: child!));
        }

        final remaining = 1 - t;
        final offset = Offset(flight.direction.dx * flight.travel * remaining, flight.direction.dy * flight.travel * remaining);

        Widget w = child!;
        final k = flight.skew.value;
        if (k.abs() > 0.0005) {
          final m = Matrix4.identity();
          if (flight.horizontal) {
            m.setEntry(0, 1, k);
          } else {
            m.setEntry(1, 0, k);
          }
          w = Transform(transform: m, alignment: Alignment.center, child: w);
        }
        if (offset != Offset.zero) {
          w = Transform.translate(offset: offset, child: w);
        }
        if (flight.fade && t < 1) {
          w = Opacity(opacity: t.clamp(0.0, 1.0), child: w);
        }
        return IgnorePointer(ignoring: t < 0.6, child: w);
      },
    );
  }
}
