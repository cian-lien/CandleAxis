import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/formatting/number_format_core.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/presentation/widgets/avatar/widget/token.dart';
import '../../../../themes/colors.dart';
import '../../../../utils/format/number.dart';
import '../../../token_detail/presentation/cubits/token_info/token_info_cubit.dart';
import 'candlestick_token_address.dart';
import 'kline_button_metrics.dart';

/// Uses the detail session's live snapshot; crosshair candles are not 24h data.
class CandlestickTokenMarketHeader extends StatefulWidget {
  const CandlestickTokenMarketHeader({
    super.key,
    required this.symbol,
    required this.actions,
    this.compact = false,
    this.latestPrice,
    this.identity,
    this.statistics,
  });

  final String symbol;
  final List<Widget> actions;
  final bool compact;
  final double? latestPrice;
  final Widget? identity;
  final Widget? statistics;

  @override
  State<CandlestickTokenMarketHeader> createState() =>
      _CandlestickTokenMarketHeaderState();
}

class _CandlestickTokenMarketHeaderState
    extends State<CandlestickTokenMarketHeader> {
  bool _expanded = true;
  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TokenInfoCubit?>();
    if (cubit == null) return _header(context, null);
    return BlocBuilder<TokenInfoCubit, TokenInfoState>(
      bloc: cubit,
      buildWhen: (previous, current) =>
          previous.tokenInfo != current.tokenInfo ||
          previous.address != current.address,
      builder: _header,
    );
  }

  Decimal? _number(String? raw) {
    final value = Decimal.tryParse(raw?.trim() ?? '');
    return value == null || value < Decimal.zero ? null : value;
  }

  String _money(String? raw, String locale) {
    final value = _number(raw);
    return value == null
        ? '--'
        : NumberFormatCore.marketCap(value, locale: locale);
  }

  Widget _header(BuildContext context, TokenInfoState? state) {
    final l10n = S.of(context);
    final token = state?.tokenInfo;
    final compact = widget.compact;
    // Portrait keeps K/M/B in every language; the wider landscape row uses
    // the reader's own units (e.g. 万/亿 in Chinese).
    final locale = compact
        ? Localizations.localeOf(context).languageCode
        : 'en';
    final price = _number(token?.base.price ?? widget.latestPrice?.toString());
    final priceText = price == null ? '--' : '\$${formatAmount(price)}';
    final capText = _money(token?.base.marketCap, locale);
    final change = Decimal.tryParse(
      token?.base.priceChange24h.trim().replaceAll('%', '') ?? '',
    );
    final color = change == null
        ? AppColors.textSecondary(context)
        : change >= Decimal.zero
        ? AppColors.riseGreen
        : AppColors.fallRed;
    final changeText = change == null
        ? '--'
        : '${change >= Decimal.zero ? '+' : ''}${change.toStringAsFixed(2)}%';
    final holders = _number(token?.hodlersValue);
    final liquidityText = _money(token?.base.liquidity, locale);
    final volumeText = _money(token?.base.volume24h, locale);
    // Holder counts are optional upstream; omit the cell rather than '--'.
    final holdersText = holders == null
        ? null
        : formatCompactAmount(holders, locale: locale);
    if (compact) {
      final tokenAddress = token?.base.address.trim() ?? '';
      final address = tokenAddress.isNotEmpty
          ? tokenAddress
          : (state?.address ?? '').trim();
      return _landscape(
        context,
        address,
        _priceWithChange(
          priceText,
          change == null ? null : changeText,
          color,
          context,
        ),
        [
          (l10n.marketCap, _value(capText, context), 2),
          (l10n.volume24h, _value(volumeText, context), 2),
          (l10n.liquidity, _value(liquidityText, context), 2),
          if (holdersText != null)
            (l10n.chartHolderCount, _value(holdersText, context), 2),
        ],
        avatar: token?.base.tokenLogo,
      );
    }
    final metrics = _metrics(context, [
      [(l10n.marketCap, capText), (l10n.liquidity, liquidityText)],
      [
        (l10n.volume24h, volumeText),
        if (holdersText != null) (l10n.chartHolderCount, holdersText),
      ],
    ]);
    // 头部只展示价格与涨跌幅，市值统一保留在下方指标网格。
    final quote = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          flex: 3,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              priceText,
              key: const Key('candlestick-header-primary-value'),
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
                height: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          changeText,
          maxLines: 1,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _duration;
    // 两行按钮使用同一右边距，让关闭与收起图标的可见右缘对齐。
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child:
                      widget.identity ??
                      Text(
                        widget.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                ),
                const SizedBox(width: 8),
                ...widget.actions,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 36,
              child: Row(
                children: [
                  Expanded(child: quote),
                  _toggle(context, duration),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: widget.statistics != null || _expanded
                ? Padding(
                    key: const Key(
                      'candlestick-portrait-fullscreen-market-data',
                    ),
                    padding: const EdgeInsets.only(top: 4, right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [if (_expanded) metrics, ?widget.statistics],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  /// 与上方关闭按钮共用点击区和光学校正尺寸。
  Widget _toggle(BuildContext context, Duration duration) {
    final l10n = S.of(context);
    return Semantics(
      expanded: _expanded,
      child: IconButton(
        key: const Key('candlestick-toggle-market-data'),
        tooltip: _expanded ? l10n.collapse : l10n.expand,
        style: KlineButtonMetrics.circleStyle,
        onPressed: () => setState(() => _expanded = !_expanded),
        icon: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SizedBox.square(
            dimension: KlineButtonMetrics.compactGlyphSize,
            child: AnimatedRotation(
              turns: _expanded ? 0 : .5,
              duration: duration,
              child: Icon(
                LucideIcons.chevronUp,
                size: KlineButtonMetrics.compactGlyphSize,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 横屏左侧为名称、地址和价格，右侧为标签在上的行情指标。
  Widget _landscape(
    BuildContext context,
    String address,
    Widget price,
    List<(String, Widget, int)> stats, {
    String? avatar,
  }) {
    final labelStyle = TextStyle(
      fontSize: 11,
      height: 1.3,
      color: AppColors.textTertiary(context),
    );
    // 高度至少与区间统计头部一致，大字体可自然撑高。
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          // Keep the trailing action flush with the landscape drawing rail.
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 184,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AvatarToken(
                                avatar: avatar,
                                tokenName: widget.symbol,
                                forceAvatarProxy: true,
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.symbol,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                              if (address.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: CandlestickTokenAddress(
                                    address: address,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: price,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        key: const Key('candlestick-token-metrics'),
                        // 缩放后的数值也与左侧价格共享底边。
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final (index, (label, value, flex))
                              in stats.indexed) ...[
                            if (index > 0) const SizedBox(width: 12),
                            Expanded(
                              flex: flex,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: labelStyle,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: value,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ...widget.actions,
            ],
          ),
        ),
        if (widget.statistics case final statistics?)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 16),
            child: statistics,
          ),
      ],
    );
  }

  TextStyle _valueStyle(BuildContext context) => TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary(context),
  );

  Widget _value(String text, BuildContext context) =>
      Text(text, maxLines: 1, style: _valueStyle(context));

  Widget _priceWithChange(
    String price,
    String? change,
    Color color,
    BuildContext context,
  ) {
    if (change == null) return _value(price, context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        _value(price, context),
        const SizedBox(width: 4),
        Text(
          change,
          maxLines: 1,
          style: _valueStyle(context).copyWith(color: color),
        ),
      ],
    );
  }

  /// Portrait 2x2 label/value grid: muted label on the left, value flush right.
  Widget _metrics(BuildContext context, List<List<(String, String)>> groups) {
    final labelStyle = TextStyle(
      fontSize: 13,
      height: 1.5,
      color: AppColors.textTertiary(context),
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary(context),
    );
    return Row(
      key: const Key('candlestick-token-metrics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, column) in groups.indexed) ...[
          if (index > 0) const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in column)
                  _metric(item, labelStyle, valueStyle),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _metric(
    (String, String) item,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: item.$1,
            child: Text(
              item.$1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.$2,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: valueStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
