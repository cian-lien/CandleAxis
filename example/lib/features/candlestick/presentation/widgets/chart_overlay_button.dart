import 'package:flutter/material.dart';

import '../../../../themes/colors.dart';

/// 主图内悬浮的小按钮（全屏、画图显隐、价格轴自动 A）：统一尺寸、半透明主题底色、
/// 圆角描边，不遮挡下方 K 线又能与图表区分开。图标或单字形二选一。
class ChartOverlayButton extends StatelessWidget {
  const ChartOverlayButton({
    super.key,
    this.icon,
    this.text,
    required this.label,
    required this.onTap,
  }) : assert((icon == null) != (text == null));

  static const double size = 28;
  static const double visualSize = 22;
  static const double iconSize = 13;
  static const double radius = 4;
  static const double textSize = 11;

  final IconData? icon;
  final String? text;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textSecondary(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 缩小可见外框，透明留白继续保留原有点击范围。
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Container(
              width: visualSize,
              height: visualSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: AppColors.border(context).withValues(alpha: 0.8),
                  width: 0.8,
                ),
              ),
              child: text == null
                  ? Icon(icon, size: iconSize, color: color)
                  : Text(
                      text!,
                      style: TextStyle(
                        color: color,
                        fontSize: textSize,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
