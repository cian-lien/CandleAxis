import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/presentation/widgets/button/cut_corner_button.dart';
import '../../../../shared/presentation/widgets/dialog/cut_corner_dialog.dart';
import '../../../../themes/colors.dart';

/// 「画图已隐藏」确认弹窗的结果；取消或点遮罩关闭时弹窗返回 null。
typedef HiddenDrawingPromptResult = ({bool dontShowAgain});

/// 画图隐藏时选中绘图工具的确认弹窗，样式沿用权限引导弹窗。
///
/// 只有点「显示并继续」才返回结果，「不再提示」的勾选状态随结果带回，
/// 由调用方决定是否持久化（取消时不持久化）。[compact] 用于横屏，
/// 避免 ScreenUtil 按横屏宽度放大弹窗。
Future<HiddenDrawingPromptResult?> showHiddenDrawingPromptDialog(
  BuildContext context, {
  bool compact = false,
}) => showCutCornerDialog<HiddenDrawingPromptResult>(
  context,
  builder: (_) => _HiddenDrawingPromptDialog(compact: compact),
);

class _HiddenDrawingPromptDialog extends StatefulWidget {
  const _HiddenDrawingPromptDialog({required this.compact});

  final bool compact;

  @override
  State<_HiddenDrawingPromptDialog> createState() =>
      _HiddenDrawingPromptDialogState();
}

class _HiddenDrawingPromptDialogState
    extends State<_HiddenDrawingPromptDialog> {
  bool _dontShowAgain = false;

  double _w(double value) => widget.compact ? value : value.w;
  double _h(double value) => widget.compact ? value : value.h;
  double _sp(double value) => widget.compact ? value : value.sp;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return CutCornerDialog(
      panelKey: const Key('hidden-drawing-prompt'),
      insetPadding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: _w(320)),
      backgroundColor: AppColors.background(context),
      showCloseButton: false,
      title: l10n.chartDrawingHiddenPromptTitle,
      titleTextAlign: TextAlign.center,
      titlePadding: EdgeInsets.fromLTRB(_w(24), _h(24), _w(24), 0),
      titleStyle: TextStyle(
        fontSize: _sp(16),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary(context),
      ),
      bodyPadding: EdgeInsets.fromLTRB(_w(24), _h(12), _w(24), 0),
      body: Text(
        l10n.chartDrawingHiddenPromptBody,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: _sp(13),
          height: 1.4,
          color: AppColors.textSecondary(context),
        ),
      ),
      footer: _buildFooter(context, l10n),
      footerPadding: EdgeInsets.fromLTRB(_w(24), _h(24), _w(24), _h(24)),
      sectionSpacing: 0,
    );
  }

  Widget _buildFooter(BuildContext context, S l10n) {
    final buttonText = TextStyle(fontSize: _sp(14), fontWeight: .w500);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: CutCornerButton(
                key: const Key('hidden-drawing-prompt-cancel'),
                onPressed: () => Navigator.of(context).pop(),
                corners: const {ButtonCorner.topLeft},
                backgroundColor: AppColors.transparent,
                foregroundColor: AppColors.textSecondary(context),
                side: BorderSide(color: AppColors.border(context)),
                padding: EdgeInsets.symmetric(vertical: _h(11)),
                child: Text(
                  l10n.chartDrawingHiddenPromptCancel,
                  style: buttonText,
                ),
              ),
            ),
            SizedBox(width: _w(12)),
            Expanded(
              child: CutCornerButton(
                key: const Key('hidden-drawing-prompt-confirm'),
                onPressed: () =>
                    Navigator.of(context).pop<HiddenDrawingPromptResult>((
                      dontShowAgain: _dontShowAgain,
                    )),
                corners: const {ButtonCorner.topRight},
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: EdgeInsets.symmetric(vertical: _h(11)),
                child: Text(
                  l10n.chartDrawingHiddenPromptConfirm,
                  style: buttonText.copyWith(color: AppColors.onPrimary),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _h(10)),
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            key: const Key('hidden-drawing-prompt-dont-show-again'),
            onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _w(18),
                  height: _w(18),
                  child: Checkbox(
                    value: _dontShowAgain,
                    onChanged: (next) =>
                        setState(() => _dontShowAgain = next ?? false),
                    activeColor: AppColors.primary,
                    checkColor: AppColors.onPrimary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(
                      width: 1,
                      color: AppColors.textTertiary(context),
                    ),
                  ),
                ),
                SizedBox(width: _w(6)),
                Text(
                  l10n.chartDrawingHiddenPromptDontShowAgain,
                  style: TextStyle(
                    fontSize: _sp(12),
                    color: AppColors.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
