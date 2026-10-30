import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_links.dart';
import '../../../services/link_opener.dart';
import '../../../widgets/clay/clay.dart';

/// Footer for HomeView: a line of muted text over a row of flat links
/// (GitHub, AI setup, privacy, terms). No border.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    void push(String route) => Navigator.of(context).pushNamed(route);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Mockuply · free and client-side · MIT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: [
              _FooterLink(
                label: 'Source on GitHub',
                icon: Icons.code_rounded,
                onPressed: () => LinkOpener.open(AppLinks.repo),
              ),
              _FooterLink(
                label: 'Connect AI (MCP)',
                icon: Icons.smart_toy_rounded,
                onPressed: () => push(AppLinks.connectAiRoute),
              ),
              _FooterLink(
                label: 'Privacy Policy',
                icon: Icons.shield_outlined,
                onPressed: () => push(AppLinks.privacyRoute),
              ),
              _FooterLink(
                label: 'Terms of Use',
                icon: Icons.description_outlined,
                onPressed: () => push(AppLinks.termsRoute),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _FooterLink({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClayButton.text(
      label: label,
      icon: icon,
      size: ClayButtonSize.compact,
      color: AppColors.textMuted,
      onPressed: onPressed,
    );
  }
}
