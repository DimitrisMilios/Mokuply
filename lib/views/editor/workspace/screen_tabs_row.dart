import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'screen_slot.dart';
import 'screen_tab.dart';
import 'sliding_underline.dart';
import 'workspace_layout.dart';

/// Named tab above each screen, the gold underline that slides to the
/// selected tab, and an "add screen" button at the end of the strip.
class ScreenTabsRow extends StatelessWidget {
  final int screenCount;
  final int selectedIndex;
  final bool previewing;
  final double cardWidth;
  final int? enterIndex;
  final int? leavingIndex;
  final Key Function(String kind, int index) keyFor;
  final ValueChanged<int> onDelete;

  const ScreenTabsRow({
    super.key,
    required this.screenCount,
    required this.selectedIndex,
    required this.previewing,
    required this.cardWidth,
    required this.enterIndex,
    required this.leavingIndex,
    required this.keyFor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final double slotWidth = cardWidth + WorkspaceLayout.cardGap;
    const double barInset = 12;
    final double barLeft = selectedIndex * slotWidth + WorkspaceLayout.cardGap / 2 + barInset;

    return SizedBox(
      height: WorkspaceLayout.tabsHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < screenCount; i++)
                ScreenSlot(
                  key: keyFor('tab', i),
                  width: slotWidth,
                  enter: i == enterIndex,
                  leaving: i == leavingIndex,
                  child: Container(
                    width: cardWidth,
                    height: WorkspaceLayout.tabPillHeight,
                    margin: const EdgeInsets.symmetric(horizontal: WorkspaceLayout.cardGap / 2),
                    child: ScreenTab(index: i, previewing: previewing, enter: i == enterIndex, onDelete: onDelete),
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
                    onPressed: context.read<EditorViewModel>().addScreenshot,
                  ),
                ),
            ],
          ),
          SlidingUnderline(left: barLeft, right: barLeft + cardWidth - barInset * 2, visible: !previewing),
        ],
      ),
    );
  }
}
