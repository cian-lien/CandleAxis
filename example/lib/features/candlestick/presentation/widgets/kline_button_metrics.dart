import 'package:flutter/material.dart';

/// K 线所有工具 / 头部图标按钮共用的尺寸，以普通竖屏 K 线工具栏
/// （图表切换、画图入口、图表设置：6 内边距 + 16 图标）为基准。
/// 竖屏沿用基准，全屏图标略大，点击区保持一致。
abstract final class KlineButtonMetrics {
  /// 点击区边长。
  static const double tapTarget = 28;

  /// 图标边长。
  static const double iconSize = 16;

  /// Lucide 的 x / chevron 图形留白较大，用更大的字号匹配分享图标的视觉宽度。
  static const double compactGlyphSize = 22;

  /// 全屏工具图标与指标文字保持适度比例，关闭图标补偿图形留白。
  static const double landscapeIconSize = 18;
  static const double landscapeCloseIconSize = 22;
  static const double landscapePadding = (tapTarget - landscapeIconSize) / 2;

  /// 手势型按钮（GestureDetector + 内边距）用内边距撑出同样的点击区。
  static const double padding = (tapTarget - iconSize) / 2;

  /// IconButton 用正圆水波纹并固定为同一点击区。
  static final ButtonStyle circleStyle = IconButton.styleFrom(
    shape: const CircleBorder(),
    // M3 默认 minimumSize 为 40，会压过 fixedSize，需一并收紧。
    minimumSize: const Size.square(tapTarget),
    fixedSize: const Size.square(tapTarget),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
