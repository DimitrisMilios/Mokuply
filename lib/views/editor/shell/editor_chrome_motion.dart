import 'package:flutter/widgets.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/clay/clay.dart';
import 'editor_shell_layout.dart';
import 'panel_flight.dart';

/// Choreography of the floating editor panels: on start they assemble with a
/// stagger; Edit ↔ Preview flies them off screen in their own directions.
/// Panels move with transforms driven by unbounded springs, never with
/// `AnimatedPositioned`, so the stack never re-lays out.
class EditorChromeMotion {
  EditorChromeMotion({required TickerProvider vsync})
    : navbar = PanelFlight(vsync: vsync, direction: const Offset(0, -1)),
      rail = PanelFlight(vsync: vsync, direction: const Offset(-1, 0)),
      inspector = PanelFlight(vsync: vsync, direction: const Offset(1, 0)),
      modeBar = PanelFlight(vsync: vsync, direction: const Offset(0, 1)),
      zoomBar = PanelFlight(vsync: vsync, direction: const Offset(0, 1)),
      modeShift = AnimationController.unbounded(vsync: vsync, value: 0);

  final PanelFlight navbar;
  final PanelFlight rail;
  final PanelFlight inspector;
  final PanelFlight modeBar;
  final PanelFlight zoomBar;

  /// 0 = mode bar in its edit position, 1 = centred for preview.
  final AnimationController modeShift;

  static const double _navbarTravel = EditorShellLayout.navTop + AppDimensions.navbarHeight + 60;
  static const double _railTravel = EditorShellLayout.edge + AppDimensions.railWidth + 60;
  static const double _inspectorTravel = EditorShellLayout.edge + AppDimensions.sidebarWidth + 80;
  static const double _zoomBarTravel = EditorShellLayout.bottomBarInset + 56 + 60;

  /// App start: panels assemble one after another.
  void assemble(ClayMotion m) {
    final step = m.stagger;
    navbar.fly(show: true, travel: 16, fade: true, motion: m, delay: step * 0);
    rail.fly(show: true, travel: _railTravel, fade: true, motion: m, delay: step * 1);
    inspector.fly(show: true, travel: _inspectorTravel, fade: true, motion: m, delay: step * 2);
    modeBar.fly(show: true, travel: 24, fade: true, motion: m, delay: step * 3);
    zoomBar.fly(show: true, travel: 24, fade: true, motion: m, delay: step * 4);
  }

  /// Edit → Preview: rail left, inspector right, navbar up, zoom bar down.
  /// Preview → Edit brings them back in reverse order.
  void flyPanels({required bool previewing, required ClayMotion motion}) {
    final order = previewing
        ? [(rail, _railTravel), (inspector, _inspectorTravel), (navbar, _navbarTravel), (zoomBar, _zoomBarTravel)]
        : [(zoomBar, _zoomBarTravel), (navbar, _navbarTravel), (inspector, _inspectorTravel), (rail, _railTravel)];
    for (final (i, (panel, travel)) in order.indexed) {
      panel.fly(show: !previewing, travel: travel, fade: false, motion: motion, delay: motion.stagger * i);
    }
    modeShift.springTo(previewing ? 1 : 0, spring: motion.gentle);
  }

  void dispose() {
    for (final f in [navbar, rail, inspector, modeBar, zoomBar]) {
      f.dispose();
    }
    modeShift.dispose();
  }
}
