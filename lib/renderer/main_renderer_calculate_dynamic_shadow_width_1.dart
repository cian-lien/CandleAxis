part of 'main_renderer.dart';

extension _MainRendererCalculateDynamicShadowWidth1 on MainRenderer {
  /// 计算动态影线宽度
  /// 根据当前缩放级别 (scaleX) 平滑调整影线宽度
  /// 当缩放到最小时，影线宽度逐渐增加至与实体宽度相同
  ///
  /// 算法说明：
  /// 1. 如果未启用动态调整，返回默认影线宽度
  /// 2. 如果 scaleX > 过渡起点，返回默认影线宽度（无需调整）
  /// 3. 如果 scaleX < 过渡终点，返回实体宽度（完全过渡）
  /// 4. 否则，在过渡区间内进行线性插值
  ///
  /// 返回值：当前应该使用的影线宽度
  double _calculateDynamicShadowWidth() {
    // 功能未启用时，使用默认宽度
    if (!chartStyle.enableDynamicShadowWidth) {
      return mCandleLineWidth;
    }

    final start = chartStyle.shadowWidthTransitionStart;
    final end = chartStyle.shadowWidthTransitionEnd;

    // 缩放级别高于过渡起点，使用默认影线宽度
    if (scaleX >= start) {
      return mCandleLineWidth;
    }

    // 缩放级别低于过渡终点，影线宽度等于实体宽度
    if (scaleX <= end) {
      return mCandleWidth;
    }

    // 在过渡区间内，线性插值计算影线宽度
    // progress: 0.0 (在起点) -> 1.0 (在终点)
    final progress = (start - scaleX) / (start - end);

    // 从默认影线宽度平滑过渡到实体宽度
    return mCandleLineWidth + (mCandleWidth - mCandleLineWidth) * progress;
  }
}
