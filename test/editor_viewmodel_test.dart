import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocuply/core/constants/store_specs.dart';
import 'package:mocuply/core/layout/canvas_geometry.dart';
import 'package:mocuply/models/canvas_device_item.dart';
import 'package:mocuply/models/template_data.dart';
import 'package:mocuply/viewmodels/editor/editor_viewmodel.dart';
import 'package:mocuply/widgets/canvas/device_frame/device_frame_widget.dart';

void main() {
  _canvasUxTests();
  group('EditorViewModel elements', () {
    late EditorViewModel vm;

    setUp(() {
      vm = EditorViewModel();
    });

    test('initial state contains at least one device frame', () {
      expect(vm.devices.length, greaterThanOrEqualTo(1));
      expect(vm.customImageItems.isEmpty, isTrue);
      expect(vm.selectedDevice, isNotNull);
    });

    test('addDeviceFrame adds a frame and selects it', () {
      final before = vm.devices.length;
      vm.addDeviceFrame(DeviceFrameStyle.minimalOutline);
      expect(vm.devices.length, equals(before + 1));
      expect(vm.selectedDevice?.frameStyle, equals(DeviceFrameStyle.minimalOutline));
      expect(vm.selectedDeviceId, startsWith('dev_'));
    });

    test('removeDeviceFrame removes the targeted frame but keeps at least one', () {
      final before = vm.devices.length;
      vm.addDeviceFrame();
      final addedId = vm.selectedDeviceId!;
      vm.removeDeviceFrame(addedId);
      expect(vm.devices.length, equals(before));
      expect(vm.devices.any((d) => d.id == addedId), isFalse);

      while (vm.devices.length > 1) {
        vm.removeDeviceFrame(vm.devices.last.id);
      }
      vm.removeDeviceFrame(vm.devices.first.id);
      expect(vm.devices.length, equals(1));
    });

    test('setDeviceFrameScale updates the selected device', () {
      final devId = vm.selectedDevice!.id;
      vm.setDeviceFrameScale(devId, 0.95);
      expect(vm.selectedDevice?.scale, equals(0.95));
    });

    test('addCustomImageItem adds an image and selects it', () {
      final dummyBytes = Uint8List.fromList([0, 1, 2, 3]);
      vm.addCustomImageItem(dummyBytes);

      expect(vm.customImageItems.length, equals(1));
      expect(vm.selectedCustomImage?.imageBytes, equals(dummyBytes));
      expect(vm.selectedImageId, startsWith('img_'));
    });

    test('custom image scale and rotation update the selected image', () {
      vm.addCustomImageItem(Uint8List.fromList([0, 1, 2, 3]));
      final imgId = vm.selectedImageId!;

      vm.setCustomImageScale(imgId, 1.5);
      vm.setCustomImageRotation(imgId, 45.0);

      expect(vm.selectedCustomImage?.scale, equals(1.5));
      expect(vm.selectedCustomImage?.rotation, equals(45.0));
    });

    test('removeCustomImageItem deletes the target image', () {
      vm.addCustomImageItem(Uint8List.fromList([0, 1, 2, 3]));
      vm.removeCustomImageItem(vm.selectedImageId!);
      expect(vm.customImageItems.isEmpty, isTrue);
    });
  });

  group('Shared layout across stores', () {
    late EditorViewModel vm;

    setUp(() {
      vm = EditorViewModel();
    });

    test('moving a device on one store moves it on the other store too', () {
      final devId = vm.selectedDevice!.id;

      vm.setPlatform(TargetPlatformType.appStore);
      vm.moveElement(0, devId, 150.0, 250.0);

      vm.setPlatform(TargetPlatformType.googlePlay);
      expect(vm.devices.first.offsetX, equals(150.0));
      expect(vm.devices.first.offsetY, equals(250.0));

      vm.moveElement(0, devId, -80.0, 90.0);
      vm.setPlatform(TargetPlatformType.appStore);
      expect(vm.devices.first.offsetX, equals(-80.0));
      expect(vm.devices.first.offsetY, equals(90.0));
    });

    test('moveElement positions title, subtitle, images and extra text', () {
      vm.moveElement(0, 'title', 10, 20);
      vm.moveElement(0, 'subtitle', 30, 40);
      expect(vm.data.textOffsetX, 10);
      expect(vm.data.textOffsetY, 20);
      expect(vm.data.subtitleOffsetX, 30);
      expect(vm.data.subtitleOffsetY, 40);

      vm.addCustomImageItem(Uint8List.fromList([1]));
      vm.moveElement(0, vm.selectedImageId!, 5, 6);
      expect(vm.selectedCustomImage!.offsetX, 5);
      expect(vm.selectedCustomImage!.offsetY, 6);

      vm.addCustomTextElement();
      vm.moveElement(0, vm.selectedTextId!, 7, 8);
      expect(vm.customTextItems.first.offsetX, 7);
      expect(vm.customTextItems.first.offsetY, 8);
    });

    test('setPlatform only switches the preview store and keeps frame styles', () {
      expect(vm.selectedDevice?.frameStyle, equals(DeviceFrameStyle.realistic));

      vm.setPlatform(TargetPlatformType.googlePlay);
      expect(vm.platform, equals(TargetPlatformType.googlePlay));
      expect(vm.screenshots.every((s) => s.platform == TargetPlatformType.googlePlay), isTrue);
      expect(vm.selectedDevice?.frameStyle, equals(DeviceFrameStyle.realistic));

      vm.setPlatform(TargetPlatformType.appStore);
      expect(vm.selectedDevice?.frameStyle, equals(DeviceFrameStyle.realistic));
    });

    test('realistic frame resolves to the store device name', () {
      expect(DeviceFrameStyle.realistic.labelFor(TargetPlatformType.appStore), 'iPhone 16 Pro Max');
      expect(DeviceFrameStyle.realistic.labelFor(TargetPlatformType.googlePlay), 'Galaxy S26 Ultra');
      expect(DeviceFrameStyle.minimalOutline.labelFor(TargetPlatformType.googlePlay), 'Minimal Dark Frame');
    });

    test('legacy per-device frame names and labels map onto the new styles', () {
      expect(DeviceFrameStyle.fromName('iphone16ProMax'), DeviceFrameStyle.realistic);
      expect(DeviceFrameStyle.fromName('samsungS26Ultra'), DeviceFrameStyle.realistic);
      expect(DeviceFrameStyle.fromName('iPhone 16 Pro Max'), DeviceFrameStyle.realistic);
      expect(DeviceFrameStyle.fromName('Samsung S26 Ultra'), DeviceFrameStyle.realistic);
      expect(DeviceFrameStyle.fromName('minimalOutline'), DeviceFrameStyle.minimalOutline);
      expect(DeviceFrameStyle.fromName('Minimal Dark Frame'), DeviceFrameStyle.minimalOutline);
      expect(DeviceFrameStyle.fromName('none'), DeviceFrameStyle.none);
      expect(DeviceFrameStyle.fromName('Raw Screenshot'), DeviceFrameStyle.none);
      expect(DeviceFrameStyle.fromName(null), DeviceFrameStyle.realistic);
    });

    test('frame style serializes as the enum identifier, not the display label', () {
      for (final style in DeviceFrameStyle.values) {
        expect(DeviceFrameStyle.fromName(style.name), style);
      }
      expect(DeviceFrameStyle.none.name, 'none');
    });
  });

  group('Inspector selection', () {
    late EditorViewModel vm;

    setUp(() {
      vm = EditorViewModel();
    });

    test('adding an element selects it so the inspector opens on it', () {
      vm.addCustomTextElement();
      expect(vm.selectedElementId, startsWith('txt_'));
      vm.addDeviceFrame();
      expect(vm.selectedElementId, startsWith('dev_'));
      vm.addCustomImageItem(Uint8List.fromList([1]));
      expect(vm.selectedElementId, startsWith('img_'));
    });

    test('showScreenSection clears the selection and remembers the section', () {
      vm.addCustomTextElement();
      vm.showScreenSection(ScreenInspectorSection.background);
      expect(vm.selectedElementId, isNull);
      expect(vm.selectedTextId, isNull);
      expect(vm.screenSection, ScreenInspectorSection.background);
    });

    test('headline and subtitle are selectable by id', () {
      vm.selectElement('title');
      expect(vm.selectedElementId, 'title');
      vm.selectElement('subtitle');
      expect(vm.selectedElementId, 'subtitle');
      vm.selectElement(null);
      expect(vm.selectedElementId, isNull);
    });
  });

  group('Per-store screenshots', () {
    late EditorViewModel vm;

    setUp(() {
      vm = EditorViewModel();
    });

    test('each frame keeps an iPhone and an Android screenshot with fallback', () {
      final devId = vm.selectedDevice!.id;
      final ios = Uint8List.fromList([1, 1, 1]);
      final android = Uint8List.fromList([2, 2, 2]);

      vm.setDeviceScreenshot(devId, TargetPlatformType.appStore, ios);
      var dev = vm.selectedDevice!;
      expect(dev.screenshotFor(TargetPlatformType.appStore), same(ios));
      expect(dev.screenshotFor(TargetPlatformType.googlePlay), same(ios), reason: 'falls back to iPhone image');
      expect(dev.hasOwnScreenshotFor(TargetPlatformType.googlePlay), isFalse);

      vm.setDeviceScreenshot(devId, TargetPlatformType.googlePlay, android);
      dev = vm.selectedDevice!;
      expect(dev.screenshotFor(TargetPlatformType.appStore), same(ios));
      expect(dev.screenshotFor(TargetPlatformType.googlePlay), same(android));

      vm.setDeviceScreenshot(devId, TargetPlatformType.appStore, null);
      dev = vm.selectedDevice!;
      expect(dev.screenshotFor(TargetPlatformType.appStore), same(android), reason: 'falls back to Android image');
    });
  });

  group('CanvasGeometry', () {
    test('Apple export renders the design 1:1', () {
      final g = CanvasGeometry(TargetPlatformType.appStore.targetSize);
      expect(g.scale, closeTo(1.0, 1e-9));
      expect(g.textScale, closeTo(DesignSpace.textScale, 1e-9));
      expect(g.elementCenter(anchorFraction: 0.5, offsetX: 0, offsetY: 0), const Offset(660, 1434));
    });

    test('Google Play shares the Apple canvas, so it also renders 1:1', () {
      final g = CanvasGeometry(TargetPlatformType.googlePlay.targetSize);
      expect(TargetPlatformType.googlePlay.targetSize, TargetPlatformType.appStore.targetSize);
      expect(g.scale, closeTo(1.0, 1e-9));
      expect(g.elementCenter(anchorFraction: 0.5, offsetX: 0, offsetY: 0), const Offset(660, 1434));
    });

    test('a smaller canvas still fits the whole design and centres it', () {
      final g = CanvasGeometry(const Size(1440, 2560));
      expect(g.scale, closeTo(2560 / 2868, 1e-9));
      expect(g.designAreaSize.height, closeTo(2560, 1e-6));
      expect(g.designAreaSize.width, lessThan(1440));
      expect(g.elementCenter(anchorFraction: 0.5, offsetX: 0, offsetY: 0), const Offset(720, 1280));
    });

    test('font sizes are export pixels', () {
      final g = CanvasGeometry(TargetPlatformType.appStore.targetSize);
      expect(g.textScale, closeTo(1.0, 1e-9));
    });

    test('preview cards of equal height show both stores at the same scale', () {
      const height = 620.0;
      final apple = CanvasGeometry(Size(height * TargetPlatformType.appStore.aspectRatio, height));
      final google = CanvasGeometry(Size(height * TargetPlatformType.googlePlay.aspectRatio, height));
      expect(apple.scale, closeTo(google.scale, 1e-9));
    });

    test('an element keeps the same relative position on canvases of different size', () {
      final apple = CanvasGeometry(TargetPlatformType.appStore.targetSize);
      final google = CanvasGeometry(const Size(1440, 2560));

      final a = apple.elementCenter(anchorFraction: 0.62, offsetX: 120, offsetY: -60);
      final b = google.elementCenter(anchorFraction: 0.62, offsetX: 120, offsetY: -60);

      // Same displacement from the centre, scaled by the store's uniform factor.
      final aFromCenter = a - apple.canvasCenter;
      final bFromCenter = b - google.canvasCenter;
      expect(bFromCenter.dx / aFromCenter.dx, closeTo(google.scale / apple.scale, 1e-9));
      expect(bFromCenter.dy / aFromCenter.dy, closeTo(google.scale / apple.scale, 1e-9));
    });

    test('drag deltas round-trip through offset units', () {
      final g = CanvasGeometry(const Size(285.3, 620));
      const dragged = Offset(12.5, -7.25);
      final units = g.deltaToOffsetUnits(dragged);
      final moved = g.elementCenter(anchorFraction: 0.5, offsetX: units.dx, offsetY: units.dy) -
          g.elementCenter(anchorFraction: 0.5, offsetX: 0, offsetY: 0);
      expect(moved.dx, closeTo(dragged.dx, 1e-9));
      expect(moved.dy, closeTo(dragged.dy, 1e-9));
    });
  });

  group('Device frame footprint', () {
    test('outer frame size depends only on scale, never on the store', () {
      final apple = CanvasGeometry(TargetPlatformType.appStore.targetSize);
      final google = CanvasGeometry(const Size(1440, 2560));
      expect(DeviceFrameWidget.outerWidthFor(apple.scale), closeTo(1320 * 0.72 + 20, 1e-9));
      expect(
        DeviceFrameWidget.outerWidthFor(google.scale) / DeviceFrameWidget.outerWidthFor(apple.scale),
        closeTo(google.scale, 1e-9),
      );
      expect(DeviceFrameWidget.bodyHeightFor(1.0) / DeviceFrameWidget.bodyWidthFor(1.0), closeTo(19.5 / 9, 1e-9));
    });
  });

  group('Serialization', () {
    test('legacy drafts with per-store offsets and device names still load', () {
      final legacy = <String, dynamic>{
        'platform': 'googlePlay',
        'frameStyle': 'samsungS26Ultra',
        'textOffsetX': -140.0,
        'textOffsetY': -60.0,
        'appStoreTextOffsetX': -140.0,
        'googlePlayTextOffsetX': -999.0,
        'devices': [
          {
            'id': 'dev_1',
            'frameStyle': 'iphone16ProMax',
            'scale': 0.92,
            'offsetX': -120.0,
            'offsetY': 280.0,
            'rotation': -22.0,
            'hasShadow': true,
            'appStoreOffsetX': -120.0,
            'googlePlayOffsetX': 50.0,
          }
        ],
      };

      final data = TemplateData.fromJson(legacy);
      expect(data.platform, TargetPlatformType.googlePlay);
      expect(data.frameStyle, DeviceFrameStyle.realistic);
      expect(data.textOffsetX, -140.0);
      expect(data.devices.single.frameStyle, DeviceFrameStyle.realistic);
      expect(data.devices.single.offsetX, -120.0);
      expect(data.devices.single.rotation, -22.0);
    });

    test('legacy drafts without a font unit are converted to export pixels', () {
      final legacy = TemplateData.fromJson({
        'titleSize': 70.0,
        'subtitleSize': 32.0,
        'customTextItems': [
          {'id': 'txt_1', 'text': 'Hi', 'fontSize': 28.0},
        ],
      });
      expect(legacy.titleSize, closeTo(70.0 * DesignSpace.legacyTextScale, 1e-9));
      expect(legacy.subtitleSize, closeTo(32.0 * DesignSpace.legacyTextScale, 1e-9));
      expect(legacy.customTextItems.single.fontSize, closeTo(28.0 * DesignSpace.legacyTextScale, 1e-9));
    });

    test('current drafts keep font sizes as written', () {
      const data = TemplateData(titleSize: 120.0, subtitleSize: 48.0);
      final reloaded = TemplateData.fromJson(data.toJson());
      expect(reloaded.titleSize, 120.0);
      expect(reloaded.subtitleSize, 48.0);
    });

    test('device items round-trip through JSON', () {
      const item = CanvasDeviceItem(
        id: 'dev_x',
        frameStyle: DeviceFrameStyle.none,
        scale: 1.1,
        offsetX: 3,
        offsetY: 4,
        rotation: 5,
        hasShadow: false,
      );
      expect(CanvasDeviceItem.fromJson(item.toJson()), equals(item));
    });
  });
}

void _canvasUxTests() {
  group('Canvas UX: screens strip', () {
    late EditorViewModel vm;

    setUp(() {
      vm = EditorViewModel();
    });

    test('both stores are shown as rows by default and can be collapsed to the active one', () {
      expect(vm.showBothStores, isTrue);
      expect(vm.visibleStores, [TargetPlatformType.appStore, TargetPlatformType.googlePlay]);
      vm.setPlatform(TargetPlatformType.googlePlay);
      vm.setShowBothStores(false);
      expect(vm.visibleStores, [TargetPlatformType.googlePlay]);
    });

    test('screens can be named, and unnamed screens fall back to their number', () {
      expect(vm.screenNameAt(0), 'Screen 1');
      vm.setScreenName(0, '  Onboarding  ');
      expect(vm.screenNameAt(0), 'Onboarding');
      expect(vm.data.name, 'Onboarding');
      final reloaded = TemplateData.fromJson(vm.data.toJson());
      expect(reloaded.name, 'Onboarding');
    });

    test('moveScreenshot reorders and keeps the moved screen selected', () {
      final n = vm.screenshotsCount;
      vm.setScreenName(0, 'A');
      vm.setScreenName(1, 'B');
      vm.setScreenName(n - 1, 'C');

      vm.moveScreenshot(n - 1, 0);
      expect(vm.screenshots.take(3).map((s) => s.name).toList(), ['C', 'A', 'B']);
      expect(vm.selectedIndex, 0);

      vm.moveScreenshot(0, n + 5); // out of range: ignored
      expect(vm.screenshots.first.name, 'C');
    });

    test('addScreenshot inherits the look of the active screen but not its content', () {
      vm.setCustomBackgroundColor(const Color(0xFF123456));
      vm.setTitleFont('Sora');
      vm.setTitleText('Hello');
      final devId = vm.selectedDevice!.id;
      vm.setDeviceScreenshot(devId, TargetPlatformType.appStore, Uint8List.fromList([1, 2, 3]));

      vm.addScreenshot();
      final added = vm.data;
      expect(added.customBackgroundColor, const Color(0xFF123456));
      expect(added.titleFont, 'Sora');
      expect(added.titleText, isNot('Hello'));
      expect(added.effectiveDevices.any((d) => d.hasAnyScreenshot), isFalse);
      expect(added.effectiveDevices.any((d) => d.id == devId), isFalse);
    });

    test('applyStyleToAllScreens copies the look and keeps each screen\'s words and screenshots', () {
      vm.selectScreenshot(0);
      vm.setTitleText('First');
      vm.selectScreenshot(1);
      vm.setTitleText('Second');
      final secondDev = vm.selectedDevice!.id;
      final shot = Uint8List.fromList([9, 9]);
      vm.setDeviceScreenshot(secondDev, TargetPlatformType.googlePlay, shot);

      vm.selectScreenshot(0);
      vm.setTitleFont('Fraunces');
      vm.setTitleSize(150);
      vm.setLayoutMode(LayoutMode.angledLeftHero);
      vm.setGradientIndex(3);
      vm.setDeviceFrameStyle(vm.selectedDevice!.id, DeviceFrameStyle.minimalOutline);

      vm.applyStyleToAllScreens(0);

      final second = vm.screenshots[1];
      expect(second.titleText, 'Second');
      expect(second.titleFont, 'Fraunces');
      expect(second.titleSize, 150);
      expect(second.layoutMode, LayoutMode.angledLeftHero);
      expect(second.selectedGradientIndex, 3);
      expect(second.effectiveDevices.first.frameStyle, DeviceFrameStyle.minimalOutline);
      expect(second.effectiveDevices.first.rotation, -15.0);
      expect(second.effectiveDevices.first.screenshotFor(TargetPlatformType.googlePlay), same(shot));
    });
  });

  group('Canvas UX: element handles and shortcuts', () {
    late EditorViewModel vm;

    setUp(() {
      vm = EditorViewModel();
    });

    test('resizeElement scales frames and images and sizes text, within limits', () {
      final devId = vm.selectedDevice!.id;
      vm.resizeElement(0, devId, 1.2);
      expect(vm.selectedDevice!.scale, 1.2);
      vm.resizeElement(0, devId, 99);
      expect(vm.selectedDevice!.scale, ScaleLimits.deviceMax);

      vm.resizeElement(0, 'title', 120);
      expect(vm.titleSize, 120);
      vm.resizeElement(0, 'title', 1);
      expect(vm.titleSize, TextSizeLimits.titleMin);

      vm.addCustomTextElement();
      vm.resizeElement(0, vm.selectedTextId!, 64);
      expect(vm.customTextItems.single.fontSize, 64);

      vm.addCustomImageItem(Uint8List.fromList([1]));
      vm.resizeElement(0, vm.selectedImageId!, 0.01);
      expect(vm.selectedCustomImage!.scale, ScaleLimits.imageMin);
    });

    test('rotateElement normalises to -180..180 and ignores the headline', () {
      final devId = vm.selectedDevice!.id;
      vm.rotateElement(0, devId, 200);
      expect(vm.selectedDevice!.rotation, -160);
      vm.rotateElement(0, devId, -190);
      expect(vm.selectedDevice!.rotation, 170);
      vm.rotateElement(0, 'title', 45);
      expect(vm.selectedDevice!.rotation, 170);
    });

    test('nudgeSelected moves the selection by offset units', () {
      vm.selectElement('title');
      final start = vm.elementOffset('title')!;
      vm.nudgeSelected(3, -2);
      vm.nudgeSelected(1, 0);
      expect(vm.data.textOffsetX, start.dx + 4);
      expect(vm.data.textOffsetY, start.dy - 2);
      expect(vm.elementOffset('title'), start + const Offset(4, -2));
    });

    test('removeSelectedElement clears headlines, deletes extras and keeps the last frame', () {
      vm.selectElement('title');
      vm.removeSelectedElement();
      expect(vm.titleText, isEmpty);
      expect(vm.selectedElementId, isNull);

      vm.addCustomTextElement();
      vm.removeSelectedElement();
      expect(vm.customTextItems, isEmpty);

      vm.selectElement(vm.selectedDevice!.id);
      vm.removeSelectedElement();
      expect(vm.devices.length, 1);
    });

    test('duplicateElement copies frames, images and text next to the original', () {
      final devId = vm.selectedDevice!.id;
      final devCount = vm.devices.length;
      final devOffsetX = vm.selectedDevice!.offsetX;
      vm.duplicateElement(devId);
      expect(vm.devices.length, devCount + 1);
      expect(vm.selectedDeviceId, isNot(devId));
      expect(vm.devices.last.offsetX, devOffsetX + 40);

      vm.addCustomTextElement();
      final txtId = vm.selectedTextId!;
      vm.duplicateElement(txtId);
      expect(vm.customTextItems.length, 2);
      expect(vm.customTextItems.last.text, vm.customTextItems.first.text);

      vm.duplicateElement('title'); // headline is unique: no-op
      expect(vm.selectedElementId, vm.customTextItems.last.id);
    });

    test('requestTextFocus bumps a counter the inspector listens to', () {
      final before = vm.textFocusRequest;
      vm.requestTextFocus();
      expect(vm.textFocusRequest, before + 1);
    });
  });
}
