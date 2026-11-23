import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../themes/colors.dart';

class IndicatorButton extends StatelessWidget {
  const IndicatorButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        fontSize: 12.sp,
        height: 1,
        leadingDistribution: TextLeadingDistribution.even,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected
            ? AppColors.textPrimary(context)
            : AppColors.textSecondary(context),
      ),
    );
    double width(FontWeight weight) => TextPainter.computeWidth(
      text: TextSpan(
        text: label,
        style: style.copyWith(fontWeight: weight),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    );
    // 两种字重共用同一宽度，切换选中态时不挤动相邻指标。
    final labelWidth = math.max(width(FontWeight.w400), width(FontWeight.w600));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.only(right: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8),
        child: SizedBox(
          width: labelWidth,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ),
    );
  }
}
