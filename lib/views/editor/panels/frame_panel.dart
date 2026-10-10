import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_device_item.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';
import '../../../widgets/shared/labeled_slider.dart';

class FramePanel extends StatelessWidget {
  const FramePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final deviceList = vm.devices;
    final activeDevice = vm.selectedDevice;

    return SidebarCard(
      title: '5. Phone Frames & Multi-Device',
      icon: Icons.phone_iphone_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add phone frames or edit the selected one. Realistic frames draw an iPhone on the App Store and a '
            'Galaxy on Google Play with the exact same footprint, so your layout never shifts.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // Add Extra Device Frame Button
          ElevatedButton.icon(
            onPressed: () => vm.addDeviceFrame(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size.fromHeight(38),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              '+ Add Extra Phone Frame',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          if (deviceList.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            const Text(
              'Canvas Phone Frames:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            // Device Frame Selector List
            Column(
              children: deviceList.asMap().entries.map((entry) {
                final int index = entry.key;
                final dev = entry.value;
                final isSelected = activeDevice?.id == dev.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.glassBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    dense: true,
                    leading: _buildModelIcon(dev.frameStyle, vm.platform, isSelected),
                    title: Text(
                      'Frame #${index + 1}: ${dev.frameStyle.labelFor(vm.platform)}',
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _screenshotStatus(dev),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    onTap: () => vm.selectDevice(dev.id),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => vm.pickDeviceScreenshot(dev.id, vm.platform),
                          icon: Icon(
                            dev.hasOwnScreenshotFor(vm.platform) ? Icons.sync_rounded : Icons.upload_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Upload ${vm.platform.screenshotLabel} screenshot to this frame',
                        ),
                        if (deviceList.length > 1)
                          IconButton(
                            onPressed: () => vm.removeDeviceFrame(dev.id),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                            tooltip: 'Remove Frame',
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (activeDevice != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            const Text(
              'Selected Frame Style:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppDimensions.fontBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),

            // Frame style tiles for the active device frame
            Column(
              children: DeviceFrameStyle.values.map((style) {
                final isSelected = activeDevice.frameStyle == style;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => vm.setDeviceFrameStyle(activeDevice.id, style),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.glassBorder,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildModelIcon(style, vm.platform, isSelected),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      style.label,
                                      style: TextStyle(
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (style == DeviceFrameStyle.realistic)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary : const Color(0xFF1E2025),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'AUTO PER STORE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  style.description,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppDimensions.spacingMd),
            LabeledSlider(
              label: 'Device Scale',
              valueText: '${(activeDevice.scale * 100).toInt()}%',
              value: activeDevice.scale,
              min: 0.3,
              max: 1.5,
              onChanged: (val) => vm.setDeviceFrameScale(activeDevice.id, val),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            LabeledSlider(
              label: 'Rotation Tilt',
              valueText: '${activeDevice.rotation.toInt()}°',
              value: activeDevice.rotation,
              min: -180.0,
              max: 180.0,
              onChanged: (val) => vm.setDeviceFrameRotation(activeDevice.id, val),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Drop Shadow',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
                ),
                value: activeDevice.hasShadow,
                activeTrackColor: AppColors.primary,
                activeThumbColor: Colors.white,
                onChanged: (val) => vm.setDeviceFrameShadow(activeDevice.id, val),
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.spacingSm),
          OutlinedButton.icon(
            onPressed: () => vm.resetCanvasOffsets(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.glassBorder),
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size.fromHeight(36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text(
              'Reset Canvas Positions',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _screenshotStatus(CanvasDeviceItem dev) {
    if (!dev.hasAnyScreenshot) return 'No screenshot yet';
    final ios = dev.hasOwnScreenshotFor(TargetPlatformType.appStore) ? '✓' : '–';
    final android = dev.hasOwnScreenshotFor(TargetPlatformType.googlePlay) ? '✓' : '–';
    return 'iPhone $ios · Android $android';
  }

  Widget _buildModelIcon(DeviceFrameStyle style, TargetPlatformType platform, bool isSelected) {
    switch (style) {
      case DeviceFrameStyle.realistic:
        return platform == TargetPlatformType.appStore ? _buildIphoneIcon(isSelected) : _buildGalaxyIcon(isSelected);

      case DeviceFrameStyle.minimalOutline:
        return Container(
          width: 28,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.textMuted, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.crop_portrait_rounded, size: 14, color: AppColors.textMuted),
          ),
        );

      case DeviceFrameStyle.none:
        return Container(
          width: 28,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Center(
            child: Icon(Icons.check_box_outline_blank_rounded, size: 12, color: AppColors.textMuted),
          ),
        );
    }
  }

  Widget _buildIphoneIcon(bool isSelected) {
    return Container(
      width: 28,
      height: 34,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : const Color(0xFF1F2024),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4A4E54), width: 1.5),
      ),
      child: Column(
        children: [
          const SizedBox(height: 2.5),
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalaxyIcon(bool isSelected) {
    return Container(
      width: 28,
      height: 34,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : const Color(0xFFD6CFC3),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF9E9484), width: 1.5),
      ),
      child: Column(
        children: [
          const SizedBox(height: 2.5),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
