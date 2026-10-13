import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../data/templates/builtin_templates.dart';
import '../../models/canvas_device_item.dart';
import '../../models/canvas_image_item.dart';
import '../../models/canvas_text_item.dart';
import '../../models/element_kind.dart';
import '../../models/project_template.dart';
import '../../models/screen_element_edits.dart';
import '../../models/screen_layout_edits.dart';
import '../../models/template_data.dart';
import '../../models/text_element.dart';
import '../../services/draft_autosaver.dart';
import '../../services/file_service.dart';

part 'editor_selection.dart';
part 'editor_elements.dart';
part 'editor_screens.dart';
part 'editor_styling.dart';

/// Sections of the screen inspector shown when no element is selected.
enum ScreenInspectorSection { layout, background }

/// The open project and what is selected in it.
///
/// Every screen is authored once in `DesignSpace`; [platform] only selects
/// which store is previewed. Positions, sizes and tilts are shared by both
/// stores, while each phone frame carries its own iPhone and Android
/// screenshot. The edits themselves are pure functions on [TemplateData]
/// (`ScreenElementEdits`, `ScreenLayoutEdits`); this class applies them,
/// tracks the selection and saves the draft.
class EditorViewModel extends _EditorState with _Selection, _ElementEditing, _ScreenManagement, _Styling {
  EditorViewModel({super.autosaver});

  bool _isHomeScreen = true;

  /// True while the template gallery is shown instead of the editor.
  bool get isHomeScreen => _isHomeScreen;

  /// Opens [screens] in the editor (a template, a restored draft…).
  void openProject(List<TemplateData> screens) {
    _screens = List.of(screens);
    _selectedIndex = 0;
    _isHomeScreen = false;
    _clearSelection();
    notifyListeners();
  }

  void openEditorWithTemplate(ProjectTemplate template) => openProject(template.initialScreenshots);

  void openEditorWithNewProject() => openEditorWithTemplate(BuiltInTemplates.starter);

  /// Leaves the editor; the project is saved as the draft to resume.
  void goBackToHome() {
    _autosaver
      ..schedule(() => _screens)
      ..flush();
    _isHomeScreen = true;
    notifyListeners();
  }
}

/// State shared by the editor mixins. Every edit goes through
/// [_replaceScreen], which saves the draft and notifies once.
abstract class _EditorState extends ChangeNotifier {
  _EditorState({DraftAutosaver? autosaver}) : _autosaver = autosaver ?? DraftAutosaver();

  final DraftAutosaver _autosaver;
  List<TemplateData> _screens = List.of(BuiltInTemplates.starter.initialScreenshots);
  int _selectedIndex = 0;

  String? _selectedElementId;
  String? _selectedDeviceId;
  String? _selectedImageId;
  String? _selectedTextId;

  /// All screens, read-only.
  List<TemplateData> get screenshots => List.unmodifiable(_screens);
  int get screenshotsCount => _screens.length;
  int get selectedIndex => _selectedIndex;

  /// Screen [index] without copying the list (cheap for per-card selectors).
  TemplateData screenAt(int index) => _screens[index];

  /// The active screen.
  TemplateData get data => _screens[_selectedIndex.clamp(0, _screens.length - 1)];

  /// Active store: the row last clicked on the canvas. Screenshot uploads
  /// and single-store downloads target it. Both stores are always exported.
  TargetPlatformType get platform => data.platform;

  /// Replaces screen [index] with [updated], schedules the draft save and
  /// notifies. An identical screen (an edit that did not apply) is ignored.
  void _replaceScreen(int index, TemplateData updated) {
    if (index < 0 || index >= _screens.length) return;
    if (identical(_screens[index], updated)) return;
    _screens[index] = updated;
    _changed();
  }

  void _updateActive(TemplateData updated) => _replaceScreen(_selectedIndex, updated);

  /// Saves the draft soon and notifies listeners.
  void _changed() {
    _autosaver.schedule(() => _screens);
    notifyListeners();
  }

  void _clearSelection() {
    _selectedElementId = null;
    _selectedDeviceId = null;
    _selectedImageId = null;
    _selectedTextId = null;
  }

  @override
  void dispose() {
    _autosaver.dispose();
    super.dispose();
  }
}
