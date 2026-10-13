import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/templates/builtin_templates.dart';
import '../models/project_template.dart';
import '../models/template_data.dart';
import '../services/export_service.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';
import 'editor/editor_viewmodel.dart';

/// The template gallery and the saved draft: what the home page shows, and
/// saving or importing templates from the editor.
class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({required EditorViewModel editor}) : _editor = editor {
    _wasHome = editor.isHomeScreen;
    editor.addListener(_onEditorChanged);
  }

  final EditorViewModel _editor;
  List<ProjectTemplate> _customTemplates = const [];
  List<ProjectTemplate>? _templates;
  List<TemplateData>? _savedDraft;
  bool _wasHome = true;

  /// User templates first, then the built-in starters.
  List<ProjectTemplate> get templates =>
      _templates ??= List.unmodifiable([..._customTemplates, ...BuiltInTemplates.all]);

  bool get hasSavedDraft => _savedDraft?.isNotEmpty ?? false;

  /// Loads user templates and the draft from browser storage.
  Future<void> load() async {
    try {
      _setCustomTemplates(await StorageService.loadCustomTemplates());
      final draft = await StorageService.loadActiveDraft();
      if (draft != null && draft.isNotEmpty) _savedDraft = draft;
      notifyListeners();
    } catch (e) {
      debugPrint('LibraryViewModel.load error: $e');
    }
  }

  /// Coming back from the editor, the project just left is the one to resume.
  void _onEditorChanged() {
    final home = _editor.isHomeScreen;
    if (home && !_wasHome) {
      _savedDraft = _editor.screenshots;
      notifyListeners();
    }
    _wasHome = home;
  }

  void startNewProject() => _editor.openEditorWithNewProject();

  void openTemplate(ProjectTemplate template) => _editor.openEditorWithTemplate(template);

  void restoreSavedDraft() {
    final draft = _savedDraft;
    if (draft != null && draft.isNotEmpty) _editor.openProject(draft);
  }

  void discardSavedDraft() {
    _savedDraft = null;
    StorageService.clearActiveDraft();
    notifyListeners();
  }

  // --- Templates from the open project ---

  ProjectTemplate _templateFromProject({required String title, required String category, required String description}) {
    return ProjectTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      description: description,
      previewGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFF3B82F6)],
      platform: _editor.platform,
      initialScreenshots: _editor.screenshots,
    );
  }

  /// Saves the open project as a gallery template in this browser.
  Future<void> saveCurrentAsTemplate({required String title, required String category, required String description}) {
    return _addCustomTemplate(_templateFromProject(title: title, category: category, description: description));
  }

  /// Downloads the open project as a `.mokuply` template file.
  Future<void> exportTemplateFile({required String title, required String category, required String description}) {
    final template = _templateFromProject(title: title, category: category, description: description);
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(template.toJson())));
    final filename = '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}.mokuply';
    return ExportService.downloadFileWeb(bytes: bytes, filename: filename, mimeType: 'application/json');
  }

  /// Asks for a `.mokuply` file, adds it to the gallery and opens it.
  /// Returns null when cancelled; throws [FormatException] for a bad file.
  Future<ProjectTemplate?> importTemplateFile() async {
    final content = await FileService.pickTemplateFileContent();
    if (content == null) return null;
    final template = await importTemplateFromJson(content);
    if (template == null) throw const FormatException('Not a template file');
    return template;
  }

  /// Adds the template in [jsonString] to the gallery and opens it, or
  /// returns null when the text is not a template.
  Future<ProjectTemplate?> importTemplateFromJson(String jsonString) async {
    try {
      final template = ProjectTemplate.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
      await _addCustomTemplate(template);
      openTemplate(template);
      return template;
    } catch (e) {
      debugPrint('LibraryViewModel.importTemplateFromJson error: $e');
      return null;
    }
  }

  Future<void> _addCustomTemplate(ProjectTemplate template) async {
    _setCustomTemplates([template, ..._customTemplates.where((t) => t.id != template.id)]);
    notifyListeners();
    await StorageService.saveCustomTemplates(_customTemplates);
  }

  void _setCustomTemplates(List<ProjectTemplate> templates) {
    _customTemplates = List.unmodifiable(templates);
    _templates = null;
  }

  @override
  void dispose() {
    _editor.removeListener(_onEditorChanged);
    super.dispose();
  }
}
