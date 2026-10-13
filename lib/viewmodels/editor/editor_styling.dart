part of 'editor_viewmodel.dart';

/// Screen-wide look of the active screen: store, layout and background.
mixin _Styling on _EditorState {
  LayoutMode get layoutMode => data.layoutMode;
  String get titleText => data.titleText;
  String get subtitleText => data.subtitleText;
  double get titleSize => data.titleSize;
  int get selectedGradientIndex => data.selectedGradientIndex;
  Color? get customBackgroundColor => data.customBackgroundColor;
  Uint8List? get customBackgroundImageBytes => data.customBackgroundImageBytes;

  /// Switches the active store for every screen. Nothing else changes: the
  /// design is shared and realistic frames resolve per store.
  void setPlatform(TargetPlatformType newPlatform) {
    if (_screens.every((s) => s.platform == newPlatform)) return;
    _screens = [for (final s in _screens) s.copyWith(platform: newPlatform)];
    notifyListeners();
  }

  /// Applies a layout preset (headline anchors and phone placement).
  void setLayoutMode(LayoutMode mode) => _updateActive(data.withLayout(mode));

  /// Puts frames and headlines back at their default position, size and tilt.
  void resetCanvasOffsets() => _updateActive(data.withResetPositions());

  // --- Background ---

  void setGradientIndex(int index) => _updateActive(data.withGradientPreset(index));

  void setCustomBackgroundColor(Color color) => _updateActive(data.withSolidBackground(color));

  void setCustomBackgroundImage(Uint8List? bytes) =>
      _updateActive(data.copyWith(customBackgroundImageBytes: () => bytes));

  /// Picks a gradient preset, dropping any background image.
  void chooseGradient(int index) =>
      _updateActive(data.copyWith(customBackgroundImageBytes: () => null).withGradientPreset(index));

  /// Picks a solid colour, dropping any background image.
  void chooseSolidColor(Color color) =>
      _updateActive(data.copyWith(customBackgroundImageBytes: () => null).withSolidBackground(color));

  Future<void> pickCustomBackgroundImage() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) setCustomBackgroundImage(bytes);
  }
}
