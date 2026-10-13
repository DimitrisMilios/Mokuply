import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/motion/clay_motion.dart';
import '../../viewmodels/editor/editor_viewmodel.dart';
import '../../widgets/shared/ambient_background.dart';
import 'shell/canvas_viewport_controller.dart';
import 'shell/editor_chrome_motion.dart';
import 'shell/editor_shell_layout.dart';
import 'shell/editor_shortcuts.dart';
import 'shell/panel_flight.dart';
import 'widgets/action_rail.dart';
import 'widgets/canvas_zoom_bar.dart';
import 'widgets/editor_mode_bar.dart';
import 'widgets/editor_navbar.dart';
import 'inspector/inspector_panel.dart';
import 'workspace/multi_canvas_workspace.dart';
import 'workspace/workspace_layout.dart';

/// Full-screen editor: a pan/zoom strip of screens under floating clay
/// panels, keyboard shortcuts (see [handleEditorKey]) and a clean preview
/// mode. Layout only; zoom, shortcuts and panel motion live in `shell/`.
class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> with TickerProviderStateMixin {
  late final CanvasViewportController _viewport = CanvasViewportController(vsync: this);
  late final EditorChromeMotion _chrome = EditorChromeMotion(vsync: this);
  final FocusNode _shortcutsFocus = FocusNode(debugLabel: 'editor-shortcuts');

  bool _previewing = false;
  Size _viewportSize = Size.zero;
  bool _didInitialFit = false;
  bool _didAssemble = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didAssemble) return;
    _didAssemble = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chrome.assemble(ClayMotion.of(context));
    });
  }

  @override
  void dispose() {
    _viewport.dispose();
    _chrome.dispose();
    _shortcutsFocus.dispose();
    super.dispose();
  }

  // --- Zoom ---

  Rect get _visibleRegion => EditorShellLayout.visibleRegion(_viewportSize, previewing: _previewing);

  /// Fits the whole strip into the visible region (springs unless [animate] is false).
  void _fit({bool animate = true}) {
    if (_viewportSize.isEmpty) return;
    final vm = context.read<EditorViewModel>();
    final content = WorkspaceLayout.contentSize(screenCount: vm.screenshotsCount, rows: vm.visibleStores);
    _viewport.fit(content, _visibleRegion, motion: animate ? ClayMotion.of(context) : null);
  }

  void _zoomBy(double factor) => _viewport.zoomBy(factor, _visibleRegion.center);
  void _actualSize() => _viewport.zoomTo(1.0, _visibleRegion.center);

  void _onViewportSize(Size size) {
    if (size == _viewportSize) return;
    _viewportSize = size;
    if (_didInitialFit || size.isEmpty) return;
    _didInitialFit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fit(animate: false);
    });
  }

  // --- Preview mode ---

  void _setPreviewing(bool value) {
    if (_previewing == value) return;
    setState(() => _previewing = value);
    _chrome.flyPanels(previewing: value, motion: ClayMotion.of(context));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fit();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    return handleEditorKey(
      event,
      vm: context.read<EditorViewModel>(),
      previewing: _previewing,
      typing: isTypingInTextField(_shortcutsFocus),
      actions: EditorShortcutActions(
        exitPreview: () => _setPreviewing(false),
        releaseTextFocus: _shortcutsFocus.requestFocus,
        zoomIn: () => _zoomBy(1.2),
        zoomOut: () => _zoomBy(1 / 1.2),
        fit: _fit,
        actualSize: _actualSize,
      ),
    );
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
              _onViewportSize(constraints.biggest);
              return Stack(children: [_workspace(), ..._panels()]);
            },
          ),
        ),
      ),
    );
  }

  /// Layer 0: the strip of screens (pan & zoom).
  Widget _workspace() {
    return Positioned.fill(
      child: Listener(
        // Clicking the canvas returns keyboard focus to the editor so
        // shortcuts work right after typing in the inspector.
        onPointerDown: (_) => _shortcutsFocus.requestFocus(),
        child: MultiCanvasWorkspace(transformationController: _viewport.transformation, previewing: _previewing),
      ),
    );
  }

  /// Layers 1–5: the floating panels.
  List<Widget> _panels() {
    const l = EditorShellLayout.edge;
    return [
      Positioned(
        top: EditorShellLayout.navTop,
        left: l,
        right: l,
        child: FlyingPanel(flight: _chrome.navbar, child: const EditorNavbar()),
      ),
      Positioned(
        top: EditorShellLayout.panelTop,
        bottom: l,
        left: l,
        child: FlyingPanel(flight: _chrome.rail, child: const ActionRail()),
      ),
      Positioned(
        top: EditorShellLayout.panelTop,
        bottom: EditorShellLayout.inspectorBottom,
        right: l,
        child: FlyingPanel(flight: _chrome.inspector, child: const InspectorPanel()),
      ),
      // Laid out in the edit position; a spring shifts it to the viewport
      // centre in preview so the stack never re-lays out.
      Positioned(
        bottom: EditorShellLayout.bottomBarInset,
        left: EditorShellLayout.modeBarLeft,
        right: EditorShellLayout.modeBarRight,
        child: AnimatedBuilder(
          animation: _chrome.modeShift,
          child: Center(
            child: FlyingPanel(
              flight: _chrome.modeBar,
              child: EditorModeBar(previewing: _previewing, onChanged: _setPreviewing),
            ),
          ),
          builder: (context, child) => Transform.translate(
            offset: Offset(EditorShellLayout.modeBarPreviewShift * _chrome.modeShift.value, 0),
            child: child,
          ),
        ),
      ),
      Positioned(
        bottom: EditorShellLayout.bottomBarInset,
        right: EditorShellLayout.bottomBarInset,
        child: FlyingPanel(
          flight: _chrome.zoomBar,
          child: CanvasZoomBar(
            transformationController: _viewport.transformation,
            onZoomIn: () => _zoomBy(1.2),
            onZoomOut: () => _zoomBy(1 / 1.2),
            onFit: _fit,
            onActualSize: _actualSize,
          ),
        ),
      ),
    ];
  }
}
