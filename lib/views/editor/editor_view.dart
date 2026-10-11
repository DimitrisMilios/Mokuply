import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../../widgets/shared/ambient_background.dart';
import 'widgets/action_rail.dart';
import 'widgets/canvas_zoom_bar.dart';
import 'widgets/editor_mode_bar.dart';
import 'widgets/editor_navbar.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/multi_canvas_workspace.dart';

/// Full-screen editor: a pan/zoom strip of screens with floating glass
/// panels, keyboard shortcuts and a clean preview mode.
///
/// Shortcuts: arrows nudge the selection (Shift = ×10), Delete removes it,
/// Esc deselects / leaves preview, Ctrl+D duplicates the selection (or the
/// screen), + / − zoom, 0 fits the strip, 1 is 100%.
class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  static const double _minZoom = 0.15;
  static const double _maxZoom = 4.0;

  late final TransformationController _transformationController;
  final FocusNode _shortcutsFocus = FocusNode(debugLabel: 'editor-shortcuts');
  bool _previewing = false;
  Size _viewport = Size.zero;
  bool _didInitialFit = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _shortcutsFocus.dispose();
    super.dispose();
  }

  // --- Zoom helpers ---

  double get _zoom => _transformationController.value.getMaxScaleOnAxis();

  /// Region of the viewport not covered by floating panels.
  Rect _visibleRegion() {
    if (_previewing) {
      return Rect.fromLTRB(24, 24, _viewport.width - 24, _viewport.height - 80);
    }
    final double right = _viewport.width - (16 + AppDimensions.sidebarWidth + 16);
    return Rect.fromLTRB(16 + ActionRail.width + 24, 98 + 8, math.max(right, 400), _viewport.height - 86);
  }

  void _fitToContent() {
    if (_viewport.isEmpty) return;
    final vm = context.read<EditorViewModel>();
    final total = MultiCanvasWorkspace.contentSize(vm);
    const pad = MultiCanvasWorkspace.contentPadding;
    final inner = Size(total.width - pad.horizontal, total.height - pad.vertical);
    final region = _visibleRegion();

    final double scale = math.min(region.width / inner.width, region.height / inner.height).clamp(_minZoom, _maxZoom);
    final innerCenter = Offset(pad.left + inner.width / 2, pad.top + inner.height / 2);
    final tx = region.center.dx - scale * innerCenter.dx;
    final ty = region.center.dy - scale * innerCenter.dy;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToContent());
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
      backgroundColor: AppColors.background,
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
                  WidgetsBinding.instance.addPostFrameCallback((_) => _fitToContent());
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
                  if (!_previewing)
                    const Positioned(top: 14, left: 16, right: 16, child: EditorNavbar()),

                  // Layer 2: left action rail
                  if (!_previewing)
                    const Positioned(top: 98, bottom: 16, left: 16, child: ActionRail()),

                  // Layer 3: right inspector (layers + properties)
                  if (!_previewing)
                    const Positioned(top: 98, bottom: 86, right: 16, child: InspectorPanel()),

                  // Layer 4: bottom-centre mode switch
                  Positioned(
                    bottom: 20,
                    left: _previewing ? 20 : 108,
                    right: _previewing ? 20 : 200,
                    child: Center(
                      child: EditorModeBar(previewing: _previewing, onChanged: _setPreviewing),
                    ),
                  ),

                  // Layer 5: bottom-right zoom
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: CanvasZoomBar(
                      transformationController: _transformationController,
                      onZoomIn: () => _zoomBy(1.2),
                      onZoomOut: () => _zoomBy(1 / 1.2),
                      onFit: _fitToContent,
                      onActualSize: () => _zoomTo(1.0),
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
