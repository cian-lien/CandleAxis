import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../layout/cut_corner_panel.dart';

export '../layout/cut_corner_panel.dart' show CutCornerPosition;

/// 使用标准 Flutter 路由展示斜切 Dialog。
///
/// 该方法只负责路由行为，展示内容由 [builder] 返回的 [CutCornerDialog] 决定，
/// 因此业务层可以通过泛型返回确认、取消等任意结果。
Future<T?> showCutCornerDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: builder,
  );
}

/// 带有可配置斜切、插槽和关闭按钮的全局 Dialog 组件。
///
/// 结构模式按照 Header、Title、正文、Footer 的顺序布局。旧的 [child] 模式会
/// 原样承载整块内容，以兼容已有调用；两种模式不能混用。
class CutCornerDialog extends StatelessWidget {
  const CutCornerDialog({
    super.key,
    this.child,
    this.header,
    this.title,
    this.titleWidget,
    this.body,
    this.footer,
    this.panelKey,
    this.insetPadding,
    this.constraints,
    this.padding = EdgeInsets.zero,
    this.headerPadding,
    this.titlePadding,
    this.bodyPadding,
    this.footerPadding,
    this.sectionSpacing = 16,
    this.titleTextAlign = TextAlign.start,
    this.titleStyle,
    this.showCloseButton = true,
    this.onClosePressed,
    this.closeButtonBuilder,
    this.closeButtonPadding = const EdgeInsets.all(4),
    this.backgroundColor,
    this.gradient,
    this.borderSide = BorderSide.none,
    this.elevation = 0,
    this.shadowColor,
    this.corners = const {CutCornerPosition.topLeft},
    this.cutSize,
    this.cutWidth,
    this.cutHeight,
    this.cutRadius,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(
         child == null ||
             (header == null &&
                 title == null &&
                 titleWidget == null &&
                 body == null &&
                 footer == null),
         'child 模式不能与 Header、Title、正文或 Footer 插槽同时使用。',
       ),
       assert(
         title == null || titleWidget == null,
         'title 与 titleWidget 不能同时设置。',
       ),
       assert(
         cutRadius == null ||
             (cutSize == null && cutWidth == null && cutHeight == null),
         'cutRadius 不能与 cutSize、cutWidth 或 cutHeight 同时设置。',
       ),
       assert(sectionSpacing >= 0, 'sectionSpacing 不能小于 0。');

  /// 兼容旧调用的完整内容模式；使用时不能再传入各结构插槽。
  final Widget? child;

  /// 最顶部的自定义插槽，默认不展示，可放置图标、标签或 Sheet 拖拽条。
  final Widget? header;

  /// 内置标题文本；为空时不展示标题。
  final String? title;

  /// 完全自定义的标题插槽，设置后覆盖内置 [title]。
  final Widget? titleWidget;

  /// 位于标题之后的正文插槽。
  final Widget? body;

  /// 位于最底部的操作区插槽。
  final Widget? footer;

  /// 赋予内部斜切面板的 Key，便于测试或定位。
  final Key? panelKey;

  /// Dialog 距离屏幕边缘的外边距；默认沿用原组件的响应式边距。
  final EdgeInsets? insetPadding;

  /// Dialog 面板可使用的尺寸约束。
  final BoxConstraints? constraints;

  /// 各插槽未单独设置内边距时使用的统一内边距。
  final EdgeInsetsGeometry padding;

  /// Header 的专用内边距，设置后覆盖 [padding]。
  final EdgeInsetsGeometry? headerPadding;

  /// Title 的专用内边距，设置后覆盖 [padding]。
  final EdgeInsetsGeometry? titlePadding;

  /// 正文的专用内边距，设置后覆盖 [padding]。
  final EdgeInsetsGeometry? bodyPadding;

  /// Footer 的专用内边距，设置后覆盖 [padding]。
  final EdgeInsetsGeometry? footerPadding;

  /// 相邻且同时存在的插槽之间的垂直间距。
  final double sectionSpacing;

  /// 内置 [title] 的文字对齐方式，支持左对齐、居中和右对齐。
  final TextAlign titleTextAlign;

  /// 内置 [title] 的文字样式；未设置部分回退到主题标题样式。
  final TextStyle? titleStyle;

  /// 是否显示右上角关闭按钮，默认显示。
  final bool showCloseButton;

  /// 点击关闭按钮时执行的业务回调。
  ///
  /// 该回调完全接管关闭和返回值，可与 Footer 中的取消按钮共用；为空时组件仅
  /// 调用 [NavigatorState.maybePop] 返回空结果。
  final VoidCallback? onClosePressed;

  /// 自定义关闭按钮构建器；第二个参数是与默认关闭按钮相同的关闭方法。
  final Widget Function(BuildContext context, VoidCallback onPressed)?
  closeButtonBuilder;

  /// 右上角关闭按钮距面板边缘的内边距。
  final EdgeInsets closeButtonPadding;

  /// 面板纯色背景；未设置时使用当前主题的 surface 颜色。
  final Color? backgroundColor;

  /// 面板渐变背景；设置后覆盖 [backgroundColor]。
  final Gradient? gradient;

  /// 面板边框样式。
  final BorderSide borderSide;

  /// 面板阴影高度。
  final double elevation;

  /// 面板阴影颜色；为空时使用 Material 默认阴影色。
  final Color? shadowColor;

  /// 需要斜切的角集合，默认仅斜切左上角。
  final Set<CutCornerPosition> corners;

  /// 水平和垂直方向共用的切角尺寸。
  final double? cutSize;

  /// 切角的水平延伸长度，优先级高于 [cutSize]。
  final double? cutWidth;

  /// 切角的垂直延伸长度，优先级高于 [cutSize]。
  final double? cutHeight;

  /// 兼容旧调用的单个切角半径。
  ///
  /// 新代码请改用 [cutSize] 或 [cutWidth]/[cutHeight]；该参数不能与新尺寸参数
  /// 同时设置。
  final Radius? cutRadius;

  /// 是否将内部内容裁剪到斜切形状内。
  final Clip clipBehavior;

  /// 构建内置标题，并为默认关闭按钮保留不会重叠的可用空间。
  Widget? _buildTitle(BuildContext context) {
    final customTitle = titleWidget;
    if (customTitle != null) return customTitle;

    final text = title;
    if (text == null) return null;

    final baseStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final reserveCloseButton = showCloseButton
        ? switch (titleTextAlign) {
            TextAlign.center => const EdgeInsets.symmetric(
              horizontal: kMinInteractiveDimension,
            ),
            _ => const EdgeInsetsDirectional.only(
              end: kMinInteractiveDimension,
            ),
          }
        : EdgeInsets.zero;

    return Padding(
      padding: reserveCloseButton,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: titleTextAlign,
          style: baseStyle?.merge(titleStyle) ?? titleStyle,
        ),
      ),
    );
  }

  /// 依次添加存在的插槽，并只在相邻插槽之间插入统一间距。
  List<Widget> _buildStructuredChildren(BuildContext context) {
    final builtTitle = _buildTitle(context);
    final sections = <(Widget, EdgeInsetsGeometry?)>[
      if (header != null) (header!, headerPadding),
      if (builtTitle != null) (builtTitle, titlePadding),
      if (body != null) (body!, bodyPadding),
      if (footer != null) (footer!, footerPadding),
    ];

    final children = <Widget>[];
    for (final section in sections) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: sectionSpacing));
      }
      children.add(Padding(padding: section.$2 ?? padding, child: section.$1));
    }
    return children;
  }

  /// 处理默认关闭行为或交由业务回调决定如何关闭和返回结果。
  void _handleClose(BuildContext context) {
    final callback = onClosePressed;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }

  /// 构建默认关闭按钮，或调用方提供的自定义关闭按钮。
  Widget _buildCloseButton(BuildContext context) {
    void onPressed() => _handleClose(context);

    return closeButtonBuilder?.call(context, onPressed) ??
        IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onPressed,
          icon: const Icon(Icons.close),
        );
  }

  @override
  Widget build(BuildContext context) {
    final content =
        child ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildStructuredChildren(context),
        );
    final panelContent = showCloseButton
        ? Stack(
            children: [
              content,
              Positioned(
                top: closeButtonPadding.top,
                right: closeButtonPadding.right,
                child: _buildCloseButton(context),
              ),
            ],
          )
        : content;
    // 默认切角沿用竖屏基线，旋转后按短边/长边缩放，避免斜边被横向拉平。
    final screenSize = MediaQuery.sizeOf(context);
    final defaultCutWidth = 25.w * screenSize.shortestSide / screenSize.width;
    final defaultCutHeight =
        21.5.h * screenSize.longestSide / screenSize.height;
    Widget panel = CutCornerPanel(
      panelKey: panelKey,
      corners: corners,
      cutSize: cutSize,
      cutWidth: cutWidth ?? cutRadius?.x ?? cutSize ?? defaultCutWidth,
      cutHeight: cutHeight ?? cutRadius?.y ?? cutSize ?? defaultCutHeight,
      backgroundColor: backgroundColor,
      gradient: gradient,
      borderSide: borderSide,
      elevation: elevation,
      shadowColor: shadowColor,
      clipBehavior: clipBehavior,
      child: panelContent,
    );

    final constraints = this.constraints;
    if (constraints != null) {
      panel = ConstrainedBox(constraints: constraints, child: panel);
    }

    return Dialog(
      insetPadding:
          insetPadding ??
          EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: panel,
    );
  }
}
