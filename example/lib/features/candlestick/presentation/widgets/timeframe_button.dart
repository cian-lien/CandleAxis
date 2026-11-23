import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/enums/timeframe.dart';
import '../../../../themes/colors.dart';
import 'timeframe_short_label.dart';

class TimeframeButton extends StatelessWidget {
  const TimeframeButton({
    super.key,
    this.compact = false,
    required this.timeframe,
    required this.isSelected,
    required this.onPressed,
  });

  final Timeframe timeframe;
  final bool compact;
  final bool isSelected;
  final VoidCallback onPressed;

  /// 横屏估算可见周期数量时的最小预留宽度。
  static const double compactWidth = 52;
  static const double regularWidth = 44;

  @override
  Widget build(BuildContext context) {
    // 选中态只靠加粗与深色文字区分，不再铺灰色胶囊底，节省横向空间。
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        width: compact ? null : regularWidth.w,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: (compact ? 4.0 : 4.h)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            timeframe.shortLabel(context),
            maxLines: 1,
            style: TextStyle(
              fontSize: (compact ? 12.0 : 12.sp),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected
                  ? AppColors.textPrimary(context)
                  : AppColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}
