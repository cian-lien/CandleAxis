import 'package:candle_axis/candle_axis.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder keyed(String key) => find.byKey(Key(key));
Finder get chartFinder => find.byType(CandlestickWidget).hitTestable();
CandlestickWidget chart(WidgetTester tester) => tester.widget(chartFinder);

Future<SharedPreferences> start(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 874);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MyApp(preferences: prefs, autoplay: false));
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  testWidgets('mobile chart switches intervals, indicators and trade display', (
    tester,
  ) async {
    final prefs = await start(tester);
    final candles = chart(tester).datas!;
    expect(candles[1].time! - candles.first.time!, 5 * 60 * 1000);
    expect(chart(tester).tradeMarkers, isNotEmpty);

    await tester.ensureVisible(find.text('更多'));
    await tester.tap(find.text('更多'));
    await tester.pumpAndSettle();
    final interval = keyed('timeframe-grid-item-m15');
    await tester.ensureVisible(interval);
    await tester.tap(interval);
    await tester.pumpAndSettle();
    final changed = chart(tester).datas!;
    expect(changed[1].time! - changed.first.time!, 15 * 60 * 1000);

    await tester.tap(keyed('indicator-settings-button'));
    await tester.pumpAndSettle();
    for (final label in ['EMA', 'MACD', 'RSI']) {
      final item = keyed('indicator-option-$label');
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();
    }
    await tester.tap(keyed('indicator-settings-save'));
    await tester.pumpAndSettle();
    expect(chart(tester).mainStateLi, {MainState.EMA});
    expect(chart(tester).secondaryStateLi, {
      SecondaryState.MACD,
      SecondaryState.RSI,
    });

    await tester.tap(keyed('candlestick-chart-settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('价格').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CandlestickWidget>(find.byType(CandlestickWidget))
          .valueType,
      ChartValueType.price,
    );
    await tester.tap(find.text('交易展示'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CandlestickWidget>(find.byType(CandlestickWidget))
          .showTradeMarkers,
      isFalse,
    );
    Navigator.of(tester.element(find.byType(Switch).first)).pop();
    await tester.pumpAndSettle();

    await tester.tap(keyed('candlestick-type-toggle'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(chart(tester).isLine, isTrue);
    await tester.tap(keyed('candlestick-type-toggle'));
    await tester.pumpAndSettle();

    final origin = tester.getTopLeft(chartFinder);
    await tester.tapAt(origin + const Offset(150, 90));
    await tester.pumpAndSettle();
    expect(find.text('开盘'), findsOneWidget);
    chart(tester).onCrosshairQuickTrade!(68000);
    await tester.pumpAndSettle();
    expect(find.text('模拟限价单'), findsOneWidget);
    await tester.tap(find.text('提交模拟委托'));
    await tester.pumpAndSettle();
    expect(
      prefs.getStringList('candlex_demo_limit_orders')!.single,
      contains('68000.00'),
    );
    expect(prefs.getString('candlestick_settings_v1'), contains('"m15"'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait and landscape fullscreen share saved drawings', (
    tester,
  ) async {
    final prefs = await start(tester);
    await tester.tap(keyed('candlestick-chart-settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Switch))).pop();
    await tester.pumpAndSettle();

    await tester.tap(keyed('candlestick-fullscreen'));
    await tester.pumpAndSettle();
    expect(keyed('portrait-fullscreen-candlestick-page'), findsOneWidget);
    expect(keyed('candlestick-portrait-drawing-tools'), findsOneWidget);
    final fullChart = find.descendant(
      of: keyed('portrait-fullscreen-candlestick-page'),
      matching: find.byType(CandlestickWidget),
    );
    final controller = tester
        .widget<CandlestickWidget>(fullChart)
        .drawingController!;
    controller.selectTool(DrawingTool.trendLine);
    await tester.pump();
    final origin = tester.getTopLeft(fullChart);
    await tester.tapAt(origin + const Offset(100, 90));
    await tester.pump();
    await tester.tapAt(origin + const Offset(220, 150));
    await tester.pumpAndSettle();
    expect(controller.completedObjects.single.tool, DrawingTool.trendLine);
    expect(
      prefs.getKeys().where((key) => key.startsWith('candlestick_drawings_')),
      isNotEmpty,
    );

    await tester.tap(keyed('candlestick-switch-to-landscape'));
    await tester.pump(const Duration(milliseconds: 250));
    tester.view.physicalSize = const Size(874, 402);
    await tester.pumpAndSettle();
    expect(keyed('landscape-candlestick-page'), findsOneWidget);
    expect(keyed('candlestick-landscape-tools'), findsOneWidget);
    final horizontalChart = find.descendant(
      of: keyed('landscape-candlestick-page'),
      matching: find.byType(CandlestickWidget),
    );
    expect(
      tester
          .widget<CandlestickWidget>(horizontalChart)
          .drawingController!
          .completedObjects
          .single
          .tool,
      DrawingTool.trendLine,
    );
    await tester.tap(keyed('candlestick-close-fullscreen'));
    await tester.pump();
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpAndSettle();
    expect(keyed('landscape-candlestick-page'), findsNothing);
    expect(chart(tester).drawingController!.completedObjects, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
