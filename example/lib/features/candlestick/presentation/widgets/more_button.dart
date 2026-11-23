import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/enums/timeframe.dart';
import '../../../../l10n/l10n.dart' as app_l10n;
import '../../../../themes/colors.dart';
import 'timeframe_short_label.dart';

class MoreButton extends StatelessWidget {
  const MoreButton({
    super.key,
    this.compact = false,
    required this.isHighlighted,
    required this.selectedTimeframe,
    required this.onPressed,
    this.isExpanded = false,
  });

  final bool compact;
  final bool isHighlighted;
  final Timeframe? selectedTimeframe;
  final VoidCallback onPressed;

  /// 底部弹窗打开时为 true，箭头旋转 180° 朝上
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    // 选中了未外显的周期时显示该周期短标签，否则显示「更多」
    final displayText =
        selectedTimeframe?.shortLabel(context) ??
        app_l10n.S.of(context).commonMore;
    final contentColor = isHighlighted
        ? AppColors.textPrimary(context)
        : AppColors.textSecondary(context);

    // 与周期按钮一致：高亮只靠加粗与深色文字，不铺灰色胶囊底。
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (compact ? 0.0 : 7.w),
          vertical: (compact ? 6.0 : 6.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: compact
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Text(
              displayText,
              style: TextStyle(
                fontSize: (compact ? 12.0 : 12.sp),
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
                color: contentColor,
              ),
            ),
            SizedBox(width: (compact ? 2.0 : 2.w)),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: (compact ? 14.0 : 14.sp),
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
