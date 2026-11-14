import 'package:fluid_glass/fluid_glass.dart';
import 'package:flutter/material.dart';

/// 导航栏标签项
class GlassNavItem {
  const GlassNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// 标签排版常量
const double kNavBarIconSize = 22;
const double kNavBarLabelFontSize = 11.5;

/// 液态玻璃悬浮导航栏
class LiquidGlassNavBar extends StatelessWidget {
  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.backdrop,
    this.isInteractive = true,
    this.iconSize = kNavBarIconSize,
    this.labelFontSize = kNavBarLabelFontSize,
  });

  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Backdrop backdrop;
  final bool isInteractive;
  final double iconSize;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final LiquidGlassColors colors = LiquidGlassTheme.of(context);

    return LiquidBottomTabs(
      selectedTabIndex: selectedIndex,
      onTabSelected: onSelected,
      backdrop: backdrop,
      tabsCount: items.length,
      isInteractive: isInteractive,
      children: <Widget>[
        for (int i = 0; i < items.length; i++)
          _tab(
            item: items[i],
            selected: i == selectedIndex,
            colors: colors,
            onPressed: () => onSelected(i),
          ),
      ],
    );
  }

  Widget _tab({
    required GlassNavItem item,
    required bool selected,
    required LiquidGlassColors colors,
    required VoidCallback onPressed,
  }) {
    return LiquidBottomTab(
      onPressed: onPressed,
      children: <Widget>[
        Semantics(
          selected: selected,
          button: true,
          label: item.label,
          child: Icon(item.icon, size: iconSize, color: colors.content),
        ),
        Text(
          item.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: labelFontSize,
            height: 14 / labelFontSize,
            color: colors.content,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
