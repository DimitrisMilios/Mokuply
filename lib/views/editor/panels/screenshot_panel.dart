import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_device_item.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';

/// Uploads the iPhone and Android screenshots of the selected phone frame.
///
/// Layout is shared between stores, so this is the only place where the two
/// stores differ: each frame shows its iPhone image on the App Store and its
/// Android image on Google Play, falling back to the other while one is missing.
class ScreenshotPanel extends StatelessWidget {
  const ScreenshotPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final devices = vm.devices;
    final device = vm.selectedDevice;

    return SidebarCard(
      title: '1. App Screenshots',
      icon: Icons.upload_file_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Each phone frame holds one iPhone and one Android screenshot. Position, size and tilt are shared, '
            'so both stores stay identical.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          if (devices.length > 1) ...[
            _buildFrameChips(vm, devices, device),
            const SizedBox(height: AppDimensions.spacingSm),
          ],

          if (device != null) ...[
            _ScreenshotSlotTile(
              platform: TargetPlatformType.appStore,
              device: device,
              isPreviewing: vm.platform == TargetPlatformType.appStore,
              onUpload: () => vm.pickDeviceScreenshot(device.id, TargetPlatformType.appStore),
              onRemove: () => vm.setDeviceScreenshot(device.id, TargetPlatformType.appStore, null),
            ),
            const SizedBox(height: 12),
            _ScreenshotSlotTile(
              platform: TargetPlatformType.googlePlay,
              device: device,
              isPreviewing: vm.platform == TargetPlatformType.googlePlay,
              onUpload: () => vm.pickDeviceScreenshot(device.id, TargetPlatformType.googlePlay),
              onRemove: () => vm.setDeviceScreenshot(device.id, TargetPlatformType.googlePlay, null),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrameChips(EditorViewModel vm, List<CanvasDeviceItem> devices, CanvasDeviceItem? active) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: devices.asMap().entries.map((entry) {
        final isSelected = active?.id == entry.value.id;
        return ChoiceChip(
          label: Text('Frame #${entry.key + 1}'),
          selected: isSelected,
          onSelected: (_) => vm.selectDevice(entry.value.id),
          selectedColor: AppColors.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.glassBorder),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
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
    final bool isApple = platform == TargetPlatformType.appStore;

    final String status;
    if (hasOwn) {
      status = 'Shown on the ${platform.shortName}';
    } else if (usesFallback) {
      status = 'Using the ${platform.other.screenshotLabel} screenshot until you upload one';
    } else {
      status = 'Shown on the ${platform.shortName} · ${platform.deviceName}';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasOwn ? AppColors.primary.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: hasOwn ? AppColors.primary : AppColors.glassBorder,
          width: hasOwn ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApple ? Icons.phone_iphone_rounded : Icons.phone_android_rounded,
                size: 20,
                color: hasOwn ? AppColors.primary : AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${platform.screenshotLabel} Screenshot',
                  style: TextStyle(
                    color: hasOwn ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isPreviewing)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PREVIEWING',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (hasOwn)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16)
              else if (usesFallback)
                const Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted, size: 16),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            status,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasOwn ? AppColors.surface : AppColors.primary,
                    foregroundColor: hasOwn ? AppColors.textPrimary : AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: hasOwn ? const BorderSide(color: AppColors.glassBorder) : BorderSide.none,
                    ),
                  ),
                  icon: Icon(hasOwn ? Icons.sync_rounded : Icons.upload_rounded, size: 14),
                  label: Text(
                    hasOwn ? 'Replace Image' : 'Upload',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (hasOwn) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                  tooltip: 'Remove Screenshot',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
