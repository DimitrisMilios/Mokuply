import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/ambient_background.dart';
import '../editor_loader.dart';
import 'widgets/home_navbar.dart';
import 'widgets/hero_section.dart';
import 'widgets/home_footer.dart';
import 'widgets/navbar_entrance.dart';
import 'widgets/saved_draft_banner.dart';
import 'widgets/template_gallery.dart';

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
  void initState() {
    super.initState();
    // Fetch the editor bundle once the page is up and its images have had a
    // head start, so "Start a project" opens instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 600), EditorLoader.preload);
    });
  }

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
                    const ClayStagger(index: 0, child: SavedDraftBanner()),
                    ClayStagger(index: 1, child: HeroSection(onBrowseTemplates: _scrollToTemplates)),
                    const SizedBox(height: 48),
                    ClayStagger(index: 2, child: TemplateGallery(key: _gridKey)),
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
              child: NavbarEntrance(child: HomeNavbar()),
            ),
          ],
        ),
      ),
    );
  }
}

