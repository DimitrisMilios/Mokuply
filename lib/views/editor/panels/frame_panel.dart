import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';
import '../../../widgets/shared/labeled_slider.dart';

class FramePanel extends StatelessWidget {
  const FramePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);

    return SidebarCard(
      title: '5. Frame & Transform',
      icon: Icons.phone_iphone_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Model Frame:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // Visual Model Selector Tiles
          Column(
            children: DeviceFrameStyle.values.map((style) {
              final isSelected = vm.frameStyle == style;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => vm.setFrameStyle(style),
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
                        // Device Model Graphic Icon
                        _buildModelIcon(style, isSelected),
                        const SizedBox(width: 12),

                        // Title & Subtitle Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    style.name,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (style == DeviceFrameStyle.iphone16ProMax || style == DeviceFrameStyle.samsungS26Ultra)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : const Color(0xFF1E2025),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'REALISTIC',
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

                        // Selected indicator
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
            valueText: '${(vm.deviceScale * 100).toInt()}%',
            value: vm.deviceScale,
            min: 0.5,
            max: 1.2,
            onChanged: (val) => vm.setDeviceScale(val),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          LabeledSlider(
            label: 'Rotation Tilt',
            valueText: '${vm.deviceRotation.toInt()}°',
            value: vm.deviceRotation,
            min: -30.0,
            max: 30.0,
            onChanged: (val) => vm.setDeviceRotation(val),
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
              value: vm.hasShadow,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) => vm.setHasShadow(val),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          // Reset drag positions button
          OutlinedButton.icon(
            onPressed: () => vm.resetCanvasOffsets(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.glassBorder),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text(
              'Reset Drag Positions',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelIcon(DeviceFrameStyle style, bool isSelected) {
    Color iconBg = isSelected ? AppColors.primary : const Color(0xFF1F2024);
    switch (style) {
      case DeviceFrameStyle.iphone16ProMax:
        return Container(
          width: 32,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4A4E54), width: 1.5),
          ),
          child: Column(
            children: [
              const SizedBox(height: 3),
              // Pill notch preview
              Container(
                width: 12,
                height: 3.5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );

      case DeviceFrameStyle.samsungS26Ultra:
        return Container(
          width: 32,
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFD6CFC3),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF9E9484), width: 1.5),
          ),
          child: Column(
            children: [
              const SizedBox(height: 3),
              // Hole punch preview
              Container(
                width: 3.5,
                height: 3.5,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );

      case DeviceFrameStyle.minimalOutline:
        return Container(
          width: 32,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.textMuted, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.crop_portrait_rounded, size: 16, color: AppColors.textMuted),
          ),
        );

      case DeviceFrameStyle.none:
        return Container(
          width: 32,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Center(
            child: Icon(Icons.check_box_outline_blank_rounded, size: 14, color: AppColors.textMuted),
          ),
        );
    }
  }
}

