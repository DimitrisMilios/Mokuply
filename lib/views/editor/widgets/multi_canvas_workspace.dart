import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/canvas/canvas_mockup_widget.dart';
import '../../../widgets/shared/canvas_grid_painter.dart';

/// Centre workspace: the screens of the project laid out as one continuous
/// store strip, with a named tab above each screen and one live row per
/// store (App Store on top, Google Play below). Pan and zoom like Figma.
class MultiCanvasWorkspace extends StatelessWidget {
  final TransformationController transformationController;

  /// Preview mode: no tabs' menus, no selection chrome, nothing draggable.
  final bool previewing;

  const MultiCanvasWorkspace({super.key, required this.transformationController, this.previewing = false});

  /// All cards share one height, so the shared design renders at the same
  /// scale on both stores; only the card width follows the store.
  static const double previewHeight = 620.0;
  static const double cardGap = 4.0;
  static const double tabsHeight = 34.0;
  static const double rowHeaderHeight = 30.0;
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
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    final rows = vm.visibleStores;

    return Container(
      color: AppColors.canvasViewport,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: CanvasGridPainter())),
          Positioned.fill(
            child: CanvasViewportZoom(
              controller: transformationController,
              child: InteractiveViewer(
                transformationController: transformationController,
                minScale: 0.15,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.symmetric(horizontal: 900, vertical: 700),
                constrained: false,
                panEnabled: true,
                scaleEnabled: true,
                child: Padding(
                  padding: contentPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScreenTabsRow(vm: vm, previewing: previewing, cardWidth: cardWidthFor(rows.first)),
                      const SizedBox(height: 10),
                      for (final (r, store) in rows.indexed) ...[
                        if (r > 0) const SizedBox(height: rowSpacing),
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
                            final double width = cardWidthFor(store);

                            return Listener(
                              onPointerDown: (_) {
                                if (previewing) return;
                                if (!isSelected) vm.selectScreenshot(index);
                                if (vm.platform != store) vm.setPlatform(store);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                // 2px per side = 4px between neighbouring screens, so the strip
                                // reads as one continuous store listing.
                                margin: const EdgeInsets.symmetric(horizontal: cardGap / 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    width: isSelected ? 3 : 0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.40)
                                          : AppColors.primary.withValues(alpha: 0.12),
                                      blurRadius: isSelected ? 34 : 20,
                                      spreadRadius: isSelected ? 3 : 0,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                // Each screen repaints on its own, so dragging on one
                                // card never re-rasterises the others.
                                child: RepaintBoundary(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg - 2),
                                    child: CanvasMockupWidget(
                                      data: itemData,
                                      itemIndex: index,
                                      canvasSize: Size(width, previewHeight),
                                      interactive: !previewing,
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

/// Named tab above each screen (double-click to rename, menu for more) and
/// an "add screen" button at the end of the strip.
class _ScreenTabsRow extends StatelessWidget {
  final EditorViewModel vm;
  final bool previewing;
  final double cardWidth;

  const _ScreenTabsRow({required this.vm, required this.previewing, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < vm.screenshotsCount; i++)
          Container(
            width: cardWidth,
            height: MultiCanvasWorkspace.tabsHeight,
            margin: const EdgeInsets.symmetric(horizontal: MultiCanvasWorkspace.cardGap / 2),
            child: _ScreenTab(key: ValueKey('tab_$i'), index: i, vm: vm, previewing: previewing),
          ),
        if (!previewing)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Tooltip(
              message: 'Add a screen (inherits this screen\'s style)',
              child: Material(
                color: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: InkWell(
                  onTap: vm.addScreenshot,
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    width: 50,
                    height: MultiCanvasWorkspace.tabsHeight,
                    child: Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScreenTab extends StatefulWidget {
  final int index;
  final EditorViewModel vm;
  final bool previewing;

  const _ScreenTab({super.key, required this.index, required this.vm, required this.previewing});

  @override
  State<_ScreenTab> createState() => _ScreenTabState();
}

class _ScreenTabState extends State<_ScreenTab> {
  bool _editing = false;
  late final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'screen-tab-name');
  DateTime? _lastPointerDown;
  DateTime? _editingSince;
  Timer? _blurTimer;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _blurTimer?.cancel();
    _controller.dispose();
    _focus.dispose();
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
    final overlay = Overlay.of(anchor).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset(0, box.size.height), ancestor: overlay);
    final position = RelativeRect.fromLTRB(origin.dx, origin.dy, overlay.size.width - origin.dx, 0);

    final action = await showMenu<String>(
      context: anchor,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'rename',
          height: 36,
          child: _TabMenuRow(Icons.drive_file_rename_outline_rounded, 'Rename'),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          height: 36,
          child: _TabMenuRow(Icons.content_copy_rounded, 'Duplicate'),
        ),
        const PopupMenuItem(
          value: 'apply',
          height: 36,
          child: _TabMenuRow(Icons.auto_fix_high_rounded, 'Apply this style to all screens'),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: 'left',
          height: 36,
          enabled: i > 0,
          child: const _TabMenuRow(Icons.arrow_back_rounded, 'Move left'),
        ),
        PopupMenuItem(
          value: 'right',
          height: 36,
          enabled: i < vm.screenshotsCount - 1,
          child: const _TabMenuRow(Icons.arrow_forward_rounded, 'Move right'),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          enabled: vm.screenshotsCount > 1,
          child: const _TabMenuRow(Icons.delete_outline_rounded, 'Delete screen', danger: true),
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
        if (anchor.mounted) {
          ScaffoldMessenger.of(anchor).showSnackBar(
            SnackBar(
              content: Text('Applied the style of ${vm.screenNameAt(i)} to all screens.'),
              behavior: SnackBarBehavior.floating,
              width: 360,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      case 'left':
        vm.moveScreenshot(i, i - 1);
      case 'right':
        vm.moveScreenshot(i, i + 1);
      case 'delete':
        vm.removeScreenshot(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final bool selected = vm.selectedIndex == widget.index && !widget.previewing;
    final Color fg = selected ? AppColors.textOnPrimary : AppColors.textPrimary;

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
      child: GestureDetector(
        onTap: widget.previewing ? null : () => vm.selectScreenshot(widget.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(left: 10, right: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Text(
                '${widget.index + 1}',
                style: TextStyle(
                  color: selected ? AppColors.textOnPrimary.withValues(alpha: 0.75) : AppColors.textMuted,
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
                  builder: (ctx) => IconButton(
                    onPressed: () => _showMenu(ctx),
                    tooltip: 'Screen options',
                    splashRadius: 14,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(Icons.more_horiz_rounded, size: 18, color: fg),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  const _TabMenuRow(this.icon, this.label, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Header above a store row: store, device and export size. The active
/// store (the one uploads target) is highlighted; click a row to activate it.
class _StoreRowHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool highlighted = active && !previewing;
    final Color fg = highlighted ? AppColors.textOnPrimary : AppColors.textSecondary;

    return SizedBox(
      height: MultiCanvasWorkspace.rowHeaderHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: previewing
                ? ''
                : (active ? 'Active store: uploads go here' : 'Click to make this the active store'),
            child: InkWell(
              onTap: previewing ? null : onTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: highlighted ? AppColors.primary : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: highlighted ? AppColors.primary : AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(store == TargetPlatformType.appStore ? Icons.apple : Icons.android, size: 13, color: fg),
                    const SizedBox(width: 6),
                    Text(
                      '${store.shortName} · ${store.deviceName}',
                      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
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
              ),
            ),
          ),
          if (!previewing && !showBoth) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: 'Show both stores',
              child: InkWell(
                onTap: onToggleBoth,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_agenda_outlined, size: 13, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Both stores',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
