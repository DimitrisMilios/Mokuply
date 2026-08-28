import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/project_template.dart';
import '../../services/file_service.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../../widgets/shared/ambient_background.dart';
import '../../widgets/shared/glass_container.dart';
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
                    _SavedDraftBanner(),
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

class _SavedDraftBanner extends StatelessWidget {
  const _SavedDraftBanner();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    if (!vm.hasSavedDraft) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        borderColor: AppColors.primary.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Saved Session Found in Local Storage',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'You have an in-progress mockup project saved in your browser.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => vm.discardSavedDraft(),
              child: const Text('Discard', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => vm.restoreSavedDraft(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Resume Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateStoreGrid extends StatelessWidget {
  const _TemplateStoreGrid();

  Future<void> _handleImportTemplate(BuildContext context) async {
    final vm = Provider.of<EditorViewModel>(context, listen: false);
    final fileContent = await FileService.pickTemplateFileContent();
    if (fileContent == null) return;

    final imported = await vm.importTemplateFromJson(fileContent);
    if (context.mounted) {
      if (imported != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "${imported.title}" loaded successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to parse template file. Please check format.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<EditorViewModel>(); // trigger rebuild when custom templates change
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
                  'Pre-configured sets designed for maximum conversion',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleImportTemplate(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  ),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('Import .mokuply Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
