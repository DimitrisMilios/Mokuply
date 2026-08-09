import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Standalone footer component for HomeView.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'Mocuply Studio © 2026 — 100% Free & Client-Side',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          Text(
            'Built with Flutter Web',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
