import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_device_item.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/labeled_slider.dart';

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
        _SectionTitle('Screenshots', Icons.image_rounded),
        const SizedBox(height: 4),
        const Text(
          'One image per store. Position and size are shared, so both stores stay identical.',
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

        const SizedBox(height: AppDimensions.spacingLg),
        _SectionTitle('Frame style', Icons.smartphone_rounded),
        const SizedBox(height: 8),
        for (final style in DeviceFrameStyle.values)
          _StyleTile(
            style: style,
            platform: vm.platform,
            selected: device.frameStyle == style,
            onTap: () => vm.setDeviceFrameStyle(device.id, style),
          ),

        const SizedBox(height: AppDimensions.spacingMd),
        _SectionTitle('Size & tilt', Icons.open_with_rounded),
        const SizedBox(height: 4),
        LabeledSlider(
          label: 'Scale',
          valueText: '${(device.scale * 100).toInt()}%',
          value: device.scale.clamp(0.3, 1.6),
          min: 0.3,
          max: 1.6,
          onChanged: (v) => vm.setDeviceFrameScale(device.id, v),
        ),
        const SizedBox(height: 8),
        LabeledSlider(
          label: 'Rotation',
          valueText: '${device.rotation.toInt()}°',
          value: device.rotation,
          min: -180.0,
          max: 180.0,
          onChanged: (v) => vm.setDeviceFrameRotation(device.id, v),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Drop shadow',
            style: TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
          ),
          value: device.hasShadow,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
          onChanged: (v) => vm.setDeviceFrameShadow(device.id, v),
        ),
        const SizedBox(height: 4),
        const Text(
          'Drag the phone on the canvas to move it.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),

        if (vm.devices.length > 1) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => vm.removeDeviceFrame(device.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Remove this frame', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionTitle(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  final DeviceFrameStyle style;
  final TargetPlatformType platform;
  final bool selected;
  final VoidCallback onTap;

  const _StyleTile({required this.style, required this.platform, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: selected ? AppColors.primary : AppColors.glassBorder, width: selected ? 1.8 : 1.0),
          ),
          child: Row(
            children: [
              Icon(
                style == DeviceFrameStyle.realistic
                    ? (platform == TargetPlatformType.appStore ? Icons.phone_iphone_rounded : Icons.phone_android_rounded)
                    : (style == DeviceFrameStyle.minimalOutline ? Icons.crop_portrait_rounded : Icons.crop_free_rounded),
                size: 22,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style == DeviceFrameStyle.realistic ? '${style.label} · ${style.labelFor(platform)}' : style.label,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      style.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.2),
                    ),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

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

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasOwn ? AppColors.primary.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: hasOwn ? AppColors.primary : AppColors.glassBorder, width: hasOwn ? 1.5 : 1.0),
      ),
      child: Row(
        children: [
          Icon(
            platform == TargetPlatformType.appStore ? Icons.phone_iphone_rounded : Icons.phone_android_rounded,
            size: 20,
            color: hasOwn ? AppColors.primary : AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      platform.screenshotLabel,
                      style: TextStyle(
                        color: hasOwn ? AppColors.primary : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPreviewing) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.badgeBg, borderRadius: BorderRadius.circular(4)),
                        child: const Text(
                          'PREVIEWING',
                          style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(status, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onUpload,
            tooltip: hasOwn ? 'Replace' : 'Upload',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: hasOwn ? Colors.transparent : AppColors.primary,
              foregroundColor: hasOwn ? AppColors.primary : AppColors.textOnPrimary,
            ),
            icon: Icon(hasOwn ? Icons.sync_rounded : Icons.upload_rounded, size: 16),
          ),
          if (hasOwn)
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
            ),
        ],
      ),
    );
  }
}
