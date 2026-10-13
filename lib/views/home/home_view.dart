import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/project_template.dart';
import '../../services/file_service.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/ambient_background.dart';
import 'widgets/home_navbar.dart';
import 'widgets/hero_section.dart';
import 'widgets/template_card.dart';
import 'widgets/home_footer.dart';

/// HomeView: a sticky floating clay navbar over the scrollable page (draft
/// banner, hero, template grid, footer). Content assembles on entry: the
/// navbar slides down and fades, the sections rise in one after another.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const double _topPadding = 110;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _gridKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToTemplates() {
    final ctx = _gridKey.currentContext;
    if (ctx == null || !_scroll.hasClients) return;
    final box = ctx.findRenderObject();
    final scrollable = Scrollable.of(ctx).context.findRenderObject();
    if (box is! RenderBox || scrollable is! RenderBox) return;
    final top = box.localToGlobal(Offset.zero, ancestor: scrollable).dy;
    final target = (_scroll.offset + top - _topPadding + 24).clamp(0.0, _scroll.position.maxScrollExtent);
    final motion = ClayMotion.of(context);
    if (!motion.enabled) {
      _scroll.jumpTo(target);
      return;
    }
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: ClaySpringCurve.gentle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: AmbientBackground(
        child: Stack(
          children: [
            // 1. Scrollable page content (passes underneath the floating navbar).
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.only(top: _topPadding, left: 32, right: 32, bottom: 24),
                child: Column(
                  children: [
                    const ClayStagger(index: 0, child: _SavedDraftBanner()),
                    ClayStagger(index: 1, child: HeroSection(onBrowseTemplates: _scrollToTemplates)),
                    const SizedBox(height: 48),
                    ClayStagger(index: 2, child: _TemplateStoreGrid(key: _gridKey)),
                    const SizedBox(height: 60),
                    const ClayStagger(index: 3, child: HomeFooter()),
                  ],
                ),
              ),
            ),

            // 2. Sticky floating clay navbar.
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _NavbarEntrance(child: HomeNavbar()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slides the navbar down 16 px and fades it in with the gentle spring.
class _NavbarEntrance extends StatefulWidget {
  final Widget child;

  const _NavbarEntrance({required this.child});

  @override
  State<_NavbarEntrance> createState() => _NavbarEntranceState();
}

class _NavbarEntranceState extends State<_NavbarEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = ClayMotion.of(context);
    if (!motion.enabled) {
      _c.value = 1;
      return;
    }
    _c.springTo(1, spring: motion.gentle);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, -16 * (1 - t)), child: child),
        );
      },
    );
  }
}

class _SavedDraftBanner extends StatelessWidget {
  const _SavedDraftBanner();

  static const String _iconAsset = 'assets/clay/icon_history.png';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    if (!vm.hasSavedDraft) return const SizedBox.shrink();

    final Widget iconTile = Image.asset(
      _iconAsset,
      width: 40,
      height: 40,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const ClayContainer(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: ClayDecoration.gold(radius: 14, depth: 4, lift: 8),
        child: Icon(Icons.history_rounded, color: AppColors.textPrimary, size: 22),
      ),
    );

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'You have an unfinished project',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontLg,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'It is saved in this browser.',
          style: TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w600),
        ),
      ],
    );

    final List<Widget> actions = [
      ClayButton.text(label: 'Discard', onPressed: () => vm.discardSavedDraft()),
      const SizedBox(width: 8),
      ClayButton.primary(
        label: 'Resume',
        icon: Icons.play_arrow_rounded,
        onPressed: () => vm.restoreSavedDraft(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ClayPanel(
        radius: AppDimensions.radiusClayLg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 560;
            if (wide) {
              return Row(
                children: [
                  iconTile,
                  const SizedBox(width: 14),
                  Expanded(child: text),
                  const SizedBox(width: 12),
                  ...actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconTile,
                    const SizedBox(width: 14),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TemplateStoreGrid extends StatelessWidget {
  const _TemplateStoreGrid({super.key});

  Future<void> _handleImportTemplate(BuildContext context) async {
    final vm = Provider.of<EditorViewModel>(context, listen: false);
    final fileContent = await FileService.pickTemplateFileContent();
    if (fileContent == null) return;

    final imported = await vm.importTemplateFromJson(fileContent);
    if (!context.mounted) return;
    if (imported != null) {
      ClayToast.show(context, 'Loaded "${imported.title}".');
    } else {
      ClayToast.show(context, 'That file could not be read as a template.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<EditorViewModel>(); // rebuild when custom templates change
    final templates = ProjectTemplate.allTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (ctx, constraints) {
            final bool wide = constraints.maxWidth >= 760;
            const Widget title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Templates',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start from a layout and change anything.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontMd, fontWeight: FontWeight.w500),
                ),
              ],
            );
            final Widget actions = ClayButton.neutral(
              label: 'Import .mokuply template',
              icon: Icons.file_upload_outlined,
              onPressed: () => _handleImportTemplate(context),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(child: title),
                  const SizedBox(width: 24),
                  actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), actions],
            );
          },
        ),
        const SizedBox(height: 24),
        if (templates.isEmpty)
          const _EmptyGallery()
        else
          LayoutBuilder(
            builder: (ctx, constraints) {
              final double width = constraints.maxWidth;
              final int columns = width > 1100 ? 3 : (width > 640 ? 2 : 1);
              // Cards hold a fixed-height preview plus text, so keep their
              // height close to constant instead of scaling with the width.
              final double columnWidth = (width - 20 * (columns - 1)) / columns;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: columnWidth / 420,
                ),
                itemCount: templates.length,
                itemBuilder: (ctx, index) {
                  // Cards stagger after the section header; capped so the
                  // whole entrance stays short on long galleries.
                  return ClayStagger(
                    index: 1 + (index < 6 ? index : 6),
                    child: TemplateCard(template: templates[index]),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

/// Shown when there is nothing in the gallery.
class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  static const String _asset = 'assets/clay/empty_gallery.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Image.asset(
            _asset,
            width: 240,
            height: 240,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const ClayWell(
              width: 240,
              height: 240,
              radius: AppDimensions.radiusClayLg,
              alignment: Alignment.center,
              child: Icon(Icons.auto_awesome_mosaic_outlined, size: 64, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No templates yet. Import one, or start a project from scratch.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontMd, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
