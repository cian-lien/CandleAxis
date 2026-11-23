import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../../themes/colors.dart';
import '../../../../utils/clipboard.dart';
import '../../../../utils/extensions/string.dart';
import '../../../../utils/toast.dart';
import 'kline_button_metrics.dart';

/// 横屏头部地址与图标均可复制完整合约地址。
class CandlestickTokenAddress extends StatefulWidget {
  const CandlestickTokenAddress({super.key, required this.address});

  final String address;

  @override
  State<CandlestickTokenAddress> createState() =>
      _CandlestickTokenAddressState();
}

class _CandlestickTokenAddressState extends State<CandlestickTokenAddress> {
  Timer? _resetTimer;
  bool _copied = false;

  Future<void> _copy() async {
    final address = widget.address;
    await ClipboardUtils.copy(address);
    if (!mounted || widget.address != address) return;
    _resetTimer?.cancel();
    setState(() => _copied = true);
    _resetTimer = Timer(const Duration(seconds: 2), () {
      setState(() => _copied = false);
    });
    ToastUtils.showCenterToast(context, S.of(context).copied);
  }

  @override
  void didUpdateWidget(CandlestickTokenAddress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _resetTimer?.cancel();
      _copied = false;
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: TextButton(
          key: const Key('candlestick-landscape-token-address'),
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
            minimumSize: const Size(0, KlineButtonMetrics.tapTarget),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _copy,
          child: Text(
            widget.address.splitStartAndEnd(4, 4, separator: '…'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary(context),
            ),
          ),
        ),
      ),
      IconButton(
        key: const Key('candlestick-landscape-copy-address'),
        style: KlineButtonMetrics.circleStyle,
        tooltip: _copied ? S.of(context).copied : S.of(context).copy,
        onPressed: _copy,
        icon: Icon(
          _copied ? LucideIcons.check : LucideIcons.copy,
          size: 12,
          color: _copied
              ? AppColors.riseGreen
              : AppColors.textSecondary(context),
        ),
      ),
    ],
  );
}
