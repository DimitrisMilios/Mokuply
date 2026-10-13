import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'screen_tab_menu.dart';
import 'screen_tab_pill.dart';

/// Named tab above a screen: click selects, double-click (or the menu)
/// renames in place, "…" opens the screen menu.
class ScreenTab extends StatefulWidget {
  final int index;
  final bool previewing;

  /// True for the screen that was just added: the tab wobbles once.
  final bool enter;
  final ValueChanged<int> onDelete;

  const ScreenTab({
    super.key,
    required this.index,
    required this.previewing,
    required this.enter,
    required this.onDelete,
  });

  @override
  State<ScreenTab> createState() => _ScreenTabState();
}

class _ScreenTabState extends State<ScreenTab> with SingleTickerProviderStateMixin {
  static const Duration _doubleClick = Duration(milliseconds: 350);
  static const TextStyle _nameStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'screen-tab-name');
  final JellyController _jelly = JellyController();

  /// 0 flat, 1 raised clay pill.
  late final AnimationController _sel = AnimationController.unbounded(vsync: this, value: 0);
  bool? _wasSelected;

  bool _editing = false;
  DateTime? _lastPointerDown;
  DateTime? _editingSince;
  Timer? _blurTimer;

  EditorViewModel get _vm => context.read<EditorViewModel>();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    if (widget.enter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _jelly.wobble(radians: 4 * math.pi / 180);
      });
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

  /// Springs the pill up or down when the selection changes.
  void _syncSelection(bool selected) {
    if (_wasSelected == null) {
      _sel.value = selected ? 1 : 0;
    } else if (selected != _wasSelected) {
      final motion = ClayMotion.of(context);
      _sel.springTo(selected ? 1 : 0, spring: selected ? motion.bouncy : motion.snappy);
    }
    _wasSelected = selected;
  }

  // --- Rename in place ---

  void _onPointerDown() {
    final now = DateTime.now();
    final last = _lastPointerDown;
    _lastPointerDown = now;
    // Own double-click timing (no minimum gap), so fast double-clicks rename.
    if (last != null && now.difference(last) < _doubleClick) {
      _lastPointerDown = null;
      _startEditing();
    }
  }

  void _startEditing() {
    if (_editing) return;
    _controller.text = _vm.screenAt(widget.index).name;
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
    if (attempt < 5) Future.delayed(const Duration(milliseconds: 150), () => _ensureFocus(attempt + 1));
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
    // pointer down), so commit only if the focus really stays away.
    _blurTimer?.cancel();
    _blurTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _editing && !_focus.hasFocus) _commit();
    });
  }

  void _commit() {
    if (!_editing) return;
    _vm.setScreenName(widget.index, _controller.text);
    setState(() => _editing = false);
  }

  Future<void> _openMenu(BuildContext anchor) async {
    final vm = _vm;
    final action = await showScreenTabMenu(anchor: anchor, index: widget.index, screenCount: vm.screenshotsCount);
    if (!mounted || action == null) return;
    switch (action) {
      case ScreenTabAction.rename:
        _startEditing();
      case ScreenTabAction.delete:
        widget.onDelete(widget.index);
      default:
        runScreenTabAction(context, vm, action, widget.index);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final (name, selected) = context.select<EditorViewModel, (String, bool)>(
      (vm) => widget.index < vm.screenshotsCount
          ? (vm.screenNameAt(widget.index), vm.selectedIndex == widget.index)
          : ('', false),
    );
    _syncSelection(selected && !widget.previewing);

    return Listener(
      onPointerDown: widget.previewing || _editing ? null : (_) => _onPointerDown(),
      child: ClayPressable(
        onTap: widget.previewing ? null : () => _vm.selectScreenshot(widget.index),
        enabled: !widget.previewing && !_editing,
        squash: 0.04,
        jelly: _jelly,
        builder: (context, hover, press, _) => AnimatedBuilder(
          animation: _sel,
          builder: (context, _) => ScreenTabPill(
            index: widget.index,
            hover: hover,
            press: press,
            selection: _sel.value,
            label: (fg) => _editing ? _nameField(fg) : _nameText(name, fg),
            trailing: widget.previewing ? null : _menuButton,
          ),
        ),
      ),
    );
  }

  Widget _nameText(String name, Color fg) => Text(
    name,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: _nameStyle.copyWith(color: fg),
  );

  Widget _nameField(Color fg) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      onSubmitted: (_) => _commit(),
      style: _nameStyle.copyWith(color: fg),
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: 'Screen name',
      ),
    );
  }

  Widget _menuButton(Color fg) {
    return Builder(
      builder: (anchor) => ClayIconButton(
        icon: Icons.more_horiz_rounded,
        size: 26,
        iconSize: 16,
        flat: true,
        iconColor: fg,
        tooltip: 'Screen options',
        onPressed: () => _openMenu(anchor),
      ),
    );
  }
}
