import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/store_specs.dart';
import '../../models/project_template.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../../widgets/shared/glass_container.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient glowing reflections for frosted glass
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 600,
              height: 600,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbCream,
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbJungle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: 200,
            child: Container(
              width: 550,
              height: 550,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbSage,
              ),
            ),
          ),

          // Main Scrollable Home View Content
          Column(
            children: [
              _buildHeader(context, vm),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    children: [
                      _buildHeroSection(context, vm),
                      const SizedBox(height: 48),
                      _buildTemplateStoreSection(context, vm),
                      const SizedBox(height: 60),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EditorViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        height: AppDimensions.navbarHeight,
        opacity: 0.75,
        borderRadius: BorderRadius.circular(AppDimensions.radiusGlassLg),
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.art_track_rounded, color: AppColors.textOnPrimary, size: 22),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                const Text(
                  'Mocuply',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '100% Free & Client-Side',
                    style: TextStyle(color: AppColors.primary, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => vm.openEditorWithNewProject(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                elevation: 3,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text(
                'Start Project',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontMd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, EditorViewModel vm) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'MOKUPLY STUDIO • APPS STORE & GOOGLE PLAY MOCKUP CREATOR',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppDimensions.fontSm,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Create Store Screenshots\nin Seconds',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: const Text(
            'Generate high-resolution 6.9" & 6.8" mockup sets for Apple App Store and Google Play Store directly in your browser.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Prominent Middle Glass CTA Card ("Do you want to start a project?")
        GlassContainer(
          width: 540,
          opacity: 0.8,
          borderRadius: BorderRadius.circular(28),
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Text(
                'Do you want to start a project?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pick a template or start with a 6-screenshot set ready for export.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => vm.openEditorWithNewProject(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                label: const Text(
                  "Let's Start",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateStoreSection(BuildContext context, EditorViewModel vm) {
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

        // Template Cards Grid
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
                final template = templates[index];
                return _buildTemplateCard(context, vm, template);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTemplateCard(BuildContext context, EditorViewModel vm, ProjectTemplate template) {
    return GlassContainer(
      opacity: 0.7,
      borderRadius: BorderRadius.circular(24),
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Thumbnail Bar (Showing 6 mini screenshots mockup strip)
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: template.previewGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: List.generate(6, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 44,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 28,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${template.initialScreenshots.length} Screenshots',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  template.category,
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Icon(
                template.platform == TargetPlatformType.googlePlay ? Icons.android : Icons.apple,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            template.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => vm.openEditorWithTemplate(template),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Use Template', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
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
