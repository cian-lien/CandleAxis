import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../themes/colors.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, this.onPressed, this.tooltip});

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.textScalerOf(context).scale(12.sp) + 16;
    return IconButton(
      key: const Key('indicator-settings-button'),
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(
        LucideIcons.chartNoAxesCombined,
        key: const Key('indicator-settings-icon'),
        size: 16.sp,
      ),
      iconSize: 16.sp,
      color: AppColors.textSecondary(context),
      style: IconButton.styleFrom(
        minimumSize: Size(36.w, height),
        fixedSize: Size(36.w, height),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      ),
    );
  }
}
