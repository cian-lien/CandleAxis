# K 线图实现原理详解

## 项目概述

这是一个基于 Flutter 实现的高性能 K 线图表库，支持多种技术指标、手势交互和自定义样式。项目采用 Canvas 绘制技术，实现了流畅的图表渲染和丰富的交互功能。

---

## 核心架构

### 1. 整体分层设计

```
┌─────────────────────────────────────────┐
│   CandlestickWidget (UI 层)            │
│   - 手势处理                            │
│   - 状态管理                            │
│   - 用户交互                            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   ChartPainter (绘制协调层)             │
│   - 协调各个 Renderer                   │
│   - 管理绘制顺序                        │
│   - 处理十字线、信息弹窗                │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌─────▼─────────┐
│MainRenderer │  │SecondaryRenderer│
│VolRenderer  │  │ (MACD/KDJ等)   │
│(渲染器层)   │  │                │
└──────┬──────┘  └─────┬─────────┘
       │                │
┌──────▼────────────────▼─────────┐
│   KLineEntity (数据模型层)      │
│   - 价格数据 (OHLC)             │
│   - 技术指标数据                │
└─────────────────────────────────┘
```

---

## 实现详解

### 第一步：数据模型设计

#### 1.1 核心数据结构 - KLineEntity

**文件位置**: [lib/entity/k_line_entity.dart:3](lib/entity/k_line_entity.dart#L3)

```dart
class KLineEntity extends KEntity {
  // 基础 OHLC 数据
  late double open;    // 开盘价
  late double high;    // 最高价
  late double low;     // 最低价
  late double close;   // 收盘价
  late double vol;     // 成交量
  late double? amount; // 成交额

  // 时间戳
  int? time;

  // 涨跌数据
  double? change;  // 涨跌额
  double? ratio;   // 涨跌幅
}
```

**设计亮点**:
- 使用 `late` 关键字延迟初始化，减少内存占用
- 兼容多种数据源（支持火币等交易所的数据格式）
- 提供 `fromJson` 和 `toJson` 方法，方便数据序列化

#### 1.2 Mixin 组合模式 - KEntity

**文件位置**: [lib/entity/k_entity.dart:9](lib/entity/k_entity.dart#L9)

```dart
class KEntity with
    CandleEntity,      // 蜡烛图相关（MA, BOLL, SAR）
    VolumeEntity,      // 成交量相关（MA5Volume, MA10Volume）
    KDJEntity,         // KDJ 指标
    RSIEntity,         // RSI 指标
    WREntity,          // WR 指标
    CCIEntity,         // CCI 指标
    MACDEntity {}      // MACD 指标
```

**设计思想**:
- 使用 Dart 的 Mixin 机制实现数据的模块化组合
- 每个指标独立一个 Mixin，便于扩展和维护
- KLineEntity 继承 KEntity，自动获得所有技术指标属性

#### 1.3 技术指标数据示例 - CandleEntity

**文件位置**: [lib/entity/candle_entity.dart:2](lib/entity/candle_entity.dart#L2)

```dart
mixin CandleEntity {
  late double open;
  late double high;
  late double low;
  late double close;

  // 移动平均线数组（支持多条 MA 线）
  List<double>? maValueList;

  // 抛物线转向指标 SAR
  double? sar;

  // 布林带 BOLL
  double? up;   // 上轨线
  double? mb;   // 中轨线
  double? dn;   // 下轨线
  double? BOLLMA;
}
```

---

### 第二步：技术指标计算

#### 2.1 统一计算入口 - DataUtil

**文件位置**: [lib/utils/data_util.dart:6](lib/utils/data_util.dart#L6)

```dart
class DataUtil {
  static calculate(List<KLineEntity> dataList,
      [List<int> maDayList = const [5, 10, 20], int n = 20, k = 2]) {
    /// 计算主图指标
    calcMA(dataList, maDayList);     // 移动平均线
    calcBOLL(dataList, n, k);        // 布林带
    calcSAR(dataList);               // 抛物线转向

    /// 计算副图指标
    calcVolumeMA(dataList);          // 成交量均线
    calcKDJ(dataList);               // KDJ 随机指标
    calcMACD(dataList);              // MACD 指标
    calcRSI(dataList);               // 相对强弱指标
    calcWR(dataList);                // 威廉指标
    calcCCI(dataList);               // 顺势指标
  }
}
```

**使用方式**:
```dart
// 从网络或数据库获取原始 K 线数据
List<KLineEntity> data = [...];

// 一键计算所有技术指标
DataUtil.calculate(data);

// 数据已经包含所有技术指标，可以直接用于渲染
```

#### 2.2 MA（移动平均线）计算原理

**文件位置**: [lib/utils/data_util.dart:22](lib/utils/data_util.dart#L22)

```dart
static calcMA(List<KLineEntity> dataList, List<int> maDayList) {
  List<double> ma = List<double>.filled(maDayList.length, 0);

  for (int i = 0; i < dataList.length; i++) {
    KLineEntity entity = dataList[i];
    final closePrice = entity.close;
    entity.maValueList = List<double>.filled(maDayList.length, 0);

    for (int j = 0; j < maDayList.length; j++) {
      ma[j] += closePrice;

      // 达到周期后开始计算均值
      if (i == maDayList[j] - 1) {
        entity.maValueList?[j] = ma[j] / maDayList[j];
      }
      // 滑动窗口计算
      else if (i >= maDayList[j]) {
        ma[j] -= dataList[i - maDayList[j]].close;
        entity.maValueList?[j] = ma[j] / maDayList[j];
      }
    }
  }
}
```

**算法优势**:
- 使用滑动窗口算法，时间复杂度 O(n)
- 同时支持多条 MA 线（MA5, MA10, MA20）
- 避免重复计算，提高性能

#### 2.3 MACD 计算原理

**文件位置**: [lib/utils/data_util.dart:141](lib/utils/data_util.dart#L141)

```dart
static void calcMACD(List<KLineEntity> dataList) {
  double ema12 = 0, ema26 = 0, dif = 0, dea = 0, macd = 0;

  for (int i = 0; i < dataList.length; i++) {
    KLineEntity entity = dataList[i];
    final closePrice = entity.close;

    if (i == 0) {
      ema12 = closePrice;
      ema26 = closePrice;
    } else {
      // EMA(12) = 前一日 EMA(12) × 11/13 + 今日收盘价 × 2/13
      ema12 = ema12 * 11 / 13 + closePrice * 2 / 13;
      // EMA(26) = 前一日 EMA(26) × 25/27 + 今日收盘价 × 2/27
      ema26 = ema26 * 25 / 27 + closePrice * 2 / 27;
    }

    // DIF = EMA(12) - EMA(26)
    dif = ema12 - ema26;
    // DEA = 前一日 DEA × 8/10 + 今日 DIF × 2/10
    dea = dea * 8 / 10 + dif * 2 / 10;
    // MACD = (DIF - DEA) × 2
    macd = (dif - dea) * 2;

    entity.dif = dif;
    entity.dea = dea;
    entity.macd = macd;
  }
}
```

**MACD 公式说明**:
1. 计算快线 EMA(12) 和慢线 EMA(26)
2. DIF = 快线 - 慢线
3. DEA = DIF 的 9 日 EMA
4. MACD 柱 = (DIF - DEA) × 2

---

### 第三步：绘制引擎实现

#### 3.1 绘制基类 - BaseChartPainter

**文件位置**: [lib/renderer/base_chart_painter.dart:16](lib/renderer/base_chart_painter.dart#L16)

```dart
abstract class BaseChartPainter extends CustomPainter {
  // 数据源
  List<KLineEntity>? datas;

  // 缩放和滚动参数
  double scaleX = 1.0;     // 水平缩放倍数
  double scrollX = 0.0;    // 滚动偏移
  double mTranslateX;      // 实际平移距离

  // 可见区域索引
  int mStartIndex = 0;     // 起始索引
  int mStopIndex = 0;      // 结束索引

  // 区域定义
  late Rect mMainRect;     // 主图区域
  Rect? mVolRect;          // 成交量区域
  List<RenderRect> mSecondaryRectList = [];  // 副图区域列表

  // 极值追踪
  double mMainMaxValue = double.minPositive;
  double mMainMinValue = double.maxFinite;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));

    initRect(size);           // 初始化绘制区域
    calculateValue();         // 计算可见范围和极值
    initChartRenderer();      // 初始化渲染器

    drawBg(canvas, size);     // 绘制背景
    drawGrid(canvas);         // 绘制网格
    drawChart(canvas, size);  // 绘制图表
    drawVerticalText(canvas); // 绘制纵轴文字
    drawDate(canvas, size);   // 绘制日期
    drawMaxAndMin(canvas);    // 绘制最高最低价
    drawNowPrice(canvas);     // 绘制当前价格线

    if (isLongPress) {
      drawCrossLineText(canvas, size);  // 绘制十字线
    }
  }
}
```

**核心设计**:
- 继承 Flutter 的 `CustomPainter` 实现自定义绘制
- 抽象类定义绘制流程，子类实现具体细节
- 模板方法模式确保绘制顺序正确

#### 3.2 坐标系统和缩放算法

**关键算法**: 屏幕坐标到数据索引的映射

**文件位置**: [lib/renderer/base_chart_painter.dart:383](lib/renderer/base_chart_painter.dart#L383)

```dart
// 根据索引获取 X 坐标
double getX(int position) => position * mPointWidth + mPointWidth / 2;

// 屏幕 X 转换为平移后的 X
double xToTranslateX(double x) => -mTranslateX + x / scaleX;

// 平移后的 X 转换为屏幕 X
double translateXtoX(double translateX) => (translateX + mTranslateX) * scaleX;

// 使用二分查找获取 translateX 对应的索引
int indexOfTranslateX(double translateX) =>
    _indexOfTranslateX(translateX, 0, mItemCount - 1);

int _indexOfTranslateX(double translateX, int start, int end) {
  if (end == start || end == -1) return start;
  if (end - start == 1) {
    double startValue = getX(start);
    double endValue = getX(end);
    return (translateX - startValue).abs() < (translateX - endValue).abs()
        ? start : end;
  }
  int mid = start + (end - start) ~/ 2;
  double midValue = getX(mid);
  if (translateX < midValue) {
    return _indexOfTranslateX(translateX, start, mid);
  } else if (translateX > midValue) {
    return _indexOfTranslateX(translateX, mid, end);
  } else {
    return mid;
  }
}
```

**算法优势**:
- 二分查找时间复杂度 O(log n)
- 支持任意缩放比例和平移
- 精确计算可见数据范围，避免无效绘制

#### 3.3 主图渲染器 - MainRenderer

**文件位置**: [lib/renderer/main_renderer.dart:255](lib/renderer/main_renderer.dart#L255)

**蜡烛图绘制核心代码**:

```dart
void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
  var high = getY(curPoint.high);
  var low = getY(curPoint.low);
  var open = getY(curPoint.open);
  var close = getY(curPoint.close);

  double r = mCandleWidth / 2;
  double lineR = mCandleLineWidth / 2;

  // 阳线（涨）
  if (open >= close) {
    if (open - close < mCandleLineWidth) {
      open = close + mCandleLineWidth;  // 确保最小可见高度
    }
    chartPaint.color = this.chartColors.upColor;
    canvas.drawRect(
        Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
    canvas.drawRect(
        Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
  }
  // 阴线（跌）
  else if (close > open) {
    if (close - open < mCandleLineWidth) {
      open = close - mCandleLineWidth;
    }
    chartPaint.color = this.chartColors.dnColor;
    canvas.drawRect(
        Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
    canvas.drawRect(
        Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
  }
}
```

**绘制技巧**:
1. **Y 坐标倒置处理**: 将价格转换为屏幕坐标（高价格对应低 Y 值）
2. **最小可见高度**: 确保十字星等极端情况也能显示
3. **分离实体和影线**: 先画实体矩形，再画上下影线

#### 3.4 分时图（折线图）绘制

**文件位置**: [lib/renderer/main_renderer.dart:163](lib/renderer/main_renderer.dart#L163)

```dart
drawPolyline(double lastPrice, double curPrice, Canvas canvas,
             double lastX, double curX) {
  mLinePath ??= Path();

  if (lastX == curX) lastX = 0;  // 起点位置填充

  // 使用三次贝塞尔曲线实现平滑过渡
  mLinePath!.moveTo(lastX, getY(lastPrice));
  mLinePath!.cubicTo(
    (lastX + curX) / 2, getY(lastPrice),  // 控制点1
    (lastX + curX) / 2, getY(curPrice),   // 控制点2
    curX, getY(curPrice)                  // 终点
  );

  // 绘制渐变填充阴影
  mLineFillShader ??= LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      this.chartColors.lineFillColor,
      this.chartColors.lineFillInsideColor
    ],
  ).createShader(Rect.fromLTRB(...));

  mLineFillPaint..shader = mLineFillShader;

  // 绘制填充区域
  mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
  mLineFillPath!.lineTo(lastX, getY(lastPrice));
  mLineFillPath!.cubicTo(...);
  mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
  mLineFillPath!.close();

  canvas.drawPath(mLineFillPath!, mLineFillPaint);
  canvas.drawPath(mLinePath!, mLinePaint);
}
```

**视觉效果**:
- 使用贝塞尔曲线实现平滑的折线
- 渐变填充营造立体感
- 动态调整线条粗细，缩放时保持清晰

---

### 第四步：手势交互系统

#### 4.1 统一手势识别器架构

**文件位置**: [lib/candlestick_widget.dart:448](lib/candlestick_widget.dart#L448)

```dart
// 使用 Listener 跟踪手指数量
return Listener(
  onPointerDown: (_) => setState(() => _pointerCount++),
  onPointerUp: (_) => setState(() => _pointerCount--),
  onPointerCancel: (_) => setState(() => _pointerCount--),
  child: RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: <Type, GestureRecognizerFactory>{
      // 统一的缩放手势 - 同时处理拖拽和缩放
      ScaleGestureRecognizer: ...,

      // 点击手势 - 切换十字线或绘制趋势线
      TapGestureRecognizer: ...,

      // 长按手势 - 显示十字线和详情
      LongPressGestureRecognizer: ...,
    },
    child: Stack(
      children: [
        CustomPaint(painter: painter),
        if (widget.showInfoDialog) _buildInfoDialog(),
        if (_isLoadingAtLeft != null) _buildLoadingIndicator(),
      ],
    ),
  ),
);
```

**架构优化**:
- 使用 Listener 精确跟踪手指数量，避免手势竞技场冲突
- 统一使用 ScaleGestureRecognizer 处理拖拽和缩放
- 支持加载指示器和错误处理组件

#### 4.2 统一手势处理（拖拽+缩放）

**文件位置**: [lib/candlestick_widget.dart:453](lib/candlestick_widget.dart#L453)

```dart
ScaleGestureRecognizer:
  GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
    () => ScaleGestureRecognizer(),
    (instance) {
      instance
        ..onStart = (details) {
          _lastPointerCount = _pointerCount;
          _scaleBase = 1.0;
          _scaleXBase = mScaleX;

          // 计算锚点：用于焦点锚定缩放
          _anchorScreenX = details.focalPoint.dx;
          _anchorIndex = painter.calculateSelectedX(_anchorScreenX);

          _boundaryOverscroll = 0.0;
        }
        ..onUpdate = (details) {
          if (isLongPress) return;

          // 滑动或缩放时自动隐藏十字线
          if (_isCrossLocked) {
            _isCrossLocked = false;
            isOnTap = false;
            mInfoWindowStream.sink.add(null);
          }

          // 关键：检测手指数量变化，重置基线避免画面跳动
          if (_pointerCount != _lastPointerCount) {
            _scaleBase = details.scale;
            _scaleXBase = mScaleX;
            _anchorScreenX = details.focalPoint.dx;
            _anchorIndex = painter.calculateSelectedX(_anchorScreenX);
            _lastPointerCount = _pointerCount;
          }

          final isPinching = _pointerCount >= 2;

          if (!isPinching) {
            // ===== 单指模式：拖拽 =====
            final dx = details.focalPointDelta.dx;
            final delta = (dx / mScaleX) * widget.panSensitivity;
            mScrollX = (mScrollX + delta)
                .clamp(0.0, ChartPainter.maxScrollX)
                .toDouble();

            // 边界检测逻辑...
          } else {
            // ===== 双指模式：焦点锚定缩放 =====
            isScale = true;
            final relativeScale = details.scale / _scaleBase;
            final newScaleX = (_scaleXBase * relativeScale).clamp(0.2, 4.0);

            // 计算锚点在缩放后的新位置，调整 scrollX 保持锚点不动
            final anchorLogicX = painter.getX(_anchorIndex);
            final newTranslateX = _anchorScreenX / newScaleX - anchorLogicX;
            // ...后续计算 scrollX
          }
          notifyChanged();
        }
        ..onEnd = (details) {
          // 单指拖拽才启动惯性滚动
          if (_pointerCount == 0 && _lastPointerCount == 1) {
            var velocity = details.velocity.pixelsPerSecond.dx;
            _onFling(velocity);
          }
        };
    },
  ),
```

**交互细节**:
- 使用 `focalPointDelta` 避免受焦点定义变化影响
- 支持 `panSensitivity` 灵敏度系数调整
- 边界检测支持防抖（`debounceDelay`）和阈值配置（`boundaryThreshold`）
- 焦点锚定缩放：缩放时保持双指焦点位置的 K 线不变

#### 4.3 焦点锚定缩放算法

**文件位置**: [lib/candlestick_widget.dart:553](lib/candlestick_widget.dart#L553)

```dart
// ===== 实现焦点锚定缩放 =====
// 核心思路：缩放后调整 scrollX，使锚点索引仍显示在焦点位置

// 1. 计算锚点在缩放前的逻辑坐标
final anchorLogicX = painter.getX(_anchorIndex);

// 2. 计算缩放后，要让锚点显示在 _anchorScreenX，需要的 mTranslateX
// 公式推导：screenX = (logicX + mTranslateX) * scaleX
// => mTranslateX = screenX / scaleX - logicX
final newTranslateX = _anchorScreenX / newScaleX - anchorLogicX;

// 3. 从 mTranslateX 反推 mScrollX
// 根据 base_chart_painter.dart：mTranslateX = scrollX + getMinTranslateX()
final dataLen = painter.mDataLen;
final pointWidth = painter.mPointWidth;
final minTranslateX = -dataLen + mWidth / newScaleX - pointWidth / 2
    - widget.xFrontPadding / newScaleX;  // 使用动态边距
final effectiveMinTranslateX = minTranslateX >= 0 ? 0.0 : minTranslateX;

mScrollX = (newTranslateX - effectiveMinTranslateX)
    .clamp(0.0, ChartPainter.maxScrollX)
    .toDouble();
```

**算法优势**:
- 双指缩放时，焦点位置的 K 线保持不动
- 使用动态边距（`xFrontPadding / scaleX`）确保边界计算正确
- 支持任意缩放比例下的精确定位

#### 4.4 惯性滚动动画

**文件位置**: [lib/candlestick_widget.dart:429](lib/candlestick_widget.dart#L429)

```dart
void _onFling(double x) {
  _controller = AnimationController(
      duration: Duration(milliseconds: widget.flingTime),
      vsync: this);

  aniX = Tween<double>(
    begin: mScrollX,
    end: x * widget.flingRatio + mScrollX
  ).animate(CurvedAnimation(
      parent: _controller!.view,
      curve: widget.flingCurve));

  aniX!.addListener(() {
    mScrollX = aniX!.value;

    // 边界检测
    if (mScrollX <= 0) {
      mScrollX = 0;
      widget.onLoadMore?.call(true);
      _stopAnimation();
    } else if (mScrollX >= ChartPainter.maxScrollX) {
      mScrollX = ChartPainter.maxScrollX;
      widget.onLoadMore?.call(false);
      _stopAnimation();
    }

    notifyChanged();
  });

  _controller!.forward();
}
```

**动画参数**:
- `flingTime`: 惯性滚动持续时间（默认 600ms）
- `flingRatio`: 速度衰减系数（默认 0.5）
- `flingCurve`: 动画曲线（默认 Curves.decelerate）

---

### 第五步：十字线和信息弹窗

#### 5.1 十字线绘制（支持虚线）

**文件位置**: [lib/renderer/chart_painter.dart:552](lib/renderer/chart_painter.dart#L552)

```dart
void drawCrossLine(Canvas canvas, Size size) {
  var index = calculateSelectedX(selectX);
  KLineEntity point = getItem(index);
  double x = getX(index);
  double y = getMainY(point.close);

  // 竖线 Paint：补偿 scaleX 对线宽的影响
  Paint paintY = Paint()
    ..color = this.chartColors.vCrossColor
    ..strokeWidth = this.chartStyle.vCrossWidth / scaleX
    ..isAntiAlias = true;

  // 横线 Paint：保持原始线宽
  Paint paintX = Paint()
    ..color = this.chartColors.hCrossColor
    ..strokeWidth = this.chartStyle.hCrossWidth
    ..isAntiAlias = true;

  if (chartStyle.crossLineDash) {
    // 竖线虚线：补偿 scaleX
    _drawDashedLineCompensated(canvas,
        Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding),
        paintY, scaleX);
    // 横线虚线：补偿 scaleX 拉伸
    _drawDashedLineHorizontalCompensated(canvas,
        Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y),
        paintX, scaleX);
  } else {
    // 实线绘制
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
  }

  // 绘制中心圆点：使用 drawOval 补偿 scaleX，保持视觉上的圆形
  Paint paintDot = Paint()
    ..color = this.chartColors.hCrossColor
    ..style = PaintingStyle.fill;
  double radius = 3.0;
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(x, y),
      width: radius * 2 / scaleX,  // 水平方向补偿缩放
      height: radius * 2,
    ),
    paintDot,
  );
}
```

#### 5.2 虚线绘制算法（带 scaleX 补偿）

**文件位置**: [lib/renderer/chart_painter.dart:609](lib/renderer/chart_painter.dart#L609)

```dart
/// 绘制虚线（用于竖线）
void _drawDashedLineCompensated(
    Canvas canvas, Offset start, Offset end, Paint paint, double scaleX) {
  final dashLength = chartStyle.crossLineDashLength;
  final dashSpace = chartStyle.crossLineDashSpace;

  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final distance = math.sqrt(dx * dx + dy * dy);
  final unitX = dx / distance;
  final unitY = dy / distance;

  double currentDistance = 0;
  while (currentDistance < distance) {
    final segmentEnd = (currentDistance + dashLength).clamp(0.0, distance);
    canvas.drawLine(
      Offset(start.dx + unitX * currentDistance,
          start.dy + unitY * currentDistance),
      Offset(start.dx + unitX * segmentEnd, start.dy + unitY * segmentEnd),
      paint,
    );
    currentDistance += dashLength + dashSpace;
  }
}

/// 绘制虚线（用于横线，补偿 scaleX 拉伸）
void _drawDashedLineHorizontalCompensated(
    Canvas canvas, Offset start, Offset end, Paint paint, double scaleX) {
  // 横线沿 X 轴绘制，会被 canvas.scale(scaleX, 1.0) 拉伸
  // 需要将 dashLength 和 dashSpace 除以 scaleX 补偿
  final dashLength = chartStyle.crossLineDashLength / scaleX;
  final dashSpace = chartStyle.crossLineDashSpace / scaleX;
  // ... 后续逻辑同上
}
```

**虚线配置项**（ChartStyle）:
- `crossLineDash`: 是否使用虚线（默认 true）
- `crossLineDashLength`: 虚线段长度（默认 4.0）
- `crossLineDashSpace`: 虚线间隔长度（默认 3.0）

#### 5.2 价格和日期标签

**文件位置**: [lib/renderer/chart_painter.dart:278](lib/renderer/chart_painter.dart#L278)

```dart
void drawCrossLineText(Canvas canvas, Size size) {
  var index = calculateSelectedX(selectX);
  KLineEntity point = getItem(index);

  // 价格标签
  TextPainter tp = getTextPainter(
    formatPrice(point.close),
    chartColors.crossTextColor
  );

  double y = getMainY(point.close);

  // 动态决定标签位置（左侧或右侧）
  bool infoWindowIsLeft = translateXtoX(getX(index)) >= mWidth / 2;
  bool priceTagOnLeft;

  if (crossPriceAlignment == CrossPriceAlignment.left) {
    priceTagOnLeft = true;
  } else if (crossPriceAlignment == CrossPriceAlignment.right) {
    priceTagOnLeft = false;
  } else {
    priceTagOnLeft = infoWindowIsLeft;  // 自动模式
  }

  if (priceTagOnLeft) {
    // 绘制左侧箭头标签
    Path path = Path();
    path.moveTo(x, y - r);
    path.lineTo(x, y + r);
    path.lineTo(textWidth + 2 * w1, y + r);
    path.lineTo(textWidth + 2 * w1 + w2, y);  // 箭头
    path.lineTo(textWidth + 2 * w1, y - r);
    path.close();
    canvas.drawPath(path, selectPointPaint);
    tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
  } else {
    // 绘制右侧箭头标签
    // ...
  }

  // 发送信息到弹窗 Stream
  sink.add(InfoWindowEntity(point, isLeft: infoWindowIsLeft));
}
```

#### 5.3 信息弹窗组件

**文件位置**: [lib/candlestick_widget.dart:467](lib/candlestick_widget.dart#L467)

```dart
Widget _buildInfoDialog() {
  return StreamBuilder<InfoWindowEntity?>(
    stream: mInfoWindowStream.stream,
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data?.kLineEntity == null)
        return SizedBox();

      KLineEntity entity = snapshot.data!.kLineEntity;
      final dialogWidth = mWidth / 3;

      // 根据十字线位置动态调整弹窗位置
      if (snapshot.data!.isLeft) {
        return Positioned(
          top: 25,
          left: 10.0,
          child: PopupInfoView(
            entity: entity,
            width: dialogWidth,
            chartColors: widget.chartColors,
            // ...
          ),
        );
      }

      return Positioned(
        top: 25,
        right: 80.0,
        child: PopupInfoView(
          entity: entity,
          width: dialogWidth,
          // ...
        ),
      );
    },
  );
}
```

**交互逻辑**:
1. 使用 `StreamController` 实现绘制层和 Widget 层的通信
2. 十字线位置在左侧时，弹窗显示在右侧，反之亦然
3. 支持自定义弹窗样式（Material 或自定义）

---

## 性能优化策略

### 1. 可见区域裁剪

**文件位置**: [lib/renderer/base_chart_painter.dart:228](lib/renderer/base_chart_painter.dart#L228)

```dart
calculateValue() {
  if (datas == null || datas!.isEmpty) return;

  // 更新最大滚动距离，包括左右两侧的留白区域
  maxScrollX = getMinTranslateX().abs() + getMaxTranslateX();
  setTranslateXFromScrollX(scrollX);

  // 只计算可见范围的索引
  mStartIndex = indexOfTranslateX(xToTranslateX(0));
  mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));

  // 只遍历可见数据
  for (int i = mStartIndex; i <= mStopIndex; i++) {
    var item = datas![i];
    getMainMaxMinValue(item, i);
    getVolMaxMinValue(item);
    // ...
  }
}
```

**优化效果**:
- 避免绘制屏幕外的数据
- 大数据集（10000+ K 线）也能流畅滚动
- 减少 CPU 和内存占用
- 支持动态边距（`xFrontPadding`, `xBackPadding`）

### 2. 路径重用和重置

**文件位置**: [lib/renderer/main_renderer.dart:166](lib/renderer/main_renderer.dart#L166)

```dart
drawPolyline(...) {
  mLinePath ??= Path();  // 单例路径对象

  // 使用路径
  mLinePath!.moveTo(lastX, getY(lastPrice));
  mLinePath!.cubicTo(...);

  canvas.drawPath(mLinePath!, mLinePaint);

  // 重置路径，下次循环复用
  mLinePath!.reset();
}
```

**避免 GC 压力**:
- 复用 Path 对象，避免频繁创建销毁
- 减少垃圾回收，提升帧率

### 3. 智能重绘判断

**文件位置**: [lib/renderer/base_chart_painter.dart:517](lib/renderer/base_chart_painter.dart#L517)

```dart
@override
bool shouldRepaint(BaseChartPainter oldDelegate) {
  return true;  // 根据实际需求可优化为精确比较
}
```

**可优化方向**:
```dart
bool shouldRepaint(BaseChartPainter oldDelegate) {
  return oldDelegate.scaleX != scaleX ||
         oldDelegate.scrollX != scrollX ||
         oldDelegate.selectX != selectX ||
         oldDelegate.datas != datas;
}
```

### 4. 动态宽度算法

**文件位置**: [lib/renderer/main_renderer.dart:342](lib/renderer/main_renderer.dart#L342)

#### 4.1 动态影线宽度

当缩放到最小时，影线宽度逐渐增加至与实体宽度相同，避免影线过细看不清。

```dart
/// 计算动态影线宽度
double _calculateDynamicShadowWidth() {
  // 功能未启用时，使用默认宽度
  if (!this.chartStyle.enableDynamicShadowWidth) {
    return mCandleLineWidth;
  }

  final start = this.chartStyle.shadowWidthTransitionStart;  // 0.3
  final end = this.chartStyle.shadowWidthTransitionEnd;      // 0.2

  // 缩放级别高于过渡起点，使用默认影线宽度
  if (scaleX >= start) return mCandleLineWidth;

  // 缩放级别低于过渡终点，影线宽度等于实体宽度
  if (scaleX <= end) return mCandleWidth;

  // 在过渡区间内，线性插值计算影线宽度
  final progress = (start - scaleX) / (start - end);
  return mCandleLineWidth + (mCandleWidth - mCandleLineWidth) * progress;
}
```

**配置项**（ChartStyle）:
- `enableDynamicShadowWidth`: 是否启用（默认 true）
- `shadowWidthTransitionStart`: 开始过渡的 scaleX（默认 0.3）
- `shadowWidthTransitionEnd`: 完全过渡的 scaleX（默认 0.2）

#### 4.2 动态指标线宽

**文件位置**: [lib/renderer/main_renderer.dart:377](lib/renderer/main_renderer.dart#L377)

```dart
/// 计算主图技术指标的动态线宽
double _calculateMainIndicatorWidth() {
  if (!this.chartStyle.enableDynamicMainIndicatorWidth) {
    return this.chartStyle.mainIndicatorBaseWidth;
  }

  // 基础宽度 / scaleX，补偿缩放效果
  final baseWidth = this.chartStyle.mainIndicatorBaseWidth / scaleX;

  // 最大宽度 = min(固定上限, K 线实体宽度)
  final maxWidth = this.chartStyle.mainIndicatorMaxWidth < mCandleWidth
      ? this.chartStyle.mainIndicatorMaxWidth
      : mCandleWidth;

  return baseWidth > maxWidth ? maxWidth : baseWidth;
}
```

**配置项**（ChartStyle）:
- `enableDynamicMainIndicatorWidth`: 主图指标是否启用（默认 false）
- `mainIndicatorBaseWidth`: 基础宽度（默认 1.5）
- `mainIndicatorMaxWidth`: 最大宽度上限（默认 3.0）
- `enableDynamicSecondaryIndicatorWidth`: 副图指标是否启用（默认 false）
- `secondaryIndicatorBaseWidth`: 基础宽度（默认 1.2）
- `secondaryIndicatorMaxWidth`: 最大宽度上限（默认 3.0）

### 5. 视口状态快照

**文件位置**: [lib/candlestick_widget.dart:19](lib/candlestick_widget.dart#L19)

在加载历史数据时，保持当前可见 K 线位置不变：

```dart
/// 视口状态快照
class ViewportSnapshot {
  final int dataLength;   // 快照时数据的总长度
  final double scrollX;   // 快照时的 scrollX 值
  final double scaleX;    // 快照时的 scaleX 值
}

// 使用示例
void loadHistoricalData() async {
  // 1. 加载前保存快照
  final snapshot = chartKey.currentState?.createViewportSnapshot();

  // 2. 加载数据
  final newData = await api.loadHistory();
  final oldLength = data.length;
  data.insertAll(0, newData);  // 在前面插入历史数据

  // 3. 恢复视口位置
  final addedCount = data.length - oldLength;
  chartKey.currentState?.restoreViewport(snapshot!, addedCount);
}
```

**文件位置**: [lib/candlestick_widget.dart:878](lib/candlestick_widget.dart#L878)

```dart
/// 恢复视口位置
void restoreViewport(ViewportSnapshot snapshot, int newDataCount) {
  if (widget.datas == null || widget.datas!.isEmpty) return;

  // 如果是左侧加载历史数据（newDataCount > 0），需要增加 scrollX 来补偿
  final newScrollX = snapshot.scrollX + newDataCount;

  setState(() {
    mScaleX = snapshot.scaleX;
    mScrollX = newScrollX.clamp(0.0, ChartPainter.maxScrollX).toDouble();
  });
}
```

---

## 使用示例

### 基础使用

**文件位置**: [example/lib/main.dart:126](example/lib/main.dart#L126)

```dart
// 1. 准备数据
List<KLineEntity> data = [];
for (int i = 0; i < 200; i++) {
  data.add(KLineEntity.fromCustom(
    time: DateTime.now().subtract(Duration(days: 200 - i)).millisecondsSinceEpoch,
    open: ...,
    close: ...,
    high: ...,
    low: ...,
    vol: ...,
  ));
}

// 2. 计算技术指标
DataUtil.calculate(data);

// 3. 渲染 K 线图
CandlestickWidget(
  data,
  ChartStyle(),
  ChartColors(),
  isTrendLine: false,
  isLine: false,                          // 是否分时图
  mainStateLi: {MainState.MA},            // 主图指标
  secondaryStateLi: {SecondaryState.MACD}, // 副图指标
  volHidden: false,                       // 是否隐藏成交量
  showNowPrice: true,                     // 显示当前价格线
  isTapShowInfoDialog: true,              // 点击显示信息
  mBaseHeight: 400,                       // 图表高度
  onLoadMore: (isLeft) {
    // isLeft = true: 加载历史数据
    // isLeft = false: 加载最新数据
    print('加载更多: ${isLeft ? "历史" : "最新"}');
  },
  onReachBoundary: (isLeft) async {
    // 滑动到边界回调，支持异步加载
    await loadMoreData(isLeft);
  },
)
```

### 高级配置

```dart
CandlestickWidget(
  data,
  ChartStyle(
    pointWidth: 11.0,           // K 线宽度
    candleWidth: 8.5,           // 蜡烛宽度
    candleLineWidth: 1.0,       // 影线宽度
    gridRows: 4,                // 网格行数
    gridColumns: 4,             // 网格列数

    // ===== 价格弹窗样式 =====
    popupTitleFontSize: 10.0,   // 弹窗标题字体大小
    popupValueFontSize: 10.0,   // 弹窗值字体大小
    popupPadding: EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 0.0),
    popupItemSpacing: 3.0,      // 每行底部间距
    popupBorderWidth: 0,        // 边框宽度（0 则无边框）
    popupBorderRadius: 0.0,     // 边框圆角

    // ===== 动态影线宽度 =====
    enableDynamicShadowWidth: true,       // 启用动态影线宽度
    shadowWidthTransitionStart: 0.3,      // 开始过渡的缩放阈值
    shadowWidthTransitionEnd: 0.2,        // 完全过渡的缩放阈值

    // ===== 动态指标线宽 =====
    enableDynamicMainIndicatorWidth: false,     // 主图指标动态线宽
    mainIndicatorBaseWidth: 1.5,                // 基础宽度（scaleX=1.0时）
    mainIndicatorMaxWidth: 3.0,                 // 最大宽度上限
    enableDynamicSecondaryIndicatorWidth: false, // 副图指标动态线宽
    secondaryIndicatorBaseWidth: 1.2,           // 基础宽度
    secondaryIndicatorMaxWidth: 3.0,            // 最大宽度上限

    // ===== 十字线虚线 =====
    crossLineDash: true,        // 使用虚线
    crossLineDashLength: 4.0,   // 虚线段长度
    crossLineDashSpace: 3.0,    // 虚线间隔长度

    // ===== 日期行 =====
    dateRowHeight: 20.0,        // 日期行高度（K线图正下方）
  ),
  ChartColors(
    bgColor: Color(0xffffffff),
    upColor: Color(0xFF14AD8F),
    dnColor: Color(0xFFD5405D),
    ma5Color: Color(0xffE5B767),
    ma10Color: Color(0xff1FD1AC),
    ma30Color: Color(0xffB48CE3),
  ),
  mainStateLi: {MainState.MA, MainState.BOLL},
  secondaryStateLi: {SecondaryState.MACD, SecondaryState.KDJ},
  maDayList: [5, 10, 20, 30],
  fixedLength: 2,                // 价格小数位数
  timeFormat: TimeFormat.YEAR_MONTH_DAY_WITH_HOUR,
  verticalTextAlignment: VerticalTextAlignment.left,
  nowPriceAlignment: NowPriceAlignment.right,
  crossPriceAlignment: CrossPriceAlignment.auto,
  priceFormatter: (price) => '\$${price.toStringAsFixed(2)}',
  autoSwitchToLine: true,        // 缩放到阈值自动切换分时图
  lineThreshold: 0.5,            // 切换阈值
  panSensitivity: 1.0,           // 拖动灵敏度系数

  // ===== 边界加载配置 =====
  xFrontPadding: 100,            // 右侧留白（最新数据端）
  xBackPadding: 100,             // 左侧留白（历史数据端）
  boundaryThreshold: 50.0,       // 边界触发阈值（像素）
  debounceDelay: 1000,           // 防抖延迟（毫秒）

  // ===== 加载指示器 =====
  loadingIndicatorBuilder: (isLeft) => Container(
    padding: EdgeInsets.all(8),
    child: CircularProgressIndicator(),
  ),
  loadingErrorBuilder: (isLeft, error, retry) => TextButton(
    onPressed: retry,
    child: Text('加载失败，点击重试'),
  ),
)
```

---

## 技术亮点总结

### 1. 架构设计
- ✅ 分层架构：数据层 → 计算层 → 渲染层 → 交互层
- ✅ Mixin 组合模式实现指标模块化
- ✅ 抽象类和模板方法确保绘制流程一致性
- ✅ 统一手势处理架构，避免手势竞技场冲突

### 2. 算法优化
- ✅ 滑动窗口算法计算 MA，时间复杂度 O(n)
- ✅ 二分查找定位可见数据，时间复杂度 O(log n)
- ✅ 可见区域裁剪，避免无效绘制
- ✅ 动态宽度算法，根据缩放级别平滑调整线条粗细
- ✅ 焦点锚定缩放，保持双指焦点位置的 K 线不变

### 3. 渲染优化
- ✅ Canvas 直接绘制，性能优于 Widget 组合
- ✅ 路径对象复用，减少 GC 压力
- ✅ 贝塞尔曲线实现平滑折线
- ✅ 十字线虚线绘制，带 scaleX 补偿
- ✅ 动态边距计算，缩放时保持视觉一致

### 4. 交互体验
- ✅ 统一 ScaleGestureRecognizer 处理拖拽和缩放
- ✅ 惯性滚动动画，支持灵敏度调节
- ✅ 边界检测带防抖和阈值配置
- ✅ 十字线锁定显示，点击切换状态
- ✅ 加载指示器和错误处理支持
- ✅ 视口快照，加载历史数据时保持位置

### 5. 扩展性
- ✅ 支持自定义样式和颜色（包括弹窗样式）
- ✅ 支持自定义时间格式
- ✅ 支持自定义价格格式化
- ✅ 支持多种技术指标组合
- ✅ 丰富的配置项（动态宽度、十字线、日期行等）

---

## 关键文件索引

| 文件路径 | 功能说明 |
|---------|---------|
| [lib/candlestick_widget.dart](lib/candlestick_widget.dart) | 主 Widget，处理手势和状态管理、视口快照 |
| [lib/renderer/chart_painter.dart](lib/renderer/chart_painter.dart) | 绘制协调器，管理渲染流程、十字线虚线绘制 |
| [lib/renderer/base_chart_painter.dart](lib/renderer/base_chart_painter.dart) | 绘制基类，定义坐标系统和动态边距 |
| [lib/renderer/main_renderer.dart](lib/renderer/main_renderer.dart) | 主图渲染器（蜡烛图、MA、BOLL、SAR）、动态宽度算法 |
| [lib/renderer/vol_renderer.dart](lib/renderer/vol_renderer.dart) | 成交量渲染器 |
| [lib/renderer/secondary_renderer.dart](lib/renderer/secondary_renderer.dart) | 副图渲染器（MACD、KDJ、RSI、WR、CCI） |
| [lib/renderer/base_dimension.dart](lib/renderer/base_dimension.dart) | 尺寸计算器，管理各区域高度 |
| [lib/entity/k_line_entity.dart](lib/entity/k_line_entity.dart) | K 线数据模型 |
| [lib/entity/k_entity.dart](lib/entity/k_entity.dart) | 指标数据混入基类 |
| [lib/utils/data_util.dart](lib/utils/data_util.dart) | 技术指标计算工具 |
| [lib/chart_style.dart](lib/chart_style.dart) | 样式配置（动态宽度、十字线、弹窗样式等） |
| [lib/chart_colors.dart](lib/chart_colors.dart) | 颜色配置 |
| [lib/components/popup_info_view.dart](lib/components/popup_info_view.dart) | 价格信息弹窗组件 |

---

## 结语

这个 K 线图项目展示了 Flutter 在自定义绘制领域的强大能力。通过深入理解 Canvas 绘制、坐标变换、手势识别和性能优化，可以构建出媲美原生的高性能图表组件。

核心实现思路：
1. **数据驱动**: 使用规范的数据模型，通过计算工具统一处理
2. **分层渲染**: 主图、成交量、副图独立渲染，职责清晰
3. **精确坐标**: 建立完善的坐标转换体系，支持缩放、滚动和动态边距
4. **流畅交互**: 统一手势处理，焦点锚定缩放，惯性动画，边界检测
5. **性能优先**: 可见区域裁剪，对象复用，动态宽度算法
6. **高度可配置**: 丰富的样式配置项，支持深度定制

掌握这些技术，你也可以实现复杂的自定义图表组件！
