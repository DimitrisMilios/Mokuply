import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocuply/core/constants/store_specs.dart';
import 'package:mocuply/models/canvas_device_item.dart';
import 'package:mocuply/models/canvas_image_item.dart';
import 'package:mocuply/models/project_template.dart';
import 'package:mocuply/models/template_data.dart';
import 'package:mocuply/services/storage_service.dart';
import 'package:mocuply/services/template_package.dart';
import 'package:mocuply/viewmodels/editor/editor_viewmodel.dart';
import 'package:mocuply/viewmodels/library_viewmodel.dart';

void main() {
  final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
  final jpg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 4, 5, 6]);

  ProjectTemplate greekTemplate() => ProjectTemplate(
        id: 'custom_1',
        title: 'Το πρότυπό μου',
        category: 'Παραγωγικότητα',
        description: 'Ελληνικό κείμενο',
        previewGradient: const [Colors.white, Colors.black],
        platform: TargetPlatformType.appStore,
        initialScreenshots: [
          TemplateData(
            titleText: 'Οργάνωσε την ημέρα σου',
            subtitleText: 'Όλα σε ένα μέρος',
            customBackgroundImageBytes: jpg,
            devices: [CanvasDeviceItem(id: 'dev_1', iosScreenshotBytes: png, androidScreenshotBytes: jpg)],
            customImageItems: [CanvasImageItem(id: 'img_1', imageBytes: png, opacity: 0.5)],
          ),
        ],
      );

  test('zip round trip keeps Greek text and every image', () {
    final decoded = TemplatePackage.decode(TemplatePackage.encode(greekTemplate()));
    final screen = decoded.initialScreenshots.single;

    expect(decoded.title, 'Το πρότυπό μου');
    expect(decoded.category, 'Παραγωγικότητα');
    expect(screen.titleText, 'Οργάνωσε την ημέρα σου');
    expect(screen.subtitleText, 'Όλα σε ένα μέρος');
    expect(screen.customBackgroundImageBytes, jpg);
    expect(screen.devices.single.iosScreenshotBytes, png);
    expect(screen.devices.single.androidScreenshotBytes, jpg);
    expect(screen.customImageItems.single.imageBytes, png);
    expect(screen.customImageItems.single.opacity, 0.5);
  });

  test('legacy JSON .mokuply decodes as UTF-8', () {
    final legacy = Uint8List.fromList(utf8.encode(jsonEncode(greekTemplate().toJson())));
    final decoded = TemplatePackage.decode(legacy);

    expect(decoded.title, 'Το πρότυπό μου');
    expect(decoded.initialScreenshots.single.titleText, 'Οργάνωσε την ημέρα σου');
    expect(decoded.initialScreenshots.single.devices.single.iosScreenshotBytes, isNull);
  });

  test('browser-storage JSON leaves images out', () {
    final json = jsonEncode(greekTemplate().toJson());
    expect(json, isNot(contains('iosScreenshot')));
    expect(json, isNot(contains('customImageItems')));
  });

  test('a file that is not a template throws FormatException', () {
    expect(() => TemplatePackage.decode(Uint8List.fromList(utf8.encode('hello'))), throwsFormatException);
  });

  test('templates saved in the browser keep their screenshots after a reload, until deleted', () async {
    final editor = EditorViewModel()..openProject(greekTemplate().initialScreenshots);
    final library = LibraryViewModel(editor: editor);
    await library.saveCurrentAsTemplate(title: 'Το πρότυπό μου', category: 'Εργασία', description: '');

    // A fresh library is what the page builds after a reload.
    final reloaded = LibraryViewModel(editor: EditorViewModel());
    await reloaded.load();
    final saved = reloaded.templates.firstWhere(reloaded.isCustomTemplate);
    expect(saved.title, 'Το πρότυπό μου');
    expect(saved.initialScreenshots.single.devices.single.iosScreenshotBytes, png);
    expect(saved.initialScreenshots.single.customImageItems.single.imageBytes, png);

    await reloaded.deleteCustomTemplate(saved);
    expect(await StorageService.loadTemplateImages(saved.id), isNull);
    final afterDelete = LibraryViewModel(editor: EditorViewModel());
    await afterDelete.load();
    expect(afterDelete.templates.where(afterDelete.isCustomTemplate), isEmpty);
  });
}
