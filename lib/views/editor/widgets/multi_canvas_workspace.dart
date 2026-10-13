import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/canvas/canvas_mockup_widget.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/canvas_grid_painter.dart';

/// Centre workspace: the screens of the project laid out as one continuous
/// store strip, with a named tab above each screen and one live row per
/// store (App Store on top, Google Play below). Pan and zoom like Figma.
class MultiCanvasWorkspace extends StatefulWidget {
  final TransformationController transformationController;

  /// Preview mode: no tabs' menus, no selection chrome, nothing draggable.
  final bool previewing;

  const MultiCanvasWorkspace({super.key, required this.transformationController, this.previewing = false});

  /// All cards share one height, so the shared design renders at the same
  /// scale on both stores; only the card width follows the store.
  static const double previewHeight = 620.0;
  static const double cardGap = 4.0;

  /// Height of the tab pill, and of the gold underline bar that sits below it.
  static const double tabPillHeight = 32.0;
  static const double underlineHeight = 4.0;
  static const double tabsHeight = tabPillHeight + 4 + underlineHeight;
  static const double rowHeaderHeight = 36.0;
  static const double rowSpacing = 28.0;
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 160, vertical: 120);

  static double cardWidthFor(TargetPlatformType store) => previewHeight * store.aspectRatio;

  /// Size of the whole strip (including padding) for the current project,
  /// used to fit the view to the content.
  static Size contentSize(EditorViewModel vm) {
    final rows = vm.visibleStores;
    double width = 0;
    for (final store in rows) {
      width = width > vm.screenshotsCount * (cardWidthFor(store) + cardGap)
          ? width
          : vm.screenshotsCount * (cardWidthFor(store) + cardGap);
    }
    width += 56 + cardGap; // "add screen" button at the end of the tabs row
    final double height =
        tabsHeight + 10 + rows.length * (rowHeaderHeight + 8 + previewHeight) + (rows.length - 1) * rowSpacing;
    return Size(width + contentPadding.horizontal, height + contentPadding.vertical);
  }

  @override
  State<MultiCanvasWorkspace> createState() => _MultiCanvasWorkspaceState();
}

class _MultiCanvasWorkspaceState extends State<MultiCanvasWorkspace> {
  /// How long a deleted screen takes to fade and collapse before the view
  /// model actually removes it.
  static const Duration _leaveDuration = Duration(milliseconds: 420);

  /// Spring shape used when the OS asks for reduced motion (no overshoot).
  static final Curve _stillCurve = ClaySpringCurve(ClaySprings.still);

  int _lastCount = -1;

  /// Index of the screen that was just added (grows in, tab wobbles once).
  int? _enterIndex;

  /// Index of the screen that is fading out before removal.
  int? _leavingIndex;

  /// Per-index key generation. Bumped when a fresh slot must be created at an
  /// index (a new screen entering, or the neighbour shifting into a deleted
  /// slot) so slot state never leaks between screens.
  int _generation = 0;
  final Map<int, int> _slotGeneration = {};

  Key _slotKey(String kind, int index) => ValueKey('${kind}_${index}_${_slotGeneration[index] ?? 0}');

  void _trackCount(EditorViewModel vm) {
    final count = vm.screenshotsCount;
    if (_lastCount >= 0 && count > _lastCount && _leavingIndex == null) {
      // Add and duplicate both select the new screen.
      _enterIndex = vm.selectedIndex;
      _slotGeneration[vm.selectedIndex] = ++_generation;
    } else if (count < _lastCount) {
      _enterIndex = null;
    }
    _lastCount = count;
  }

  /// Fades and collapses the card and tab, then asks the view model to
  /// remove the screen. The remove call itself is unchanged.
  Future<void> _deleteScreen(EditorViewModel vm, int index) async {
    if (_leavingIndex != null) return;
    if (!ClayMotion.of(context).enabled) {
      vm.removeScreenshot(index);
      return;
    }
    setState(() {
      _leavingIndex = index;
      _enterIndex = null;
    });
    await Future<void>.delayed(_leaveDuration);
    if (!mounted) return;
    setState(() {
      _leavingIndex = null;
      // The screen that shifts into this index gets a fresh, full-width slot.
      _slotGeneration[index] = ++_generation;
    });
    vm.removeScreenshot(index);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    _trackCount(vm);
    final rows = vm.visibleStores;
    final previewing = widget.previewing;
    final motion = ClayMotion.of(context);
    final Curve liftCurve = motion.enabled ? ClaySpringCurve.bouncy : _stillCurve;

    return Container(
      color: AppColors.sandDeep,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: CanvasGridPainter())),
          Positioned.fill(
            child: CanvasViewportZoom(
              controller: widget.transformationController,
              child: InteractiveViewer(
                transformationController: widget.transformationController,
                minScale: 0.15,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.symmetric(horizontal: 900, vertical: 700),
                constrained: false,
                panEnabled: true,
                scaleEnabled: true,
                child: Padding(
                  padding: MultiCanvasWorkspace.contentPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScreenTabsRow(
                        vm: vm,
                        previewing: previewing,
                        cardWidth: MultiCanvasWorkspace.cardWidthFor(rows.first),
                        enterIndex: _enterIndex,
                        leavingIndex: _leavingIndex,
                        keyFor: _slotKey,
                        onDelete: (i) => _deleteScreen(vm, i),
                      ),
                      const SizedBox(height: 10),
                      for (final (r, store) in rows.indexed) ...[
                        if (r > 0) const SizedBox(height: MultiCanvasWorkspace.rowSpacing),
                        _StoreRowHeader(
                          store: store,
                          active: vm.platform == store,
                          showBoth: vm.showBothStores,
                          previewing: previewing,
                          onTap: () => vm.setPlatform(store),
                          onToggleBoth: () => vm.setShowBothStores(!vm.showBothStores),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(vm.screenshotsCount, (index) {
                            final itemData = vm.screenshots[index].copyWith(platform: store);
                            final isSelected = vm.selectedIndex == index && !previewing;
                            final double width = MultiCanvasWorkspace.cardWidthFor(store);

                            return _ScreenSlot(
                              key: _slotKey('card_${store.name}', index),
                              width: width + MultiCanvasWorkspace.cardGap,
                              enter: index == _enterIndex,
                              leaving: index == _leavingIndex,
                              child: Listener(
                                onPointerDown: (_) {
                                  if (previewing) return;
                                  if (!isSelected) vm.selectScreenshot(index);
                                  if (vm.platform != store) vm.setPlatform(store);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: liftCurve,
                                  // 2px per side = 4px between neighbouring screens, so the strip
                                  // reads as one continuous store listing.
                                  margin: const EdgeInsets.symmetric(horizontal: MultiCanvasWorkspace.cardGap / 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                                    // No border: the selected card floats higher instead.
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.clayShadow.withValues(alpha: isSelected ? 0.24 : 0.12),
                                        blurRadius: isSelected ? 40 : 20,
                                        offset: Offset(0, isSelected ? 20 : 12),
                                      ),
                                    ],
                                  ),
                                  // Each screen repaints on its own, so dragging on one
                                  // card never re-rasterises the others.
                                  child: RepaintBoundary(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                                      child: CanvasMockupWidget(
                                        data: itemData,
                                        itemIndex: index,
                                        canvasSize: Size(width, MultiCanvasWorkspace.previewHeight),
                                        interactive: !previewing,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One slot of the strip (a tab or a card). A new slot grows in from width 0
/// with a bounce; a leaving slot fades, shrinks to 0.9 and collapses so its
/// neighbours close the gap gently.
class _ScreenSlot extends StatefulWidget {
  final double width;
  final bool enter;
  final bool leaving;
  final Widget child;

  const _ScreenSlot({super.key, required this.width, required this.enter, required this.leaving, required this.child});

  @override
  State<_ScreenSlot> createState() => _ScreenSlotState();
}

class _ScreenSlotState extends State<_ScreenSlot> {
  late bool _grown = !widget.enter;

  @override
  void initState() {
    super.initState();
    if (widget.enter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _grown = true);
      });
    }
  }

  static final Curve _stillCurve = ClaySpringCurve(ClaySprings.still, settleDuration: const Duration(milliseconds: 450));

  @override
  Widget build(BuildContext context) {
    final motion = ClayMotion.of(context);
    final bool collapsed = widget.leaving || !_grown;
    final Curve sizeCurve = !motion.enabled
        ? _stillCurve
        : widget.leaving
            ? ClaySpringCurve.gentle
            : ClaySpringCurve.bouncy;
    return AnimatedSize(
      duration: const Duration(milliseconds: 450),
      curve: sizeCurve,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: collapsed ? 0 : widget.width,
        child: OverflowBox(
          minWidth: widget.width,
          maxWidth: widget.width,
          fit: OverflowBoxFit.deferToChild,
          alignment: Alignment.centerLeft,
          // Pure crossfade on the way out (and hidden on the width-0 frame a
          // new slot starts on), so an eased curve is fine here.
          child: AnimatedOpacity(
            opacity: collapsed ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: widget.leaving ? 0.9 : 1,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Named tab above each screen (double-click to rename, menu for more), the
/// gold underline that slides to the selected tab, and an "add screen"
/// button at the end of the strip.
class _ScreenTabsRow extends StatelessWidget {
  final EditorViewModel vm;
  final bool previewing;
  final double cardWidth;
  final int? enterIndex;
  final int? leavingIndex;
  final Key Function(String kind, int index) keyFor;
  final ValueChanged<int> onDelete;

  const _ScreenTabsRow({
    required this.vm,
    required this.previewing,
    required this.cardWidth,
    required this.enterIndex,
    required this.leavingIndex,
    required this.keyFor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final double slotWidth = cardWidth + MultiCanvasWorkspace.cardGap;
    const double barInset = 12;
    final double barLeft = vm.selectedIndex * slotWidth + MultiCanvasWorkspace.cardGap / 2 + barInset;
    final double barRight = barLeft + cardWidth - barInset * 2;

    return SizedBox(
      height: MultiCanvasWorkspace.tabsHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < vm.screenshotsCount; i++)
                _ScreenSlot(
                  key: keyFor('tab', i),
                  width: slotWidth,
                  enter: i == enterIndex,
                  leaving: i == leavingIndex,
                  child: Container(
                    width: cardWidth,
                    height: MultiCanvasWorkspace.tabPillHeight,
                    margin: const EdgeInsets.symmetric(horizontal: MultiCanvasWorkspace.cardGap / 2),
                    child: _ScreenTab(
                      index: i,
                      vm: vm,
                      previewing: previewing,
                      enter: i == enterIndex,
                      onDelete: onDelete,
                    ),
                  ),
                ),
              if (!previewing)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ClayIconButton(
                    icon: Icons.add_rounded,
                    size: 36,
                    iconSize: 20,
                    tooltip: 'Add a screen (inherits this screen\'s style)',
                    onPressed: vm.addScreenshot,
                  ),
                ),
            ],
          ),
          _SlidingUnderline(left: barLeft, right: barRight, visible: !previewing),
        ],
      ),
    );
  }
}

/// The one gold bar under the selected tab. Its two edges are separate
/// springs: the edge facing the target leads with a bounce, the trailing edge
/// follows gently, so the bar stretches while it travels and settles round.
class _SlidingUnderline extends StatefulWidget {
  final double left;
  final double right;
  final bool visible;

  const _SlidingUnderline({required this.left, required this.right, required this.visible});

  @override
  State<_SlidingUnderline> createState() => _SlidingUnderlineState();
}

class _SlidingUnderlineState extends State<_SlidingUnderline> with TickerProviderStateMixin {
  late final AnimationController _l = AnimationController.unbounded(vsync: this, value: widget.left);
  late final AnimationController _r = AnimationController.unbounded(vsync: this, value: widget.right);

  @override
  void didUpdateWidget(_SlidingUnderline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.left == widget.left && oldWidget.right == widget.right) return;
    final motion = ClayMotion.of(context);
    final bool movingRight = widget.left > oldWidget.left;
    _l.springTo(widget.left, spring: movingRight ? motion.gentle : motion.bouncy);
    _r.springTo(widget.right, spring: movingRight ? motion.bouncy : motion.gentle);
  }

  @override
  void dispose() {
    _l.dispose();
    _r.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: ClayDurations.crossfade,
          child: AnimatedBuilder(
            animation: Listenable.merge([_l, _r]),
            builder: (context, _) {
              final double left = _l.value;
              final double width = math.max(0.0, _r.value - left);
              return Transform.translate(
                offset: Offset(left, 0),
                child: SizedBox(
                  width: width,
                  height: MultiCanvasWorkspace.underlineHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScreenTab extends StatefulWidget {
  final int index;
  final EditorViewModel vm;
  final bool previewing;

  /// True for the screen that was just added: the tab wobbles once.
  final bool enter;
  final ValueChanged<int> onDelete;

  const _ScreenTab({
    required this.index,
    required this.vm,
    required this.previewing,
    required this.enter,
    required this.onDelete,
  });

  @override
  State<_ScreenTab> createState() => _ScreenTabState();
}

class _ScreenTabState extends State<_ScreenTab> with SingleTickerProviderStateMixin {
  bool _editing = false;
  late final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'screen-tab-name');
  DateTime? _lastPointerDown;
  DateTime? _editingSince;
  Timer? _blurTimer;

  /// 0 flat, 1 raised clay pill.
  late final AnimationController _sel;
  late bool _wasSelected;
  final JellyController _jelly = JellyController();

  bool get _selected => widget.vm.selectedIndex == widget.index && !widget.previewing;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    _wasSelected = _selected;
    _sel = AnimationController.unbounded(vsync: this, value: _wasSelected ? 1 : 0);
    if (widget.enter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _jelly.wobble(radians: 4 * math.pi / 180);
      });
    }
  }

  @override
  void didUpdateWidget(_ScreenTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sel = _selected;
    if (sel != _wasSelected) {
      _wasSelected = sel;
      final motion = ClayMotion.of(context);
      _sel.springTo(sel ? 1 : 0, spring: sel ? motion.bouncy : motion.snappy);
    }
  }

  @override
  void dispose() {
    _blurTimer?.cancel();
    _controller.dispose();
    _focus.dispose();
    _sel.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus || !_editing) return;
    final since = _editingSince;
    if (since != null && DateTime.now().difference(since) < const Duration(milliseconds: 700)) {
      // The menu that just closed, or the click that started editing, hands
      // focus back to the editor a moment later; take it again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editing) _focus.requestFocus();
      });
      return;
    }
    // Clicking into the field briefly blurs it (the canvas grabs focus on
    // pointer down, the field takes it back on tap), so commit only if the
    // focus really stays away.
    _blurTimer?.cancel();
    _blurTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _editing && !_focus.hasFocus) _commit();
    });
  }

  void _startEditing() {
    if (_editing) return;
    _controller.text = widget.vm.screenshots[widget.index].name;
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    _editingSince = DateTime.now();
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocus());
  }

  /// Focuses the name field, retrying briefly: while the tab menu is still
  /// animating closed, the editor underneath cannot take focus yet.
  void _ensureFocus([int attempt = 0]) {
    if (!mounted || !_editing || _focus.hasFocus) return;
    _focus.requestFocus();
    if (attempt < 5) {
      Future.delayed(const Duration(milliseconds: 150), () => _ensureFocus(attempt + 1));
    }
  }

  void _commit() {
    if (!_editing) return;
    widget.vm.setScreenName(widget.index, _controller.text);
    setState(() => _editing = false);
  }

  Future<void> _showMenu(BuildContext anchor) async {
    final vm = widget.vm;
    final i = widget.index;
    final box = anchor.findRenderObject() as RenderBox;
    // Global corners (the strip is zoomed, so the size must go through the
    // transform too).
    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero),
      box.localToGlobal(box.size.bottomRight(Offset.zero)),
    );

    final action = await showClayMenu<String>(
      context: anchor,
      anchorRect: rect,
      items: [
        const ClayMenuItem(value: 'rename', label: 'Rename', icon: Icons.drive_file_rename_outline_rounded),
        const ClayMenuItem(value: 'duplicate', label: 'Duplicate', icon: Icons.content_copy_rounded),
        const ClayMenuItem(value: 'apply', label: 'Apply this style to all screens', icon: Icons.auto_fix_high_rounded),
        const ClayMenuItem.divider(),
        ClayMenuItem(value: 'left', label: 'Move left', icon: Icons.arrow_back_rounded, enabled: i > 0),
        ClayMenuItem(
          value: 'right',
          label: 'Move right',
          icon: Icons.arrow_forward_rounded,
          enabled: i < vm.screenshotsCount - 1,
        ),
        const ClayMenuItem.divider(),
        ClayMenuItem(
          value: 'delete',
          label: 'Delete screen',
          icon: Icons.delete_outline_rounded,
          danger: true,
          enabled: vm.screenshotsCount > 1,
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'rename':
        _startEditing();
      case 'duplicate':
        vm.duplicateScreenshot(i);
      case 'apply':
        vm.applyStyleToAllScreens(i);
        ClayToast.show(context, 'Applied the style of ${vm.screenNameAt(i)} to all screens');
      case 'left':
        vm.moveScreenshot(i, i - 1);
      case 'right':
        vm.moveScreenshot(i, i + 1);
      case 'delete':
        widget.onDelete(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    const double radius = MultiCanvasWorkspace.tabPillHeight / 2;

    return Listener(
      // Own double-click timing (no minimum gap), so fast double-clicks from
      // mice and trackpads rename reliably.
      onPointerDown: widget.previewing || _editing
          ? null
          : (_) {
              final now = DateTime.now();
              final last = _lastPointerDown;
              _lastPointerDown = now;
              if (last != null && now.difference(last) < const Duration(milliseconds: 350)) {
                _lastPointerDown = null;
                _startEditing();
              }
            },
      child: ClayPressable(
        onTap: widget.previewing ? null : () => vm.selectScreenshot(widget.index),
        enabled: !widget.previewing && !_editing,
        squash: 0.04,
        jelly: _jelly,
        builder: (context, hover, press, _) {
          final double h = hover.clamp(0.0, 1.0);
          final double p = press.clamp(0.0, 1.0);
          return AnimatedBuilder(
            animation: _sel,
            builder: (context, _) {
              final double t = _sel.value.clamp(0.0, 1.2);
              final raised = ClayDecoration(
                color: AppColors.clay,
                radius: radius,
                depth: 4,
                lift: 8,
                pressed: p,
                shadowOpacity: 0.18,
                edgeOpacity: 0.10,
              );
              // Flat when idle; hover brings a faint mint fill.
              final idle = ClayDecoration(
                color: AppColors.mint.withValues(alpha: 0.4 * h),
                radius: radius,
                depth: 4,
                lift: 0,
                shadowOpacity: 0,
                highlightOpacity: 0,
                shadeOpacity: 0,
                edgeOpacity: 0,
              );
              final deco = ClayDecoration.lerp(idle, raised, t)!;
              final Color fg = Color.lerp(AppColors.textMuted, AppColors.textPrimary, t.clamp(0.0, 1.0))!;

              return Container(
                height: MultiCanvasWorkspace.tabPillHeight,
                padding: const EdgeInsets.only(left: 12, right: 3),
                decoration: deco,
                child: Row(
                  children: [
                    Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _editing
                          ? TextField(
                              controller: _controller,
                              focusNode: _focus,
                              onSubmitted: (_) => _commit(),
                              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
                              decoration: const InputDecoration(
                                isDense: true,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Screen name',
                              ),
                            )
                          : Text(
                              vm.screenNameAt(widget.index),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                    ),
                    if (!widget.previewing)
                      Builder(
                        builder: (ctx) => ClayIconButton(
                          icon: Icons.more_horiz_rounded,
                          size: 26,
                          iconSize: 16,
                          flat: true,
                          iconColor: fg,
                          tooltip: 'Screen options',
                          onPressed: () => _showMenu(ctx),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Header above a store row: store, device and export size. The active
/// store (the one uploads target) is a raised primary clay pill; the other
/// is flat muted text. Click a row to activate it.
class _StoreRowHeader extends StatefulWidget {
  final TargetPlatformType store;
  final bool active;
  final bool showBoth;
  final bool previewing;
  final VoidCallback onTap;
  final VoidCallback onToggleBoth;

  const _StoreRowHeader({
    required this.store,
    required this.active,
    required this.showBoth,
    required this.previewing,
    required this.onTap,
    required this.onToggleBoth,
  });

  @override
  State<_StoreRowHeader> createState() => _StoreRowHeaderState();
}

class _StoreRowHeaderState extends State<_StoreRowHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _active;
  late bool _wasHighlighted;

  bool get _highlighted => widget.active && !widget.previewing;

  @override
  void initState() {
    super.initState();
    _wasHighlighted = _highlighted;
    _active = AnimationController.unbounded(vsync: this, value: _wasHighlighted ? 1 : 0);
  }

  @override
  void didUpdateWidget(_StoreRowHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final on = _highlighted;
    if (on != _wasHighlighted) {
      _wasHighlighted = on;
      final motion = ClayMotion.of(context);
      _active.springTo(on ? 1 : 0, spring: on ? motion.bouncy : motion.snappy);
    }
  }

  @override
  void dispose() {
    _active.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    const double radius = MultiCanvasWorkspace.rowHeaderHeight / 2;

    Widget pill = ClayPressable(
      onTap: widget.previewing ? null : widget.onTap,
      squash: 0.05,
      builder: (context, hover, press, _) {
        final double h = hover.clamp(0.0, 1.0);
        final double p = press.clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _active,
          builder: (context, _) {
            final double t = _active.value.clamp(0.0, 1.15);
            final raised = ClayDecoration.primary(radius: radius, lift: 8, pressed: p);
            final idle = ClayDecoration(
              color: AppColors.mint.withValues(alpha: 0.4 * h),
              radius: radius,
              depth: 5,
              lift: 0,
              shadowOpacity: 0,
              highlightOpacity: 0,
              shadeOpacity: 0,
              edgeOpacity: 0,
            );
            final deco = ClayDecoration.lerp(idle, raised, t)!;
            final Color fg = Color.lerp(AppColors.textMuted, AppColors.textOnPrimary, t.clamp(0.0, 1.0))!;

            return Container(
              height: MultiCanvasWorkspace.rowHeaderHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: deco,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(store == TargetPlatformType.appStore ? Icons.apple : Icons.android, size: 14, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    '${store.shortName} · ${store.deviceName}',
                    style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    store.dimensionsLabel,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!widget.previewing) {
      pill = Tooltip(
        message: widget.active ? 'Active store: uploads go here' : 'Click to make this the active store',
        child: pill,
      );
    }

    return SizedBox(
      height: MultiCanvasWorkspace.rowHeaderHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill,
          if (!widget.previewing && !widget.showBoth) ...[
            const SizedBox(width: 6),
            ClayButton.text(
              label: 'Both stores',
              icon: Icons.view_agenda_outlined,
              size: ClayButtonSize.compact,
              onPressed: widget.onToggleBoth,
            ),
          ],
        ],
      ),
    );
  }
}
