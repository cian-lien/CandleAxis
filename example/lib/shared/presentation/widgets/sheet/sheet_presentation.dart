import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 在局部界面启用横屏侧边弹层，路由内也保留此约定。
class SideSheetScope extends InheritedWidget {
  const SideSheetScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SideSheetScope>() != null;

  @override
  bool updateShouldNotify(SideSheetScope oldWidget) => false;
}

/// 横屏侧栏使用逻辑像素；竖屏沿用 ScreenUtil 的设计尺寸。
extension SheetDimensions on num {
  double sheetW(BuildContext context) =>
      SideSheetScope.of(context) ? toDouble() : w;
  double sheetH(BuildContext context) =>
      SideSheetScope.of(context) ? toDouble() : h;
  double sheetSp(BuildContext context) =>
      SideSheetScope.of(context) ? toDouble() : sp;
  double sheetR(BuildContext context) =>
      SideSheetScope.of(context) ? toDouble() : r;
}
