import 'dart:math' as math;

import 'package:fluid_glass/fluid_glass.dart';
import 'package:flutter/material.dart';

/// 导航栏标签项
class GlassNavItem {
  const GlassNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// 选中指示器的稳定测试标识
const Key navBarIndicatorKey = Key('liquidGlassNavBarIndicator');

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

/// 底部悬浮玻璃导航栏的布局脚手架
class GlassNavBarScaffold extends StatelessWidget {
  const GlassNavBarScaffold({
    super.key,
    required this.body,
    required this.navBar,
    this.clipBehavior = Clip.none,
  });

  final Widget body;
  final Widget navBar;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final double inset = MediaQuery.viewPaddingOf(context).bottom;
    final double bottom = inset != 0 ? 8 + inset : 28.0;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        clipBehavior: clipBehavior,
        children: <Widget>[
          Positioned.fill(child: body),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 0, 28, bottom),
              child: navBar,
            ),
          ),
        ],
      ),
    );
  }
}

/// 禁用过度滚动拉伸，避免边缘渲染黑色
class GlassScrollBehavior extends MaterialScrollBehavior {
  const GlassScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// 导航栏尺寸常量与几何计算
abstract final class GlassNavBarMetrics {
  const GlassNavBarMetrics._();

  static const double panelHeight = 64;
  static const double inset = 4;
  static const double pillHeight = panelHeight - inset * 2;

  static double tabWidth(double barWidth, int tabCount) {
    if (tabCount <= 0) return 0;
    return (barWidth - inset * 2) / tabCount;
  }

  static double pillLeft(double barWidth, int tabCount, int index) {
    return inset + math.min(tabWidth(barWidth, tabCount) * index, barWidth);
  }
}
