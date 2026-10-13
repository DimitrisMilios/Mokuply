import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_device_item.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';

/// Everything about one phone frame: its two store screenshots, chassis
/// style, size, tilt and shadow.
class FrameInspector extends StatelessWidget {
  final String deviceId;

  const FrameInspector({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final device = vm.devices.where((d) => d.id == deviceId).firstOrNull;
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
        _ScreenshotSlotTile(
          platform: TargetPlatformType.appStore,
          device: device,
          isPreviewing: vm.platform == TargetPlatformType.appStore,
          onUpload: () => vm.pickDeviceScreenshot(device.id, TargetPlatformType.appStore),
          onRemove: () => vm.setDeviceScreenshot(device.id, TargetPlatformType.appStore, null),
        ),
        const SizedBox(height: 8),
        _ScreenshotSlotTile(
          platform: TargetPlatformType.googlePlay,
          device: device,
          isPreviewing: vm.platform == TargetPlatformType.googlePlay,
          onUpload: () => vm.pickDeviceScreenshot(device.id, TargetPlatformType.googlePlay),
          onRemove: () => vm.setDeviceScreenshot(device.id, TargetPlatformType.googlePlay, null),
        ),

        const SizedBox(height: AppDimensions.spacingXl),
        const ClayLabel('Frame style'),
        const SizedBox(height: 10),
        for (final style in DeviceFrameStyle.values)
          _StyleTile(
            style: style,
            platform: vm.platform,
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

        if (vm.devices.length > 1) ...[
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

/// One chassis style. Always a clay slab; the selected one is the raised
/// mint puck.
class _StyleTile extends StatelessWidget {
  final DeviceFrameStyle style;
  final TargetPlatformType platform;
  final bool selected;
  final VoidCallback onTap;

  const _StyleTile({required this.style, required this.platform, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = style == DeviceFrameStyle.realistic
        ? (platform == TargetPlatformType.appStore ? Icons.phone_iphone_rounded : Icons.phone_android_rounded)
        : (style == DeviceFrameStyle.minimalOutline ? Icons.crop_portrait_rounded : Icons.crop_free_rounded);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClayTile(
        selected: selected,
        idleColor: AppColors.clay,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.primaryDeep : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style == DeviceFrameStyle.realistic ? '${style.label} · ${style.labelFor(platform)}' : style.label,
                    style: TextStyle(
                      color: selected ? AppColors.primaryDeep : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    style.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.textSecondary : AppColors.textMuted,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One store's screenshot slot. Raised when it holds an image, flat
/// otherwise. A gold dot marks the store currently previewed on the canvas.
class _ScreenshotSlotTile extends StatelessWidget {
  final TargetPlatformType platform;
  final CanvasDeviceItem device;
  final bool isPreviewing;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _ScreenshotSlotTile({
    required this.platform,
    required this.device,
    required this.isPreviewing,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasOwn = device.hasOwnScreenshotFor(platform);
    final bool usesFallback = !hasOwn && device.hasOwnScreenshotFor(platform.other);
    final String status = hasOwn
        ? 'Shown on the ${platform.shortName}'
        : usesFallback
            ? 'Using the ${platform.other.screenshotLabel} image until you upload one'
            : '${platform.shortName} · ${platform.deviceName}';

    return ClayTile(
      selected: hasOwn,
      onTap: onUpload,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Icon(
            platform == TargetPlatformType.appStore ? Icons.phone_iphone_rounded : Icons.phone_android_rounded,
            size: 20,
            color: hasOwn ? AppColors.primaryDeep : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isPreviewing) ...[
                      Tooltip(
                        message: 'Previewing on the canvas',
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        platform.screenshotLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasOwn ? AppColors.primaryDeep : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasOwn ? AppColors.textSecondary : AppColors.textMuted,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ClayIconButton(
            icon: hasOwn ? Icons.sync_rounded : Icons.upload_rounded,
            tooltip: hasOwn ? 'Replace' : 'Upload',
            size: 32,
            iconSize: 16,
            flat: hasOwn,
            onPressed: onUpload,
          ),
          if (hasOwn) ...[
            const SizedBox(width: 2),
            ClayIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Remove',
              size: 32,
              iconSize: 16,
              flat: true,
              danger: true,
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
