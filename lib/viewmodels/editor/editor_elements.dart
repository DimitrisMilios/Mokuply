part of 'editor_viewmodel.dart';

/// Adding, editing and removing the elements of a screen. The geometry and
/// text edits are pure functions in `ScreenElementEdits`.
mixin _ElementEditing on _EditorState, _Selection {
  List<CanvasDeviceItem> get devices => data.effectiveDevices;
  List<CanvasImageItem> get customImageItems => data.customImageItems;
  List<CanvasTextItem> get customTextItems => data.customTextItems;

  /// True when [id] is an element of the active screen.
  bool elementExists(String id) => data.hasElement(id);

  /// Stored offset of element [id] on the active screen, or null if it is gone.
  Offset? elementOffset(String id) => data.elementOffset(id);

  /// Any text element of the active screen in one shape, or null.
  TextElement? textElement(String id) => data.textElement(id);

  /// Selects [id] and replaces the active screen with [updated], notifying once.
  void _updateActiveSelecting(String id, TemplateData updated) {
    _select(id);
    _updateActive(updated);
  }

  // --- Geometry (any screen, any element) ---

  /// Moves element [id] of screen [index]; positions are shared by both stores.
  void moveElement(int index, String id, double offsetX, double offsetY) {
    if (index < 0 || index >= _screens.length) return;
    _replaceScreen(index, _screens[index].moveElement(id, offsetX, offsetY));
  }

  /// Phone frames and images take a scale factor, text a font size in export px.
  void resizeElement(int index, String id, double value) {
    if (index < 0 || index >= _screens.length) return;
    _replaceScreen(index, _screens[index].resizeElement(id, value));
  }

  /// Rotates a phone frame, image or extra text. Headlines cannot rotate.
  void rotateElement(int index, String id, double degrees) {
    if (index < 0 || index >= _screens.length) return;
    _replaceScreen(index, _screens[index].rotateElement(id, degrees));
  }

  /// Moves the selected element by ([dx], [dy]) offset units (keyboard arrows).
  void nudgeSelected(double dx, double dy) {
    final id = _selectedElementId;
    final current = id == null ? null : elementOffset(id);
    if (id == null || current == null) return;
    moveElement(_selectedIndex, id, current.dx + dx, current.dy + dy);
  }

  // --- Duplicate and remove (any element type) ---

  /// Copies a phone frame, image or extra text next to the original and
  /// selects the copy. The headline and subtitle are unique.
  void duplicateElement(String id) {
    final kind = ElementKind.of(id);
    if (kind == null || !kind.isFreeform) return;
    final newId = kind.newId();
    final updated = data.duplicateElement(id, newId);
    if (identical(updated, data)) return;
    _updateActiveSelecting(newId, updated);
  }

  /// Removes any element of the active screen. The headline and subtitle are
  /// cleared instead; the last phone frame is kept.
  void removeElement(String id) {
    final kind = ElementKind.of(id);
    if (kind == null) return;
    if (kind.isHeadline) {
      if (_selectedElementId == id) _select(null);
      _updateActive(data.editText(id, text: ''));
      return;
    }
    if (kind == ElementKind.device && devices.length <= 1) return;
    _select(null);
    _updateActive(data.removeElement(id));
  }

  void removeSelectedElement() {
    final id = _selectedElementId;
    if (id != null) removeElement(id);
  }

  // --- Phone frames ---

  void addDeviceFrame([DeviceFrameStyle? style]) {
    final id = ElementKind.device.newId();
    final frame = CanvasDeviceItem(
      id: id,
      frameStyle: style ?? DeviceFrameStyle.realistic,
      scale: 0.75,
      offsetX: devices.length * 90.0 - 45.0,
    );
    _updateActiveSelecting(id, data.copyWith(devices: [...devices, frame]));
  }

  /// Removes a frame (never the last one); a removed selection falls back to
  /// the first remaining frame.
  void removeDeviceFrame(String deviceId) {
    final updated = data.removeElement(deviceId);
    if (identical(updated, data)) return;
    if (_selectedDeviceId == deviceId) _select(updated.effectiveDevices.first.id);
    _updateActive(updated);
  }

  void setDeviceFrameStyle(String id, DeviceFrameStyle style) =>
      _updateActive(data.updateDevice(id, (d) => d.copyWith(frameStyle: style)));

  void setDeviceFrameScale(String id, double scale) =>
      _updateActive(data.updateDevice(id, (d) => d.copyWith(scale: scale)));

  void setDeviceFrameRotation(String id, double rotation) =>
      _updateActive(data.updateDevice(id, (d) => d.copyWith(rotation: rotation)));

  void setDeviceFrameShadow(String id, bool hasShadow) =>
      _updateActive(data.updateDevice(id, (d) => d.copyWith(hasShadow: hasShadow)));

  /// Stores the screenshot shown inside [deviceId] on [target] (iPhone for
  /// the App Store, Android for Google Play). Pass null to remove it.
  void setDeviceScreenshot(String deviceId, TargetPlatformType target, Uint8List? bytes) =>
      _updateActive(data.updateDevice(deviceId, (d) => d.withScreenshotFor(target, bytes)));

  Future<void> pickDeviceScreenshot(String deviceId, TargetPlatformType target) async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) setDeviceScreenshot(deviceId, target, bytes);
  }

  /// Uploads a screenshot for the previewed store into the selected (or
  /// first) phone frame and keeps that frame selected.
  Future<void> uploadScreenshotToSelectedFrame() async {
    final device = selectedDevice;
    if (device == null) return;
    selectElement(device.id);
    await pickDeviceScreenshot(device.id, platform);
  }

  // --- Images ---

  Future<void> pickAndAddCustomImageItem() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) addCustomImageItem(bytes);
  }

  void addCustomImageItem(Uint8List bytes) {
    final id = ElementKind.image.newId();
    final image = CanvasImageItem(id: id, imageBytes: bytes);
    _updateActiveSelecting(id, data.copyWith(customImageItems: [...customImageItems, image]));
  }

  /// Removes an image; a removed selection falls back to the first remaining image.
  void removeCustomImageItem(String imageId) {
    final updated = data.removeElement(imageId);
    if (_selectedImageId == imageId) {
      final next = updated.customImageItems.firstOrNull?.id;
      _selectedImageId = next;
      _selectedElementId = next;
    }
    _updateActive(updated);
  }

  void setCustomImageScale(String id, double scale) =>
      _updateActive(data.updateImage(id, (i) => i.copyWith(scale: scale)));

  void setCustomImageRotation(String id, double rotation) =>
      _updateActive(data.updateImage(id, (i) => i.copyWith(rotation: rotation)));

  void setCustomImageOpacity(String id, double opacity) =>
      _updateActive(data.updateImage(id, (i) => i.copyWith(opacity: opacity)));

  void setCustomImageShadow(String id, bool hasShadow) =>
      _updateActive(data.updateImage(id, (i) => i.copyWith(hasShadow: hasShadow)));

  // --- Text ---

  void addCustomTextElement() {
    final id = ElementKind.text.newId();
    final text = CanvasTextItem(id: id, text: 'New Text Element', fontSize: 28.0, offsetY: 80.0);
    _updateActiveSelecting(id, data.copyWith(customTextItems: [...customTextItems, text]));
  }

  /// Removes an extra text; a removed selection falls back to the first remaining one.
  void removeCustomTextElement(String id) {
    final updated = data.removeElement(id);
    if (_selectedTextId == id) {
      final next = updated.customTextItems.firstOrNull?.id;
      _selectedTextId = next;
      _selectedElementId = next;
    }
    _updateActive(updated);
  }

  /// Edits the headline, the subtitle or an extra text of the active screen.
  void editText(
    String id, {
    String? text,
    String? font,
    double? fontSize,
    FontWeight? weight,
    Color? color,
    TextAlign? alignment,
    double? rotation,
  }) {
    _updateActive(
      data.editText(
        id,
        text: text,
        font: font,
        fontSize: fontSize,
        weight: weight,
        color: color,
        alignment: alignment,
        rotation: rotation,
      ),
    );
  }

  void setTitleText(String text) => editText(ElementKind.titleId, text: text);
  void setSubtitleText(String text) => editText(ElementKind.subtitleId, text: text);
  void setTitleFont(String font) => editText(ElementKind.titleId, font: font);
  void setTitleSize(double size) => editText(ElementKind.titleId, fontSize: size);
}
