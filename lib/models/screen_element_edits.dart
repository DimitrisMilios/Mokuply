import 'dart:ui';

import '../core/constants/store_specs.dart';
import 'canvas_device_item.dart';
import 'canvas_image_item.dart';
import 'canvas_text_item.dart';
import 'element_kind.dart';
import 'template_data.dart';
import 'text_element.dart';

/// Pure edits of one element of a screen, addressed by element id.
///
/// Each method returns a new [TemplateData], or `this` unchanged when the
/// edit does not apply (unknown id, or a headline asked to rotate).
extension ScreenElementEdits on TemplateData {
  /// True when [id] is an element of this screen.
  bool hasElement(String id) {
    return switch (ElementKind.of(id)) {
      ElementKind.title || ElementKind.subtitle => true,
      ElementKind.device => effectiveDevices.any((d) => d.id == id),
      ElementKind.image => customImageItems.any((i) => i.id == id),
      ElementKind.text => customTextItems.any((t) => t.id == id),
      null => false,
    };
  }

  CanvasDeviceItem? deviceById(String id) => effectiveDevices.where((d) => d.id == id).firstOrNull;
  CanvasImageItem? imageById(String id) => customImageItems.where((i) => i.id == id).firstOrNull;
  CanvasTextItem? textById(String id) => customTextItems.where((t) => t.id == id).firstOrNull;

  /// Stored offset of element [id] in design offset units, or null if it is gone.
  Offset? elementOffset(String id) {
    switch (ElementKind.of(id)) {
      case ElementKind.title:
        return Offset(textOffsetX, textOffsetY);
      case ElementKind.subtitle:
        return Offset(subtitleOffsetX, subtitleOffsetY);
      case ElementKind.device:
        final d = deviceById(id);
        return d == null ? null : Offset(d.offsetX, d.offsetY);
      case ElementKind.image:
        final i = imageById(id);
        return i == null ? null : Offset(i.offsetX, i.offsetY);
      case ElementKind.text:
        final t = textById(id);
        return t == null ? null : Offset(t.offsetX, t.offsetY);
      case null:
        return null;
    }
  }

  // --- Per-collection updates ---

  TemplateData updateDevice(String id, CanvasDeviceItem Function(CanvasDeviceItem) edit) =>
      copyWith(devices: [for (final d in effectiveDevices) d.id == id ? edit(d) : d]);

  TemplateData updateImage(String id, CanvasImageItem Function(CanvasImageItem) edit) =>
      copyWith(customImageItems: [for (final i in customImageItems) i.id == id ? edit(i) : i]);

  TemplateData updateText(String id, CanvasTextItem Function(CanvasTextItem) edit) =>
      copyWith(customTextItems: [for (final t in customTextItems) t.id == id ? edit(t) : t]);

  // --- Geometry ---

  /// Moves element [id] to ([x], [y]) design offset units (shared by both stores).
  TemplateData moveElement(String id, double x, double y) {
    return switch (ElementKind.of(id)) {
      ElementKind.title => copyWith(textOffsetX: x, textOffsetY: y),
      ElementKind.subtitle => copyWith(subtitleOffsetX: x, subtitleOffsetY: y),
      ElementKind.device => updateDevice(id, (d) => d.copyWith(offsetX: x, offsetY: y)),
      ElementKind.image => updateImage(id, (i) => i.copyWith(offsetX: x, offsetY: y)),
      ElementKind.text => updateText(id, (t) => t.copyWith(offsetX: x, offsetY: y)),
      null => this,
    };
  }

  /// Resizes element [id]: phone frames and images take a scale factor, text
  /// takes a font size in export pixels. Values are clamped to their limits.
  TemplateData resizeElement(String id, double value) {
    return switch (ElementKind.of(id)) {
      ElementKind.title => copyWith(titleSize: value.clamp(TextSizeLimits.titleMin, TextSizeLimits.titleMax)),
      ElementKind.subtitle => copyWith(
        subtitleSize: value.clamp(TextSizeLimits.subtitleMin, TextSizeLimits.subtitleMax),
      ),
      ElementKind.device => updateDevice(
        id,
        (d) => d.copyWith(scale: value.clamp(ScaleLimits.deviceMin, ScaleLimits.deviceMax)),
      ),
      ElementKind.image => updateImage(
        id,
        (i) => i.copyWith(scale: value.clamp(ScaleLimits.imageMin, ScaleLimits.imageMax)),
      ),
      ElementKind.text => updateText(
        id,
        (t) => t.copyWith(fontSize: value.clamp(TextSizeLimits.customMin, TextSizeLimits.customMax)),
      ),
      null => this,
    };
  }

  /// Rotates a phone frame, image or extra text to [degrees], normalised to
  /// (-180, 180]. The headline and subtitle cannot rotate.
  TemplateData rotateElement(String id, double degrees) {
    final deg = normalizeDegrees(degrees);
    return switch (ElementKind.of(id)) {
      ElementKind.device => updateDevice(id, (d) => d.copyWith(rotation: deg)),
      ElementKind.image => updateImage(id, (i) => i.copyWith(rotation: deg)),
      ElementKind.text => updateText(id, (t) => t.copyWith(rotation: deg)),
      _ => this,
    };
  }

  // --- Add, duplicate, remove ---

  /// Copies element [id] next to the original under [newId]. Headlines are
  /// unique and are not duplicated; returns `this` for them.
  TemplateData duplicateElement(String id, String newId) {
    const double nudge = 40.0;
    switch (ElementKind.of(id)) {
      case ElementKind.device:
        final src = deviceById(id);
        if (src == null) return this;
        final copy = src.copyWith(id: newId, offsetX: src.offsetX + nudge, offsetY: src.offsetY + nudge);
        return copyWith(devices: [...effectiveDevices, copy]);
      case ElementKind.image:
        final src = imageById(id);
        if (src == null) return this;
        final copy = src.copyWith(id: newId, offsetX: src.offsetX + nudge, offsetY: src.offsetY + nudge);
        return copyWith(customImageItems: [...customImageItems, copy]);
      case ElementKind.text:
        final src = textById(id);
        if (src == null) return this;
        final copy = src.copyWith(id: newId, offsetX: src.offsetX + nudge, offsetY: src.offsetY + nudge);
        return copyWith(customTextItems: [...customTextItems, copy]);
      default:
        return this;
    }
  }

  /// Removes a phone frame (never the last one), image or extra text.
  TemplateData removeElement(String id) {
    switch (ElementKind.of(id)) {
      case ElementKind.device:
        if (effectiveDevices.length <= 1) return this;
        return copyWith(devices: effectiveDevices.where((d) => d.id != id).toList());
      case ElementKind.image:
        return copyWith(customImageItems: customImageItems.where((i) => i.id != id).toList());
      case ElementKind.text:
        return copyWith(customTextItems: customTextItems.where((t) => t.id != id).toList());
      default:
        return this;
    }
  }

  // --- Text ---

  /// Any text element of this screen in one shape, or null if [id] is not text.
  TextElement? textElement(String id) {
    switch (ElementKind.of(id)) {
      case ElementKind.title:
        return TextElement(
          id: id,
          kind: ElementKind.title,
          text: titleText,
          font: titleFont,
          fontSize: titleSize,
          weight: titleWeight,
          color: textColor,
          alignment: titleAlignment,
        );
      case ElementKind.subtitle:
        return TextElement(
          id: id,
          kind: ElementKind.subtitle,
          text: subtitleText,
          font: subtitleFont,
          fontSize: subtitleSize,
          weight: subtitleWeight,
          color: subtitleColor,
          alignment: subtitleAlignment,
        );
      case ElementKind.text:
        final t = textById(id);
        if (t == null) return null;
        return TextElement(
          id: id,
          kind: ElementKind.text,
          text: t.text,
          font: t.font,
          fontSize: t.fontSize,
          weight: t.weight,
          color: t.color,
          alignment: t.alignment,
          rotation: t.rotation,
        );
      default:
        return null;
    }
  }

  /// Edits any text element. Rotation only applies to extra text.
  TemplateData editText(
    String id, {
    String? text,
    String? font,
    double? fontSize,
    FontWeight? weight,
    Color? color,
    TextAlign? alignment,
    double? rotation,
  }) {
    return switch (ElementKind.of(id)) {
      ElementKind.title => copyWith(
        titleText: text,
        titleFont: font,
        titleSize: fontSize,
        titleWeight: weight,
        textColor: color,
        titleAlignment: alignment,
      ),
      ElementKind.subtitle => copyWith(
        subtitleText: text,
        subtitleFont: font,
        subtitleSize: fontSize,
        subtitleWeight: weight,
        subtitleColor: color,
        subtitleAlignment: alignment,
      ),
      ElementKind.text => updateText(
        id,
        (t) => t.copyWith(
          text: text,
          font: font,
          fontSize: fontSize,
          weight: weight,
          color: color,
          alignment: alignment,
          rotation: rotation,
        ),
      ),
      _ => this,
    };
  }
}

/// Maps any angle to (-180, 180].
double normalizeDegrees(double degrees) {
  double d = degrees % 360.0;
  if (d > 180.0) d -= 360.0;
  if (d <= -180.0) d += 360.0;
  return d;
}
