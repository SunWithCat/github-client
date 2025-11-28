import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class SafeScaffold extends StatelessWidget {
  /// AppBar - 顶部应用栏
  final PreferredSizeWidget? appBar;

  /// body - 主体内容
  final Widget? body;

  /// floatingActionButton - 悬浮按钮
  final Widget? floatingActionButton;

  /// floatingActionButtonLocation - 悬浮按钮位置
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// floatingActionButtonAnimator - 悬浮按钮动画
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  /// persistentFooterButtons - 底部持久按钮
  final List<Widget>? persistentFooterButtons;

  /// drawer - 左侧抽屉
  final Widget? drawer;

  /// endDrawer - 右侧抽屉
  final Widget? endDrawer;

  /// bottomNavigationBar - 底部导航栏
  final Widget? bottomNavigationBar;

  /// bottomSheet - 底部面板
  final Widget? bottomSheet;

  /// backgroundColor - 背景颜色
  final Color? backgroundColor;

  /// resizeToAvoidBottomInset - 是否自动调整大小以避免底部遮挡（键盘等）
  final bool? resizeToAvoidBottomInset;

  /// primary - 是否为主要的 Scaffold
  final bool primary;

  /// drawerDragStartBehavior - 抽屉拖动起始行为
  final DragStartBehavior drawerDragStartBehavior;

  /// extendBody - 是否扩展 body 到底部导航栏后面
  final bool extendBody;

  /// extendBodyBehindAppBar - 是否扩展 body 到 AppBar 后面
  final bool extendBodyBehindAppBar;

  /// drawerScrimColor - 抽屉遮罩颜色
  final Color? drawerScrimColor;

  /// drawerEdgeDragWidth - 抽屉边缘拖动宽度
  final double? drawerEdgeDragWidth;

  /// drawerEnableOpenDragGesture - 是否启用左侧抽屉的拖动手势
  final bool drawerEnableOpenDragGesture;

  /// endDrawerEnableOpenDragGesture - 是否启用右侧抽屉的拖动手势
  final bool endDrawerEnableOpenDragGesture;

  /// restorationId - 恢复 ID
  final String? restorationId;

  /// 异常顶部间距阈值（单位：像素）
  /// 当系统报告的顶部间距超过这个值时，认为是异常的，会被移除
  /// 默认为 100，可以根据实际情况调整
  final double abnormalPaddingThreshold;

  const SafeScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
    this.abnormalPaddingThreshold = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 Builder 来获取当前上下文的 MediaQuery
    return Builder(
      builder: (context) {
        // 获取系统报告的安全区域边距
        final padding = MediaQuery.of(context).padding;
        final hasAbnormalTopPadding = padding.top > abnormalPaddingThreshold;

        // 构建标准的 Scaffold
        final scaffold = Scaffold(
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          floatingActionButtonAnimator: floatingActionButtonAnimator,
          persistentFooterButtons: persistentFooterButtons,
          drawer: drawer,
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar,
          bottomSheet: bottomSheet,
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          primary: primary,
          drawerDragStartBehavior: drawerDragStartBehavior,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          drawerScrimColor: drawerScrimColor,
          drawerEdgeDragWidth: drawerEdgeDragWidth,
          drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
          endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
          restorationId: restorationId,
        );

        // 如果检测到异常的顶部间距，移除它以修复显示问题
        if (hasAbnormalTopPadding) {
          return MediaQuery.removePadding(
            context: context,
            removeTop: true, // 只移除顶部异常间距
            child: scaffold,
          );
        }

        // 正常情况下直接返回 Scaffold
        return scaffold;
      },
    );
  }
}
