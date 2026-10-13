import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Footer for HomeView: two lines of muted text, no border.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  // TODO(links): make this a real link once url_launcher is a dependency.
  // GitHub URL placeholder: https://github.com/<org>/mockuply
  static const String _sourceLabel = 'Source on GitHub';

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mockuply · free and client-side · MIT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            _sourceLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
