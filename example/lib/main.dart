import 'dart:async';

import 'package:candle_axis/candle_axis.dart' hide S;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_market.dart';
import 'features/candlestick/infrastructure/datasource/candlestick_settings_storage.dart';
import 'features/candlestick/infrastructure/datasource/drawing_storage.dart';
import 'features/candlestick/presentation/cubit/candlestick/candlestick_cubit.dart';
import 'features/candlestick/presentation/cubit/candlestick/candlestick_state.dart';
import 'features/candlestick/presentation/cubit/selection/selection_params_cubit.dart';
import 'features/candlestick/presentation/widgets/candlestick.dart';
import 'features/candlestick/presentation/widgets/candlestick_token_market_header.dart';
import 'features/token_detail/presentation/cubits/token_info/token_info_cubit.dart';
import 'infrastructure/di/service_locator.dart';
import 'l10n/l10n.dart';
import 'shared/presentation/widgets/avatar/widget/token.dart';
import 'themes/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final preferences = await SharedPreferences.getInstance();
  runApp(MyApp(preferences: preferences));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.preferences, this.autoplay = true});

  final SharedPreferences preferences;
  final bool autoplay;

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => MaterialApp(
      title: 'CandleAxis',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: child,
    ),
    child: CandlestickDemo(preferences: preferences, autoplay: autoplay),
  );

  ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF121212)
        : Colors.white,
  );
}

class CandlestickDemo extends StatefulWidget {
  const CandlestickDemo({
    super.key,
    required this.preferences,
    required this.autoplay,
  });

  final SharedPreferences preferences;
  final bool autoplay;

  @override
  State<CandlestickDemo> createState() => _CandlestickDemoState();
}

class _CandlestickDemoState extends State<CandlestickDemo> {
  late final CandlestickSettingsStorage _settings;
  late final DrawingStorage _drawings;
  late final SelectionParamsCubit _selection;
  late final CandlestickCubit _candles;
  final _token = TokenInfoCubit();
  late final StreamSubscription<CandlestickState> _quoteSubscription;
  bool _chartOwnsScroll = false;

  @override
  void initState() {
    super.initState();
    _settings = CandlestickSettingsStorage(widget.preferences);
    _drawings = DrawingStorage(widget.preferences);
    getIt.registerSingleton<CandlestickSettingsStorage>(_settings);
    getIt.registerSingleton<DrawingStorage>(_drawings);
    _selection = SelectionParamsCubit(_settings)
      ..updateToken(network: 'demo', address: 'btc-usd');
    _candles = CandlestickCubit(_selection, autoplay: widget.autoplay);
    _updateQuote(_candles.state);
    _quoteSubscription = _candles.stream.listen(_updateQuote);
  }

  void _updateQuote(CandlestickState state) {
    final candles = state.kLineEntities;
    final latest = candles.last;
    final timeframe = _selection.state.selectedTimeframe;
    final lookback =
        const Duration(days: 1).inSeconds ~/ timeframe.duration.inSeconds;
    final sample = candles.reversed.take(lookback.clamp(1, candles.length));
    final change = (latest.close / sample.last.open - 1) * 100;
    final volume = sample.fold(
      0.0,
      (sum, candle) => sum + (candle.amount ?? 0),
    );
    _token.update(price: latest.close, change: change, volume: volume);
  }

  @override
  void dispose() {
    unawaited(_quoteSubscription.cancel());
    unawaited(_candles.close());
    unawaited(_selection.close());
    unawaited(_token.close());
    getIt.unregister<DrawingStorage>(instance: _drawings);
    getIt.unregister<CandlestickSettingsStorage>(instance: _settings);
    super.dispose();
  }

  Future<void> _showQuickTrade(double price) async {
    final order = await showModalBottomSheet<(TradeMarkerSide, double)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _DemoLimitOrder(price: price),
    );
    if (!mounted || order == null) return;
    final (side, quantity) = order;
    final action = side == TradeMarkerSide.buy ? '模拟买入委托' : '模拟卖出委托';
    final summary = '$action · $quantity BTC · \$${price.toStringAsFixed(2)}';
    final saved = await widget.preferences
        .setStringList('candlex_demo_limit_orders', [
          summary,
          ...?widget.preferences
              .getStringList('candlex_demo_limit_orders')
              ?.take(19),
        ]);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(saved ? '已记录$summary' : '模拟委托保存失败')));
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<SelectionParamsCubit>.value(value: _selection),
      BlocProvider<CandlestickCubit>.value(value: _candles),
      BlocProvider<TokenInfoCubit>.value(value: _token),
    ],
    child: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: _chartOwnsScroll
              ? const NeverScrollableScrollPhysics()
              : null,
          child: BlocBuilder<CandlestickCubit, CandlestickState>(
            builder: (context, state) {
              final trades = state.trades;
              return Column(
                children: [
                  CandlestickTokenMarketHeader(
                    symbol: 'BTC',
                    latestPrice: state.kLineEntities.last.close,
                    actions: const [],
                    identity: const Row(
                      children: [
                        AvatarToken(
                          tokenName: 'BTC',
                          forceAvatarProxy: false,
                          width: 24,
                          height: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'BTC / USD',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('模拟行情', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  AIGunCandlestick(
                    settingsStorage: _settings,
                    tokenSymbol: 'BTC',
                    mcapFactor: DemoMarket.marketCapFactor,
                    tradeMarkers: trades,
                    avgBuyPrice: _average(trades, TradeMarkerSide.buy),
                    avgSellPrice: _average(trades, TradeMarkerSide.sell),
                    onCrosshairQuickTrade: _showQuickTrade,
                    onGestureStateChanged: (state) {
                      final own =
                          state == ChartGestureState.horizontalDragging ||
                          state == ChartGestureState.scaling;
                      if (mounted && own != _chartOwnsScroll) {
                        setState(() => _chartOwnsScroll = own);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  double? _average(List<TradeMarkerEntity> trades, TradeMarkerSide side) {
    var amount = 0.0;
    var value = 0.0;
    for (final trade in trades.where((trade) => trade.side == side)) {
      final size = double.parse(trade.amount);
      amount += size;
      value += trade.price * size;
    }
    return amount == 0 ? null : value / amount;
  }
}

class _DemoLimitOrder extends StatefulWidget {
  const _DemoLimitOrder({required this.price});

  final double price;

  @override
  State<_DemoLimitOrder> createState() => _DemoLimitOrderState();
}

class _DemoLimitOrderState extends State<_DemoLimitOrder> {
  TradeMarkerSide _side = TradeMarkerSide.buy;
  double? _amount = .01;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.viewInsetsOf(context).bottom +
          MediaQuery.viewPaddingOf(context).bottom +
          16,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('模拟限价单', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<TradeMarkerSide>(
          segments: const [
            ButtonSegment(value: TradeMarkerSide.buy, label: Text('买入')),
            ButtonSegment(value: TradeMarkerSide.sell, label: Text('卖出')),
          ],
          selected: {_side},
          onSelectionChanged: (values) => setState(() => _side = values.single),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: const InputDecoration(labelText: '限价 (USD)'),
          child: Text(widget.price.toStringAsFixed(2)),
        ),
        TextFormField(
          initialValue: '0.01',
          decoration: const InputDecoration(labelText: '数量 (BTC)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) =>
              setState(() => _amount = double.tryParse(value)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _amount != null && _amount!.isFinite && _amount! > 0
              ? () => Navigator.pop(context, (_side, _amount!))
              : null,
          child: const Text('提交模拟委托'),
        ),
      ],
    ),
  );
}
