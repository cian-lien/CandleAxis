import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/sheet/sheet_presentation.dart';
import '../../../../themes/colors.dart';

/// A shared title whose arrow, spacing and text use the same one-level return.
class ChartSettingsSheetHeader extends StatelessWidget {
  const ChartSettingsSheetHeader({
    super.key,
    required this.title,
    this.onBack,
    this.textStyle,
    this.iconSize,
    this.spacing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String title;
  final VoidCallback? onBack;
  final TextStyle? textStyle;
  final double? iconSize;
  final double? spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (onBack != null) ...[
          Icon(
            Icons.arrow_back_ios_new,
            size: iconSize ?? 18.sheetSp(context),
            color: AppColors.textPrimary(context),
          ),
          SizedBox(width: spacing ?? 12.sheetW(context)),
        ],
        Expanded(
          child: Text(
            title,
            style:
                textStyle ??
                TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 18.sheetSp(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
    if (onBack == null) return header;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onBack,
        child: header,
      ),
    );
  }
}
