import 'dart:math';

import 'package:flutter/material.dart';
import 'package:candlestick/candlestick.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candlestick Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CandlestickDemo(),
    );
  }
}

class CandlestickDemo extends StatefulWidget {
  const CandlestickDemo({super.key});

  @override
  State<CandlestickDemo> createState() => _CandlestickDemoState();
}

class _CandlestickDemoState extends State<CandlestickDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<KLineEntity>? _kLineData;
  bool _isLine = false;
  Set<MainState> _mainState = {MainState.MA};
  Set<SecondaryState> _secondaryState = {SecondaryState.MACD};
  bool _volHidden = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateMockData() {
    final random = Random();
    final List<KLineEntity> data = [];

    double basePrice = 100.0;
    final now = DateTime.now();

    for (int i = 0; i < 200; i++) {
      final date = now.subtract(Duration(days: 200 - i));
      final timestamp = date.millisecondsSinceEpoch;

      // 生成随机价格波动
      final change = (random.nextDouble() - 0.5) * 5;
      basePrice = basePrice + change;
      if (basePrice < 10) basePrice = 10;

      final open = basePrice + (random.nextDouble() - 0.5) * 2;
      final close = basePrice + (random.nextDouble() - 0.5) * 2;
      final high = max(open, close) + random.nextDouble() * 2;
      final low = min(open, close) - random.nextDouble() * 2;
      final vol = 1000000 + random.nextDouble() * 5000000;

      data.add(
        KLineEntity.fromCustom(
          time: timestamp,
          open: open,
          close: close,
          high: high,
          low: low,
          vol: vol,
          amount: vol * close,
        ),
      );
    }

    // 计算技术指标
    DataUtil.calculate(data);

    setState(() {
      _kLineData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('K线图示例'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'K线图'),
            Tab(text: '空白页'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildKLineTab(), _buildEmptyTab()],
      ),
    );
  }

  Widget _buildKLineTab() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: _kLineData == null
              ? const Center(child: CircularProgressIndicator())
              : CandlestickWidget(
                  _kLineData,
                  ChartStyle(),
                  ChartColors(),
                  // onReachBoundary: (isLeft) {
                  //   _tabController.animateTo(1);
                  // },
                  isTrendLine: false,
                  isLine: _isLine,
                  mainStateLi: _mainState,
                  secondaryStateLi: _secondaryState,
                  volHidden: _volHidden,
                  showNowPrice: true,
                  isTapShowInfoDialog: true,
                  mBaseHeight: 400,
                  timeFormat: TimeFormat.YEAR_MONTH_DAY,
                  onLoadMore: (isLeft) {
                    debugPrint('加载更多数据: isLeft=$isLeft');
                    if (isLeft) {
                      _tabController.animateTo(1);
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyTab() {
    return const Center(
      child: Text('空白页面', style: TextStyle(fontSize: 24, color: Colors.grey)),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToggleButton(
              label: _isLine ? '分时' : 'K线',
              onPressed: () => setState(() => _isLine = !_isLine),
            ),
            const SizedBox(width: 8),
            _buildToggleButton(
              label: 'MA',
              isSelected: _mainState.contains(MainState.MA),
              onPressed: () => setState(() {
                if (_mainState.contains(MainState.MA)) {
                  _mainState.remove(MainState.MA);
                } else {
                  _mainState.add(MainState.MA);
                }
                _mainState = Set.from(_mainState);
              }),
            ),
            const SizedBox(width: 8),
            _buildToggleButton(
              label: 'BOLL',
              isSelected: _mainState.contains(MainState.BOLL),
              onPressed: () => setState(() {
                if (_mainState.contains(MainState.BOLL)) {
                  _mainState.remove(MainState.BOLL);
                } else {
                  _mainState.add(MainState.BOLL);
                }
                _mainState = Set.from(_mainState);
              }),
            ),
            const SizedBox(width: 8),
            _buildToggleButton(
              label: 'SAR',
              isSelected: _mainState.contains(MainState.SAR),
              onPressed: () => setState(() {
                if (_mainState.contains(MainState.SAR)) {
                  _mainState.remove(MainState.SAR);
                } else {
                  _mainState.add(MainState.SAR);
                }
                _mainState = Set.from(_mainState);
              }),
            ),
            const SizedBox(width: 16),
            _buildToggleButton(
              label: 'MACD',
              isSelected: _secondaryState.contains(SecondaryState.MACD),
              onPressed: () => setState(() {
                if (_secondaryState.contains(SecondaryState.MACD)) {
                  _secondaryState.remove(SecondaryState.MACD);
                } else {
                  _secondaryState.add(SecondaryState.MACD);
                }
                _secondaryState = Set.from(_secondaryState);
              }),
            ),
            const SizedBox(width: 8),
            _buildToggleButton(
              label: 'KDJ',
              isSelected: _secondaryState.contains(SecondaryState.KDJ),
              onPressed: () => setState(() {
                if (_secondaryState.contains(SecondaryState.KDJ)) {
                  _secondaryState.remove(SecondaryState.KDJ);
                } else {
                  _secondaryState.add(SecondaryState.KDJ);
                }
                _secondaryState = Set.from(_secondaryState);
              }),
            ),
            const SizedBox(width: 8),
            _buildToggleButton(
              label: 'RSI',
              isSelected: _secondaryState.contains(SecondaryState.RSI),
              onPressed: () => setState(() {
                if (_secondaryState.contains(SecondaryState.RSI)) {
                  _secondaryState.remove(SecondaryState.RSI);
                } else {
                  _secondaryState.add(SecondaryState.RSI);
                }
                _secondaryState = Set.from(_secondaryState);
              }),
            ),
            const SizedBox(width: 16),
            _buildToggleButton(
              label: _volHidden ? '显示成交量' : '隐藏成交量',
              onPressed: () => setState(() => _volHidden = !_volHidden),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required VoidCallback onPressed,
    bool isSelected = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
        foregroundColor: isSelected ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
