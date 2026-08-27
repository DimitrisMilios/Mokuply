import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocuply/core/constants/store_specs.dart';
import 'package:mocuply/viewmodels/editor_viewmodel.dart';

void main() {
  group('EditorViewModel Multi-Device & Custom Image Unit Tests', () {
    late EditorViewModel vm;

    setUp(() {
      vm = EditorViewModel();
    });

    test('Initial state contains default single primary device frame', () {
      expect(vm.devices.length, equals(1));
      expect(vm.customImageItems.isEmpty, isTrue);
      expect(vm.selectedDevice, isNotNull);
    });

    test('addDeviceFrame adds a new device frame and updates selection', () {
      vm.addDeviceFrame(DeviceFrameStyle.samsungS26Ultra);
      expect(vm.devices.length, equals(2));
      expect(vm.selectedDevice?.frameStyle, equals(DeviceFrameStyle.samsungS26Ultra));
      expect(vm.selectedDeviceId, startsWith('dev_'));
    });

    test('removeDeviceFrame removes targeted device frame', () {
      vm.addDeviceFrame();
      expect(vm.devices.length, equals(2));
      final secondId = vm.selectedDeviceId!;

      vm.removeDeviceFrame(secondId);
      expect(vm.devices.length, equals(1));
    });

    test('setDeviceFrameScale updates scale of selected device', () {
      final devId = vm.selectedDevice!.id;
      vm.setDeviceFrameScale(devId, 0.95);
      expect(vm.selectedDevice?.scale, equals(0.95));
    });

    test('addCustomImageItem adds custom image and updates selection', () {
      final dummyBytes = Uint8List.fromList([0, 1, 2, 3]);
      vm.addCustomImageItem(dummyBytes);

      expect(vm.customImageItems.length, equals(1));
      expect(vm.selectedCustomImage?.imageBytes, equals(dummyBytes));
      expect(vm.selectedImageId, startsWith('img_'));
    });

    test('setCustomImageScale and rotation update selected custom image', () {
      final dummyBytes = Uint8List.fromList([0, 1, 2, 3]);
      vm.addCustomImageItem(dummyBytes);
      final imgId = vm.selectedImageId!;

      vm.setCustomImageScale(imgId, 1.5);
      vm.setCustomImageRotation(imgId, 45.0);

      expect(vm.selectedCustomImage?.scale, equals(1.5));
      expect(vm.selectedCustomImage?.rotation, equals(45.0));
    });

    test('removeCustomImageItem deletes target custom image', () {
      final dummyBytes = Uint8List.fromList([0, 1, 2, 3]);
      vm.addCustomImageItem(dummyBytes);
      final imgId = vm.selectedImageId!;

      vm.removeCustomImageItem(imgId);
      expect(vm.customImageItems.isEmpty, isTrue);
    });

    test('DeviceFrameStyle filters frames per target store platform', () {
      final appleFrames = DeviceFrameStyle.availableForPlatform(TargetPlatformType.appStore);
      expect(appleFrames.contains(DeviceFrameStyle.iphone16ProMax), isTrue);
      expect(appleFrames.contains(DeviceFrameStyle.samsungS26Ultra), isFalse);

      final googleFrames = DeviceFrameStyle.availableForPlatform(TargetPlatformType.googlePlay);
      expect(googleFrames.contains(DeviceFrameStyle.samsungS26Ultra), isTrue);
      expect(googleFrames.contains(DeviceFrameStyle.iphone16ProMax), isFalse);
    });

    test('setPlatform updates device frame models cleanly', () {
      expect(vm.selectedDevice?.frameStyle, equals(DeviceFrameStyle.iphone16ProMax));

      vm.setPlatform(TargetPlatformType.googlePlay);
      expect(vm.selectedDevice?.frameStyle, equals(DeviceFrameStyle.samsungS26Ultra));

      vm.setPlatform(TargetPlatformType.appStore);
      expect(vm.selectedDevice?.frameStyle, equals(DeviceFrameStyle.iphone16ProMax));
    });
  });
}
