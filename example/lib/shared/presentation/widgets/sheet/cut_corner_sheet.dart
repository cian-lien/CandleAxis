import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../themes/colors.dart';
import '../layout/cut_corner_panel.dart';
import 'sheet_presentation.dart';
import 'side_sheet_route.dart';

export '../layout/cut_corner_panel.dart' show CutCornerPosition;
export 'sheet_presentation.dart';

/// 使用标准 Flutter 路由展示斜切 Sheet。
///
/// 该方法统一透明路由背景、可滚动路由和泛型返回值；展示内容由 [builder] 返回的
/// [CutCornerSheet] 决定。正文是否滚动由调用方提供的 [CutCornerSheet.body] 控制。
Future<T?> showCutCornerSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
  Color? barrierColor,
  ValueListenable<Color?>? barrierColorListenable,
  BoxConstraints? constraints,
  RouteSettings? routeSettings,
}) {
  if (SideSheetScope.of(context)) {
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    return navigator.push(
      SideSheetRoute<T>(
        builder: builder,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        barrierColor:
            barrierColor ??
            Theme.of(context).bottomSheetTheme.modalBarrierColor ??
            AppColors.overlayBlack.withValues(alpha: 0.54),
        barrierColorListenable: barrierColorListenable,
        barrierLabel: MaterialLocalizations.of(context).scrimLabel,
        barrierDismissible: isDismissible,
        enableDrag: enableDrag,
        settings: routeSettings,
      ),
    );
  }
  if (barrierColorListenable != null) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));

    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final localizations = MaterialLocalizations.of(context);
    return navigator.push(
      _ListenableBarrierModalBottomSheetRoute<T>(
        builder: builder,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        isScrollControlled: isScrollControlled,
        barrierLabel: localizations.scrimLabel,
        barrierOnTapHint: localizations.scrimOnTapHint(
          localizations.bottomSheetLabel,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        constraints: constraints,
        isDismissible: isDismissible,
        modalBarrierColor:
            barrierColor ??
            Theme.of(context).bottomSheetTheme.modalBarrierColor,
        barrierColorListenable: barrierColorListenable,
        enableDrag: enableDrag,
        settings: routeSettings,
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    barrierColor: barrierColor,
    constraints: constraints,
    routeSettings: routeSettings,
  );
}

class _ListenableBarrierModalBottomSheetRoute<T>
    extends ModalBottomSheetRoute<T> {
  _ListenableBarrierModalBottomSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    required this.barrierColorListenable,
    super.capturedThemes,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.backgroundColor,
    super.elevation,
    super.constraints,
    super.modalBarrierColor,
    super.isDismissible,
    super.enableDrag,
    super.settings,
  });

  final ValueListenable<Color?> barrierColorListenable;

  @override
  Color get barrierColor => barrierColorListenable.value ?? super.barrierColor;

  @override
  void install() {
    super.install();
    barrierColorListenable.addListener(_handleBarrierColorChanged);
  }

  @override
  void dispose() {
    barrierColorListenable.removeListener(_handleBarrierColorChanged);
    super.dispose();
  }

  void _handleBarrierColorChanged() {
    changedInternalState();
  }
}

/// 带有可配置斜切和四插槽布局的全局底部 Sheet 组件。
///
/// 插槽严格按照 Header、Title、正文、Footer 的顺序布局。组件负责安全区、键盘
/// 避让和最大高度；正文保持为调用方传入的原始 Widget，不会被自动包裹为滚动容器。
class CutCornerSheet extends StatelessWidget {
  const CutCornerSheet({
    super.key,
    this.header,
    this.title,
    this.titleWidget,
    this.body,
    this.footer,
    this.panelKey,
    this.padding = EdgeInsets.zero,
    this.headerPadding,
    this.titlePadding,
    this.bodyPadding,
    this.footerPadding,
    this.sectionSpacing = 16,
    this.titleTextAlign = TextAlign.start,
    this.titleStyle,
    this.maxHeightFactor = 0.9,
    this.backgroundColor,
    this.gradient,
    this.borderSide = BorderSide.none,
    this.elevation = 0,
    this.shadowColor,
    this.corners = const {CutCornerPosition.topRight},
    this.cutSize,
    this.cutWidth,
    this.cutHeight,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(
         title == null || titleWidget == null,
         'title 与 titleWidget 不能同时设置。',
       ),
       assert(sectionSpacing >= 0, 'sectionSpacing 不能小于 0。'),
       assert(
         maxHeightFactor > 0 && maxHeightFactor <= 1,
         'maxHeightFactor 必须大于 0 且不超过 1。',
       );

  /// 最顶部的自定义插槽，默认不展示，可放置拖拽条、图标或标签。
  final Widget? header;

  /// 内置标题文本；为空时不展示标题。
  final String? title;

  /// 完全自定义的标题插槽，设置后覆盖内置 [title]。
  final Widget? titleWidget;

  /// 位于标题之后的正文插槽；调用方自行决定是否使用滚动组件。
  final Widget? body;

  /// 位于最底部的操作区插槽。
  final Widget? footer;

  /// 赋予内部斜切面板的 Key，便于测试或定位。
  final Key? panelKey;

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

  /// Sheet 最大高度占屏幕高度的比例，默认不超过 90%。
  final double maxHeightFactor;

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

  /// 需要斜切的角集合，默认仅斜切右上角。
  final Set<CutCornerPosition> corners;

  /// 水平和垂直方向共用的切角尺寸。
  final double? cutSize;

  /// 切角的水平延伸长度，优先级高于 [cutSize]。
  final double? cutWidth;

  /// 切角的垂直延伸长度，优先级高于 [cutSize]。
  final double? cutHeight;

  /// 是否将内部内容裁剪到斜切形状内。
  final Clip clipBehavior;

  /// 构建内置标题；[titleWidget] 负责承载复杂标题内容。
  Widget? _buildTitle(BuildContext context) {
    final customTitle = titleWidget;
    if (customTitle != null) return customTitle;

    final text = title;
    if (text == null) return null;

    final baseStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: titleTextAlign,
        style: baseStyle?.merge(titleStyle) ?? titleStyle,
      ),
    );
  }

  /// 依次添加存在的插槽，仅让正文在高度不足时收缩到可用空间内。
  List<Widget> _buildStructuredChildren(BuildContext context) {
    final builtTitle = _buildTitle(context);
    final sections =
        <({Widget child, EdgeInsetsGeometry? padding, bool flexible})>[
          if (header != null)
            (child: header!, padding: headerPadding, flexible: false),
          if (builtTitle != null)
            (child: builtTitle, padding: titlePadding, flexible: false),
          if (body != null)
            (child: body!, padding: bodyPadding, flexible: true),
          if (footer != null)
            (child: footer!, padding: footerPadding, flexible: false),
        ];

    final children = <Widget>[];
    for (final section in sections) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: sectionSpacing));
      }
      final paddedChild = Padding(
        padding: section.padding ?? padding,
        child: section.child,
      );
      children.add(
        section.flexible
            ? Flexible(fit: FlexFit.loose, child: paddedChild)
            : paddedChild,
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSideSheet = SideSheetScope.of(context);
    final panel = MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: CutCornerPanel(
        panelKey: panelKey,
        corners: isSideSheet ? const {CutCornerPosition.topLeft} : corners,
        cutSize: cutSize ?? (isSideSheet ? 18 : null),
        cutWidth: cutWidth,
        cutHeight: cutHeight,
        backgroundColor: backgroundColor,
        gradient: gradient,
        borderSide: borderSide,
        elevation: elevation,
        shadowColor: shadowColor,
        clipBehavior: clipBehavior,
        child: SafeArea(
          top: isSideSheet,
          // 侧栏贴右缘且不触及屏幕左缘，左侧挖孔安全区与它无关，叠加只会把内容推远。
          left: !isSideSheet,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  mediaQuery.size.height * (isSideSheet ? 1 : maxHeightFactor),
            ),
            child: Column(
              mainAxisSize: isSideSheet ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildStructuredChildren(context),
            ),
          ),
        ),
      ),
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: panel,
    );
  }
}
