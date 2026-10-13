part of 'editor_viewmodel.dart';

/// What is selected: the active screen, the element on it, the inspector
/// section and which store rows are drawn.
mixin _Selection on _EditorState {
  ScreenInspectorSection _screenSection = ScreenInspectorSection.layout;
  bool _showBothStores = true;
  int _textFocusRequest = 0;

  /// 'title', 'subtitle', or a `dev_` / `img_` / `txt_` id; null for the screen itself.
  String? get selectedElementId => _selectedElementId;

  /// The last phone frame, image and extra text that were selected. They
  /// survive selecting something else, so "Shot" still knows its frame.
  String? get selectedDeviceId => _selectedDeviceId;
  String? get selectedImageId => _selectedImageId;
  String? get selectedTextId => _selectedTextId;

  /// Inspector section shown while nothing on the canvas is selected.
  ScreenInspectorSection get screenSection => _screenSection;

  /// Canvas rows: both stores side by side, or only the active one.
  bool get showBothStores => _showBothStores;

  /// Bumped when the canvas asks the inspector to focus its text field
  /// (double-click on a text element).
  int get textFocusRequest => _textFocusRequest;

  /// Store rows drawn on the canvas, top to bottom.
  List<TargetPlatformType> get visibleStores =>
      _showBothStores ? const [TargetPlatformType.appStore, TargetPlatformType.googlePlay] : [platform];

  /// The element highlighted on screen [screenIndex], or null. Starter
  /// templates reuse element ids across screens, so a selection only counts
  /// on the active screen.
  String? selectedElementOn(int screenIndex) => screenIndex == _selectedIndex ? _selectedElementId : null;

  /// Selected phone frame on the active screen (falls back to the first one).
  CanvasDeviceItem? get selectedDevice {
    final devices = data.effectiveDevices;
    if (devices.isEmpty) return null;
    return devices.where((d) => d.id == _selectedDeviceId).firstOrNull ?? devices.first;
  }

  /// Selected image on the active screen (falls back to the first one).
  CanvasImageItem? get selectedCustomImage {
    final images = data.customImageItems;
    if (images.isEmpty) return null;
    return images.where((i) => i.id == _selectedImageId).firstOrNull ?? images.first;
  }

  void selectElement(String? id) {
    _select(id);
    notifyListeners();
  }

  /// Makes screen [index] active and selects element [id] on it, with one
  /// notification (a click on a canvas element).
  void selectElementOn(int index, String? id) {
    if (index >= 0 && index < _screens.length && index != _selectedIndex) {
      _selectedIndex = index;
      _clearSelection();
    }
    _select(id);
    notifyListeners();
  }

  void _select(String? id) {
    _selectedElementId = id;
    switch (ElementKind.of(id)) {
      case ElementKind.device:
        _selectedDeviceId = id;
      case ElementKind.image:
        _selectedImageId = id;
      case ElementKind.text:
        _selectedTextId = id;
      case ElementKind.title || ElementKind.subtitle:
        break;
      case null:
        _clearSelection();
    }
  }

  void selectScreenshot(int index) {
    if (index < 0 || index >= _screens.length || index == _selectedIndex) return;
    _selectedIndex = index;
    _clearSelection();
    notifyListeners();
  }

  /// Deselects everything and opens [section] of the screen inspector.
  void showScreenSection(ScreenInspectorSection section) {
    _screenSection = section;
    _clearSelection();
    notifyListeners();
  }

  void setShowBothStores(bool value) {
    if (_showBothStores == value) return;
    _showBothStores = value;
    notifyListeners();
  }

  /// Asks the inspector to focus the text field of the selected text element.
  void requestTextFocus() {
    _textFocusRequest++;
    notifyListeners();
  }
}
