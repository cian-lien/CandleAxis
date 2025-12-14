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

  // 模拟加载失败场景（用于演示错误处理）
  int _loadAttemptCount = 0;

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

  void _generateMockData({int count = 200, int startOffset = 0}) {
    final random = Random();
    final List<KLineEntity> data = [];

    double basePrice = 100.0;
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final date = now.subtract(Duration(days: startOffset + count - i));
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

  /// 加载更多历史数据
  Future<void> _loadMoreData(bool isLeft) async {
    if (_kLineData == null) return;

    // ignore: avoid_print
    print('开始加载${isLeft ? "历史" : "最新"}数据...');

    // 模拟网络请求延迟
    await Future.delayed(const Duration(seconds: 2));

    // 模拟第一次加载失败（用于演示错误处理）
    _loadAttemptCount++;
    if (_loadAttemptCount == 1) {
      throw Exception('网络连接失败，请重试');
    }

    if (isLeft) {
      // 加载历史数据（左侧）
      final currentOldestTime = _kLineData!.first.time!;
      final random = Random();
      final List<KLineEntity> newData = [];

      double basePrice = _kLineData!.first.close!;

      // 生成50条历史数据
      for (int i = 50; i > 0; i--) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          currentOldestTime,
        ).subtract(Duration(days: i));
        final timestamp = date.millisecondsSinceEpoch;

        final change = (random.nextDouble() - 0.5) * 5;
        basePrice = basePrice + change;
        if (basePrice < 10) basePrice = 10;

        final open = basePrice + (random.nextDouble() - 0.5) * 2;
        final close = basePrice + (random.nextDouble() - 0.5) * 2;
        final high = max(open, close) + random.nextDouble() * 2;
        final low = min(open, close) - random.nextDouble() * 2;
        final vol = 1000000 + random.nextDouble() * 5000000;

        newData.add(
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

      // 将新数据插入到前面
      final combinedData = [...newData, ..._kLineData!];
      DataUtil.calculate(combinedData);

      setState(() {
        _kLineData = combinedData;
      });

      // ignore: avoid_print
      print('成功加载${newData.length}条历史数据');
    } else {
      // 加载最新数据（右侧）
      // ignore: avoid_print
      print('加载最新数据（暂未实现）');
    }
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
        physics: NeverScrollableScrollPhysics(),
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
                  isTrendLine: false,
                  isLine: _isLine,
                  mainStateLi: _mainState,
                  secondaryStateLi: _secondaryState,
                  volHidden: _volHidden,
                  showNowPrice: true,
                  isTapShowInfoDialog: true,
                  mBaseHeight: 400,
                  timeFormat: TimeFormat.YEAR_MONTH_DAY,
                  crossPriceAlignment: CrossPriceAlignment.right,
                  nowPriceAlignment: NowPriceAlignment.right,
                  verticalTextAlignment: VerticalTextAlignment.right,
                  priceFormatter: (price) => price.toStringAsFixed(2),
                  flingRatio: 0.2,
                  xFrontPadding: 300, // 右侧留白
                  xBackPadding: 300, // 左侧留白
                  // 边界回调 - 滑动到边界时触发加载更多数据
                  onReachBoundary: (isLeft) async {
                    await _loadMoreData(isLeft);
                  },
                  // 自定义加载指示器
                  loadingIndicatorBuilder: (isLeft) {
                    if (!isLeft) {
                      return SizedBox.shrink();
                    }

                    return Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLeft ? '加载历史数据...' : '加载最新数据...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  // 加载错误组件
                  loadingErrorBuilder: (isLeft, error, retry) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '加载失败: ${error.toString()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: retry,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('重试'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  // 边界触发阈值（像素）
                  boundaryThreshold: 50,
                  // 防抖延迟（毫秒）
                  debounceDelay: 1000,
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
