import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_device_item.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'frame_inspector_tiles.dart';

/// Everything about one phone frame: its two store screenshots, chassis
/// style, size, tilt and shadow.
class FrameInspector extends StatelessWidget {
  final String deviceId;

  const FrameInspector({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final (device, platform, frameCount) = context.select<EditorViewModel, (CanvasDeviceItem?, TargetPlatformType, int)>(
      (vm) => (vm.devices.where((d) => d.id == deviceId).firstOrNull, vm.platform, vm.devices.length),
    );
    final vm = context.read<EditorViewModel>();
    if (device == null) {
      return const Text('This frame no longer exists.', style: TextStyle(color: AppColors.textMuted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClayLabel('Screenshots'),
        const SizedBox(height: 4),
        const Text(
          'One image per store. Position and size are shared.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 10),
        ScreenshotSlotTile(
          platform: TargetPlatformType.appStore,
          device: device,
          isPreviewing: platform == TargetPlatformType.appStore,
          onUpload: () => vm.pickDeviceScreenshot(device.id, TargetPlatformType.appStore),
          onRemove: () => vm.setDeviceScreenshot(device.id, TargetPlatformType.appStore, null),
        ),
        const SizedBox(height: 8),
        ScreenshotSlotTile(
          platform: TargetPlatformType.googlePlay,
          device: device,
          isPreviewing: platform == TargetPlatformType.googlePlay,
          onUpload: () => vm.pickDeviceScreenshot(device.id, TargetPlatformType.googlePlay),
          onRemove: () => vm.setDeviceScreenshot(device.id, TargetPlatformType.googlePlay, null),
        ),

        const SizedBox(height: AppDimensions.spacingXl),
        const ClayLabel('Frame style'),
        const SizedBox(height: 10),
        for (final style in DeviceFrameStyle.values)
          FrameStyleTile(
            style: style,
            platform: platform,
            selected: device.frameStyle == style,
            onTap: () => vm.setDeviceFrameStyle(device.id, style),
          ),

        const SizedBox(height: AppDimensions.spacingLg),
        const ClayLabel('Size and tilt'),
        const SizedBox(height: 8),
        ClaySlider(
          label: 'Scale',
          valueText: '${(device.scale * 100).toInt()}%',
          value: device.scale.clamp(ScaleLimits.deviceMin, ScaleLimits.deviceMax),
          min: ScaleLimits.deviceMin,
          max: ScaleLimits.deviceMax,
          onChanged: (v) => vm.setDeviceFrameScale(device.id, v),
        ),
        const SizedBox(height: 8),
        ClaySlider(
          label: 'Rotation',
          valueText: '${device.rotation.toInt()}°',
          value: device.rotation,
          min: -180.0,
          max: 180.0,
          onChanged: (v) => vm.setDeviceFrameRotation(device.id, v),
        ),
        const SizedBox(height: 10),
        ClayToggle(
          label: 'Shadow',
          value: device.hasShadow,
          onChanged: (v) => vm.setDeviceFrameShadow(device.id, v),
        ),
        const SizedBox(height: 10),
        const Text(
          'Drag to move, corners to resize, top handle to rotate.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),

        if (frameCount > 1) ...[
          const SizedBox(height: 10),
          ClayButton.text(
            label: 'Remove this frame',
            icon: Icons.delete_outline_rounded,
            danger: true,
            expand: true,
            onPressed: () => vm.removeDeviceFrame(device.id),
          ),
        ],
      ],
    );
  }
}
