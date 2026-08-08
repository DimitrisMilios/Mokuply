import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/project_template.dart';
import '../../widgets/shared/ambient_background.dart';
import 'widgets/home_navbar.dart';
import 'widgets/hero_section.dart';
import 'widgets/template_card.dart';
import 'widgets/home_footer.dart';

/// HomeView with sticky floating glass navbar overlay over scrollable store content.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: Stack(
          children: [
            // 1. Main Scrollable Page Content (Passes underneath floating navbar)
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: 110, left: 32, right: 32, bottom: 24),
                child: Column(
                  children: [
                    HeroSection(),
                    SizedBox(height: 48),
                    _TemplateStoreGrid(),
                    SizedBox(height: 60),
                    HomeFooter(),
                  ],
                ),
              ),
            ),

            // 2. Sticky Floating Glass Header Navbar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HomeNavbar(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateStoreGrid extends StatelessWidget {
  const _TemplateStoreGrid();

  @override
  Widget build(BuildContext context) {
    final templates = ProjectTemplate.allTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Starter Mockup Templates',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pre-configured 6-screenshot sets designed for maximum conversion',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Free E-Shop Store',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 900;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.9,
              ),
              itemCount: templates.length,
              itemBuilder: (ctx, index) {
                return TemplateCard(template: templates[index]);
              },
            );
          },
        ),
      ],
    );
  }
}
