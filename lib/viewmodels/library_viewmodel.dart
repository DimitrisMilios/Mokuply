import 'package:flutter/material.dart';
import '../data/templates/builtin_templates.dart';
import '../models/project_template.dart';
import '../models/template_data.dart';
import '../services/export_service.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';
import '../services/template_package.dart';
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
      final custom = await StorageService.loadCustomTemplates();
      _setCustomTemplates(custom);
      final draft = await StorageService.loadActiveDraft();
      if (draft != null && draft.isNotEmpty) _savedDraft = draft;
      notifyListeners();
      await _restoreTemplateImages(custom);
    } catch (e) {
      debugPrint('LibraryViewModel.load error: $e');
    }
  }

  /// The gallery shows first; the images follow from binary storage.
  Future<void> _restoreTemplateImages(List<ProjectTemplate> templates) async {
    final loaded = await Future.wait(templates.map((t) => StorageService.loadTemplateImages(t.id)));
    final restored = {for (final t in loaded.nonNulls) t.id: t};
    if (restored.isEmpty) return;
    // Templates added or deleted meanwhile are left as they are.
    _setCustomTemplates([for (final t in _customTemplates) restored[t.id] ?? t]);
    notifyListeners();
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

  /// Downloads the open project as a template zip, screenshots included.
  Future<void> exportTemplateFile({required String title, required String category, required String description}) {
    final template = _templateFromProject(title: title, category: category, description: description);
    // Keep letters of any script, so a Greek title stays readable.
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final filename = '${slug.isEmpty ? 'template' : slug}.zip';
    return ExportService.downloadFileWeb(
      bytes: TemplatePackage.encode(template),
      filename: filename,
      mimeType: 'application/zip',
    );
  }

  /// Asks for a template zip (or an older `.mokuply`), adds it to the gallery
  /// and opens it. Returns null when cancelled; throws [FormatException] for
  /// a bad file.
  Future<ProjectTemplate?> importTemplateFile() async {
    final bytes = await FileService.pickTemplateFileBytes();
    if (bytes == null) return null;
    final template = TemplatePackage.decode(bytes);
    await _addCustomTemplate(template);
    openTemplate(template);
    return template;
  }

  /// True for templates the user saved or imported, which can be deleted.
  bool isCustomTemplate(ProjectTemplate template) => _customTemplates.any((t) => t.id == template.id);

  Future<void> deleteCustomTemplate(ProjectTemplate template) async {
    _setCustomTemplates(_customTemplates.where((t) => t.id != template.id).toList());
    notifyListeners();
    await StorageService.saveCustomTemplates(_customTemplates);
    await StorageService.deleteTemplateImages(template.id);
  }

  Future<void> _addCustomTemplate(ProjectTemplate template) async {
    _setCustomTemplates([template, ..._customTemplates.where((t) => t.id != template.id)]);
    notifyListeners();
    await StorageService.saveCustomTemplates(_customTemplates);
    await StorageService.saveTemplateImages(template);
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
