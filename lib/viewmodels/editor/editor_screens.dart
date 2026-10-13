part of 'editor_viewmodel.dart';

/// Adding, naming, ordering and removing the screens of the project.
mixin _ScreenManagement on _EditorState, _Selection {
  /// Display name of screen [index] (falls back to its number).
  String screenNameAt(int index) {
    final name = _screens[index].name.trim();
    return name.isEmpty ? 'Screen ${index + 1}' : name;
  }

  /// Appends a screen that inherits the look of the active one, with
  /// placeholder words and no screenshots, and selects it.
  void addScreenshot() {
    _screens.add(data.asNewScreen());
    _selectScreenSilently(_screens.length - 1);
    _changed();
  }

  void removeScreenshot(int index) {
    if (_screens.length <= 1 || index < 0 || index >= _screens.length) return;
    _screens.removeAt(index);
    _selectScreenSilently(_selectedIndex.clamp(0, _screens.length - 1));
    _changed();
  }

  /// Inserts a copy of screen [index] after it and selects the copy.
  void duplicateScreenshot(int index) {
    if (index < 0 || index >= _screens.length) return;
    final source = _screens[index];
    _screens.insert(index + 1, source.copyWith(name: source.name.isEmpty ? '' : '${source.name} copy'));
    _selectScreenSilently(index + 1);
    _changed();
  }

  void setScreenName(int index, String name) {
    if (index < 0 || index >= _screens.length) return;
    _replaceScreen(index, _screens[index].copyWith(name: name.trim()));
  }

  /// Moves screen [from] to position [to], keeping it selected.
  void moveScreenshot(int from, int to) {
    if (from < 0 || from >= _screens.length) return;
    if (to < 0 || to >= _screens.length || from == to) return;
    _screens.insert(to, _screens.removeAt(from));
    _selectedIndex = to;
    _changed();
  }

  /// Copies the look of screen [sourceIndex] onto every other screen. Each
  /// screen keeps its own words, screenshots, images and extra text.
  void applyStyleToAllScreens(int sourceIndex) {
    if (sourceIndex < 0 || sourceIndex >= _screens.length) return;
    final source = _screens[sourceIndex];
    for (int i = 0; i < _screens.length; i++) {
      if (i != sourceIndex) _screens[i] = _screens[i].withStyleOf(source);
    }
    _changed();
  }

  /// Replaces the project with the "Reset set" starter.
  void resetToDefaults() {
    _screens = List.of(BuiltInTemplates.resetSet.initialScreenshots);
    _selectScreenSilently(0);
    notifyListeners();
  }

  void _selectScreenSilently(int index) {
    _selectedIndex = index;
    _clearSelection();
  }
}
