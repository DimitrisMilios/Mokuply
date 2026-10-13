import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_device_item.dart';
import '../../../widgets/clay/clay.dart';

/// One chassis style. Always a clay slab; the selected one is the raised
/// mint puck.
class FrameStyleTile extends StatelessWidget {
  final DeviceFrameStyle style;
  final TargetPlatformType platform;
  final bool selected;
  final VoidCallback onTap;

  const FrameStyleTile({
    super.key,
    required this.style,
    required this.platform,
    required this.selected,
    required this.onTap,
  });

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
class ScreenshotSlotTile extends StatelessWidget {
  final TargetPlatformType platform;
  final CanvasDeviceItem device;
  final bool isPreviewing;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const ScreenshotSlotTile({
    super.key,
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
