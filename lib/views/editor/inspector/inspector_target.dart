import 'package:flutter/material.dart';
import '../../../models/element_kind.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../panels/frame_inspector.dart';
import '../panels/image_inspector.dart';
import '../panels/screen_inspector.dart';
import '../panels/text_inspector.dart';

/// What the inspector is showing: the selected element (and its position in
/// its list, for the title) or the screen itself. Compared by value, so the
/// inspector only rebuilds when the selection really changes.
@immutable
class InspectorFocus {
  final int screenIndex;
  final String screenName;
  final int screenCount;
  final String? elementId;
  final ScreenInspectorSection section;

  /// 1-based number of the selected frame or image, 0 when not applicable or gone.
  final int ordinal;

  const InspectorFocus({
    required this.screenIndex,
    required this.screenName,
    required this.screenCount,
    required this.elementId,
    required this.section,
    required this.ordinal,
  });

  factory InspectorFocus.of(EditorViewModel vm) {
    final id = vm.selectedElementId;
    final int ordinal = switch (ElementKind.of(id)) {
      ElementKind.device => vm.devices.indexWhere((d) => d.id == id) + 1,
      ElementKind.image => vm.customImageItems.indexWhere((i) => i.id == id) + 1,
      ElementKind.text => vm.elementExists(id!) ? 1 : 0,
      _ => 1,
    };
    return InspectorFocus(
      screenIndex: vm.selectedIndex,
      screenName: vm.screenNameAt(vm.selectedIndex),
      screenCount: vm.screenshotsCount,
      elementId: id,
      section: vm.screenSection,
      ordinal: ordinal,
    );
  }

  /// Key of the properties body; a new key crossfades the body.
  String get bodyKey => '$screenIndex:${elementId ?? 'screen:${section.name}'}';

  @override
  bool operator ==(Object other) =>
      other is InspectorFocus &&
      other.screenIndex == screenIndex &&
      other.screenName == screenName &&
      other.screenCount == screenCount &&
      other.elementId == elementId &&
      other.section == section &&
      other.ordinal == ordinal;

  @override
  int get hashCode => Object.hash(screenIndex, screenName, screenCount, elementId, section, ordinal);
}

/// Which inspector to show for a selection: icon, title, hint and body.
class InspectorTarget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget body;

  /// The canvas element this body edits, or null for the screen itself.
  final String? elementId;

  const InspectorTarget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    this.elementId,
  });

  static const String _canvasHint = 'Drag to move, corners to resize, top handle to rotate.';

  static const InspectorTarget _screen = InspectorTarget(
    icon: Icons.tune_rounded,
    title: 'Screen',
    subtitle: 'Layout and backdrop. Click anything on the canvas to edit it.',
    body: ScreenInspector(),
  );

  static InspectorTarget resolve(InspectorFocus s) {
    final id = s.elementId;
    if (id == null || s.ordinal <= 0) return _screen;
    return switch (ElementKind.of(id)) {
      ElementKind.title => const InspectorTarget(
        icon: Icons.title_rounded,
        title: 'Headline',
        subtitle: _canvasHint,
        body: TextInspector(elementId: ElementKind.titleId),
      ),
      ElementKind.subtitle => const InspectorTarget(
        icon: Icons.notes_rounded,
        title: 'Subtitle',
        subtitle: _canvasHint,
        body: TextInspector(elementId: ElementKind.subtitleId),
      ),
      ElementKind.text => InspectorTarget(
        icon: Icons.text_fields_rounded,
        title: 'Text element',
        subtitle: _canvasHint,
        body: TextInspector(elementId: id),
        elementId: id,
      ),
      ElementKind.device => InspectorTarget(
        icon: Icons.smartphone_rounded,
        title: 'Phone frame #${s.ordinal}',
        subtitle: 'Screenshots, style, size and tilt',
        body: FrameInspector(deviceId: id),
        elementId: id,
      ),
      ElementKind.image => InspectorTarget(
        icon: Icons.image_rounded,
        title: 'Image #${s.ordinal}',
        subtitle: 'Size, tilt, opacity and shadow',
        body: ImageInspector(imageId: id),
        elementId: id,
      ),
      null => _screen,
    };
  }
}
