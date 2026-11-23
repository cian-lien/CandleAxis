import 'package:flutter/material.dart';

import '../../../../themes/colors.dart';

/// 可被斜切的按钮角。
enum ButtonCorner { topLeft, topRight, bottomLeft, bottomRight }

/// 一个支持自定义斜切（chamfer）的可复用按钮。
///
/// 设计要点：
/// - [corners] 指定需要斜切的角（可多选），默认仅右上角。
/// - [cutWidth] / [cutHeight] 分别控制切角在水平、垂直方向的延伸长度，二者相等
///   即为 45° 斜切，不等则形成任意角度的直线斜切；[cutSize] 是同时设置二者的
///   便捷参数，仅在未单独指定时生效。
/// - 切角通过 [BeveledRectangleBorder] + [Radius.elliptical] 实现，因此 Material
///   水波纹与（未来可能的）描边都会自然贴合切角，无需额外 ClipPath。
/// - 支持 [leading] / [suffix] 两个图标槽与 [gap] 间距。
///
/// ## 三态外观（enabled / loading / disabled）
///
/// 按钮区分三种并列的视觉状态，优先级 `loading > disabled > enabled`：
/// - **loading**：[isLoading] 为 true；
/// - **disabled**：非 loading 且 [onPressed] 为 null；
/// - **enabled**：其余情况。
///
/// 每个状态都可独立指定文字（[child] / [loadingChild] / [disabledChild]）、背景
/// （纯色或渐变）与前景色。任一项未显式指定时**回退到启用态**对应值，因此仅传
/// [child] + 基础颜色的调用方与旧行为完全一致（loading 显示启用态底色 + spinner）
///
/// 颜色默认走主题（[AppColors.primary] / [AppColors.black]）
///
/// 背景填充在**单个状态内** color 与 gradient 互斥（见构造断言），但允许跨状态
/// 混用——例如 enabled 用 [gradient]、disabled 用纯色 [disabledBackgroundColor]
///
/// 实现说明：状态由构造参数（[isLoading] / [onPressed]）决定，其变化必然触发
/// rebuild，因此 [build] 直接判定当前状态并只解析该状态的一套值，无需依赖
/// [WidgetStateProperty]（它无法区分 loading 与 disabled，二者都表现为
/// [WidgetState.disabled]）
class CutCornerButton extends StatelessWidget {
  const CutCornerButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.corners = const {ButtonCorner.topRight},
    this.cutSize = 12.0,
    this.cutWidth,
    this.cutHeight,
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.side = BorderSide.none,
    this.loadingChild,
    this.loadingBackgroundColor,
    this.loadingForegroundColor,
    this.loadingGradient,
    this.disabledChild,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.disabledGradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.leading,
    this.suffix,
    this.gap = 8.0,
    this.isLoading = false,
    this.loadingIndicator,
    this.textStyle,
    this.minimumSize,
    this.tapTargetSize,
  }) : assert(
         backgroundColor == null || gradient == null,
         'backgroundColor 与 gradient 互斥,请只设置其一(gradient 优先)。',
       ),
       assert(
         loadingBackgroundColor == null || loadingGradient == null,
         'loadingBackgroundColor 与 loadingGradient 互斥,请只设置其一。',
       ),
       assert(
         disabledBackgroundColor == null || disabledGradient == null,
         'disabledBackgroundColor 与 disabledGradient 互斥,请只设置其一。',
       );

  /// 启用态按钮内容（通常是一段 [Text]，自带文字样式）；也是其余状态未指定内容
  /// 时的兜底。
  final Widget child;

  /// 点击回调。为 null 或 [isLoading] 为 true 时按钮处于禁用状态。
  final VoidCallback? onPressed;

  /// 需要斜切的角集合，默认仅右上角。
  final Set<ButtonCorner> corners;

  /// 切角的便捷尺寸：未单独指定 [cutWidth] / [cutHeight] 时，水平与垂直方向均
  /// 采用该值（即 45° 斜切）。
  final double cutSize;

  /// 切角的水平延伸长度（覆盖 [cutSize]），与 [cutHeight] 共同决定切角角度。
  final double? cutWidth;

  /// 切角的垂直延伸长度（覆盖 [cutSize]）。
  final double? cutHeight;

  final Color? backgroundColor;

  /// 渐变背景。设置后与 [backgroundColor] 互斥(见构造断言),优先级更高:此时底色
  /// 让位为透明,渐变通过 [ElevatedButton] 的 backgroundBuilder 注入,因而会被
  /// Material 自动裁剪到切角形状,水波纹仍叠加在其上。
  final Gradient? gradient;

  final Color? foregroundColor;

  /// 按钮描边；次要操作可配合透明背景使用。
  final BorderSide side;

  /// 加载态文字，默认回退到 [child]。
  final Widget? loadingChild;

  /// 加载态背景色，默认回退到启用态背景。
  final Color? loadingBackgroundColor;

  /// 加载态前景色，默认回退到 [foregroundColor]。
  final Color? loadingForegroundColor;

  /// 加载态渐变背景，与 [loadingBackgroundColor] 互斥。
  final Gradient? loadingGradient;

  /// 禁用态文字，默认回退到 [child]。
  final Widget? disabledChild;

  /// 禁用态背景色，默认回退到启用态背景。
  final Color? disabledBackgroundColor;

  /// 禁用态前景色，默认回退到 [foregroundColor]。
  final Color? disabledForegroundColor;

  /// 禁用态渐变背景，与 [disabledBackgroundColor] 互斥。
  final Gradient? disabledGradient;

  final EdgeInsetsGeometry? padding;

  /// 前置图标槽。
  final Widget? leading;

  /// 后置图标槽。
  final Widget? suffix;

  /// [leading] / [suffix] / 加载指示器与内容之间的间距。
  final double gap;

  /// 加载态：在内容之后追加指示器并禁用点击。
  final bool isLoading;

  /// 自定义加载指示器，默认使用前景色描绘的小号 [CircularProgressIndicator]。
  final Widget? loadingIndicator;

  /// 可选的统一文字样式；为空时由 [child] 自带样式决定。
  final TextStyle? textStyle;

  final Size? minimumSize;
  final MaterialTapTargetSize? tapTargetSize;

  /// 依据 [corners] 与切角尺寸构造斜切用的 [BorderRadius]。
  BorderRadius _buildBorderRadius() {
    final radius = Radius.elliptical(cutWidth ?? cutSize, cutHeight ?? cutSize);
    Radius radiusFor(ButtonCorner corner) =>
        corners.contains(corner) ? radius : Radius.zero;
    return BorderRadius.only(
      topLeft: radiusFor(ButtonCorner.topLeft),
      topRight: radiusFor(ButtonCorner.topRight),
      bottomLeft: radiusFor(ButtonCorner.bottomLeft),
      bottomRight: radiusFor(ButtonCorner.bottomRight),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 先判定当前视觉状态：loading > disabled > enabled。状态由构造参数决定，
    // 其变化必然触发 rebuild，因此这里只需解析「当前状态」的一套值。
    final isDisabled = !isLoading && onPressed == null;

    // 启用态基准值（也是其余状态未指定时的兜底）。
    final baseForeground = foregroundColor ?? AppColors.foreground(context);
    final baseGradient = gradient;
    final baseColor = backgroundColor;

    // 逐状态解析前景色，回退到启用态。
    final foreground = isLoading
        ? (loadingForegroundColor ?? baseForeground)
        : isDisabled
        ? (disabledForegroundColor ?? baseForeground)
        : baseForeground;

    // 逐状态解析背景填充（渐变优先于纯色）；该状态两者都未设时回退启用态填充。
    Gradient? resolvedGradient;
    Color? resolvedColor;
    if (isLoading &&
        (loadingGradient != null || loadingBackgroundColor != null)) {
      resolvedGradient = loadingGradient;
      resolvedColor = loadingBackgroundColor;
    } else if (isDisabled &&
        (disabledGradient != null || disabledBackgroundColor != null)) {
      resolvedGradient = disabledGradient;
      resolvedColor = disabledBackgroundColor;
    } else {
      resolvedGradient = baseGradient;
      resolvedColor = baseColor;
    }
    final hasGradient = resolvedGradient != null;
    // 纯色兜底到主题主色（保持渐变优先、纯色路径 backgroundBuilder 为空的行为）。
    final fillColor = hasGradient
        ? Colors.transparent
        : (resolvedColor ?? AppColors.primary);

    // 逐状态解析文字内容，回退到 [child]。
    final content = isLoading
        ? (loadingChild ?? child)
        : isDisabled
        ? (disabledChild ?? child)
        : child;

    // styleFrom 会把 elevation 展开为 pressed: elevation + 6，导致按住时出现
    // 投影，因此这里用 copyWith 把所有状态（含按压/悬停/聚焦）的 elevation
    // 固定为 0，保持完全扁平的外观。
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        // 把同一解析值同时喂给 enabled / disabled 槽，让上面的三态判定「压过」
        // ElevatedButton 的状态机（loading 与 disabled 都表现为 disabled 槽，
        // 无法靠 WidgetState 区分）。
        backgroundColor: fillColor,
        foregroundColor: foreground,
        disabledBackgroundColor: fillColor,
        disabledForegroundColor: foreground,
        // 扁平外观，切角效果由 shape 提供。
        elevation: 0,
        // 关闭按压/悬停/聚焦的墨水叠加层，避免按住时出现阴影。
        overlayColor: Colors.transparent,
        padding: padding,
        textStyle: textStyle,
        minimumSize: minimumSize,
        tapTargetSize: tapTargetSize,
        shape: BeveledRectangleBorder(
          side: side,
          borderRadius: _buildBorderRadius(),
        ),
        // 渐变注入点：backgroundBuilder 返回的层会被 Material 自动裁剪到上面的
        // BeveledRectangleBorder 切角；纯色路径下为 null，行为完全不变。
        backgroundBuilder: hasGradient
            ? (context, states, child) => DecoratedBox(
                decoration: BoxDecoration(gradient: resolvedGradient),
                child: child,
              )
            : null,
      ).copyWith(
        elevation: const WidgetStatePropertyAll<double>(0),
        shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      child: Row(
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: gap)],
          Flexible(child: content),
          if (suffix != null) ...[SizedBox(width: gap), suffix!],
          if (isLoading) ...[
            SizedBox(width: gap),
            loadingIndicator ??
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
