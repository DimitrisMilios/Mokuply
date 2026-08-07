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
          const Text('Device Model:', style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimensions.fontBody)),
          const SizedBox(height: AppDimensions.spacingSm),
          DropdownButtonFormField<DeviceFrameStyle>(
            initialValue: vm.frameStyle,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: DeviceFrameStyle.values
                .map((style) => DropdownMenuItem(
                      value: style,
                      child: Text(style.name),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) vm.setFrameStyle(val);
            },
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Drop Shadow', style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimensions.fontBody)),
            value: vm.hasShadow,
            activeTrackColor: AppColors.primary,
            onChanged: (val) => vm.setHasShadow(val),
          ),
        ],
      ),
    );
  }
}
