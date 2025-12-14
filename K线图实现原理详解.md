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

#### 4.1 多手势识别器组合

**文件位置**: [lib/candlestick_widget.dart:222](lib/candlestick_widget.dart#L222)

```dart
return RawGestureDetector(
  behavior: HitTestBehavior.opaque,
  gestures: <Type, GestureRecognizerFactory>{
    // 1. 水平拖拽 - 图表滚动
    HorizontalDragGestureRecognizer: ...,

    // 2. 缩放手势 - 双指缩放
    ScaleGestureRecognizer: ...,

    // 3. 点击手势 - 显示信息弹窗
    TapGestureRecognizer: ...,

    // 4. 长按手势 - 十字线和详情
    LongPressGestureRecognizer: ...,
  },
  child: Stack(
    children: [
      CustomPaint(painter: painter),
      if (widget.showInfoDialog) _buildInfoDialog()
    ],
  ),
);
```

#### 4.2 水平拖拽实现

**文件位置**: [lib/candlestick_widget.dart:228](lib/candlestick_widget.dart#L228)

```dart
HorizontalDragGestureRecognizer:
  GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
    () => HorizontalDragGestureRecognizer(),
    (instance) {
      instance
        ..onStart = (details) {
          isScale = true;
          _boundaryOverscroll = 0.0;  // 重置边界滑动累积
          _stopAnimation();
        }
        ..onUpdate = (details) {
          if (isLongPress) return;

          // 单指平移
          final delta = details.delta.dx;
          mScrollX = (delta / mScaleX + mScrollX)
              .clamp(0.0, ChartPainter.maxScrollX)
              .toDouble();

          // 边界检测和回调
          if (widget.onReachBoundary != null) {
            // 在左边界且向右滑动
            if (mScrollX <= 0 && delta > 0) {
              _boundaryOverscroll += delta;
              if (_boundaryOverscroll > 50) {
                widget.onReachBoundary!(true);  // 触发加载更多
                _boundaryOverscroll = 0.0;
              }
            }
            // 在右边界且向左滑动
            else if (mScrollX >= ChartPainter.maxScrollX && delta < 0) {
              _boundaryOverscroll += delta.abs();
              if (_boundaryOverscroll > 50) {
                widget.onReachBoundary!(false);
                _boundaryOverscroll = 0.0;
              }
            }
          }

          notifyChanged();
        }
        ..onEnd = (details) {
          isScale = false;
          var velocity = details.velocity.pixelsPerSecond.dx;
          _onFling(velocity);  // 惯性滚动
        };
    },
  ),
```

**交互细节**:
- 考虑缩放比例的拖拽距离计算
- 边界累积滑动距离，避免误触发
- 惯性滚动增强用户体验

#### 4.3 双指缩放实现

**文件位置**: [lib/candlestick_widget.dart:285](lib/candlestick_widget.dart#L285)

```dart
ScaleGestureRecognizer:
  GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
    () => ScaleGestureRecognizer(),
    (instance) {
      instance
        ..onStart = (details) {
          if (details.pointerCount >= 2) {
            isScale = true;
            _initialPointerCount = details.pointerCount;
            _stopAnimation();
          }
        }
        ..onUpdate = (details) {
          if (details.pointerCount >= 2) {
            // 限制缩放范围在 0.2 ~ 4.0
            mScaleX = (_lastScale * details.scale).clamp(0.2, 4.0);

            // 自动切换分时图模式
            if (widget.autoSwitchToLine) {
              _isAutoLine = mScaleX <= widget.lineThreshold;
            }

            notifyChanged();
          }
        }
        ..onEnd = (details) {
          isScale = false;
          _lastScale = mScaleX;
        };
    },
  ),
```

**缩放特性**:
- 支持 0.2 ~ 4 倍缩放
- 缩放到阈值以下自动切换分时图
- 记录最后缩放值，支持连续缩放

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

#### 5.1 十字线绘制

**文件位置**: [lib/renderer/chart_painter.dart:537](lib/renderer/chart_painter.dart#L537)

```dart
void drawCrossLine(Canvas canvas, Size size) {
  var index = calculateSelectedX(selectX);
  KLineEntity point = getItem(index);

  double x = getX(index);
  double y = getMainY(point.close);

  // 垂直线
  Paint paintY = Paint()
    ..color = this.chartColors.vCrossColor
    ..strokeWidth = this.chartStyle.vCrossWidth
    ..isAntiAlias = true;
  canvas.drawLine(
    Offset(x, mTopPadding),
    Offset(x, size.height - mBottomPadding),
    paintY
  );

  // 水平线
  Paint paintX = Paint()
    ..color = this.chartColors.hCrossColor
    ..strokeWidth = this.chartStyle.hCrossWidth
    ..isAntiAlias = true;
  canvas.drawLine(
    Offset(-mTranslateX, y),
    Offset(-mTranslateX + mWidth / scaleX, y),
    paintX
  );

  // 中心点圆圈（根据缩放自适应大小）
  if (scaleX >= 1) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
      paintX,
    );
  } else {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
      paintX,
    );
  }
}
```

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

**文件位置**: [lib/renderer/base_chart_painter.dart:217](lib/renderer/base_chart_painter.dart#L217)

```dart
calculateValue() {
  if (datas == null || datas!.isEmpty) return;

  maxScrollX = getMinTranslateX().abs();
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

**文件位置**: [lib/renderer/base_chart_painter.dart:426](lib/renderer/base_chart_painter.dart#L426)

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
  onReachBoundary: (isLeft) {
    // 滑动到边界回调
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
    candleLineWidth: 1.5,       // 影线宽度
    gridRows: 4,                // 网格行数
    gridColumns: 4,             // 网格列数
  ),
  ChartColors(
    bgColor: Color(0xff18191d),
    upColor: Color(0xff00ff00),
    dnColor: Color(0xffff0000),
    ma5Color: Color(0xffC9B885),
    ma10Color: Color(0xff6CB0A6),
    ma30Color: Color(0xff9979C6),
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
)
```

---

## 技术亮点总结

### 1. 架构设计
- ✅ 分层架构：数据层 → 计算层 → 渲染层 → 交互层
- ✅ Mixin 组合模式实现指标模块化
- ✅ 抽象类和模板方法确保绘制流程一致性

### 2. 算法优化
- ✅ 滑动窗口算法计算 MA，时间复杂度 O(n)
- ✅ 二分查找定位可见数据，时间复杂度 O(log n)
- ✅ 可见区域裁剪，避免无效绘制

### 3. 渲染优化
- ✅ Canvas 直接绘制，性能优于 Widget 组合
- ✅ 路径对象复用，减少 GC 压力
- ✅ 贝塞尔曲线实现平滑折线

### 4. 交互体验
- ✅ 多手势识别器组合（拖拽、缩放、点击、长按）
- ✅ 惯性滚动动画，自然流畅
- ✅ 边界累积触发，避免误操作
- ✅ 动态信息弹窗，智能避开十字线

### 5. 扩展性
- ✅ 支持自定义样式和颜色
- ✅ 支持自定义时间格式
- ✅ 支持自定义价格格式化
- ✅ 支持多种技术指标组合

---

## 关键文件索引

| 文件路径 | 功能说明 |
|---------|---------|
| [lib/candlestick_widget.dart](lib/candlestick_widget.dart) | 主 Widget，处理手势和状态管理 |
| [lib/renderer/chart_painter.dart](lib/renderer/chart_painter.dart) | 绘制协调器，管理渲染流程 |
| [lib/renderer/base_chart_painter.dart](lib/renderer/base_chart_painter.dart) | 绘制基类，定义坐标系统 |
| [lib/renderer/main_renderer.dart](lib/renderer/main_renderer.dart) | 主图渲染器（蜡烛图、MA、BOLL） |
| [lib/renderer/vol_renderer.dart](lib/renderer/vol_renderer.dart) | 成交量渲染器 |
| [lib/renderer/secondary_renderer.dart](lib/renderer/secondary_renderer.dart) | 副图渲染器（MACD、KDJ 等） |
| [lib/entity/k_line_entity.dart](lib/entity/k_line_entity.dart) | K 线数据模型 |
| [lib/entity/k_entity.dart](lib/entity/k_entity.dart) | 指标数据混入基类 |
| [lib/utils/data_util.dart](lib/utils/data_util.dart) | 技术指标计算工具 |
| [lib/chart_style.dart](lib/chart_style.dart) | 样式配置 |
| [lib/chart_colors.dart](lib/chart_colors.dart) | 颜色配置 |

---

## 结语

这个 K 线图项目展示了 Flutter 在自定义绘制领域的强大能力。通过深入理解 Canvas 绘制、坐标变换、手势识别和性能优化，可以构建出媲美原生的高性能图表组件。

核心实现思路：
1. **数据驱动**: 使用规范的数据模型，通过计算工具统一处理
2. **分层渲染**: 主图、成交量、副图独立渲染，职责清晰
3. **精确坐标**: 建立完善的坐标转换体系，支持缩放和滚动
4. **流畅交互**: 多手势组合，惯性动画，边界检测
5. **性能优先**: 可见区域裁剪，对象复用，智能重绘

掌握这些技术，你也可以实现复杂的自定义图表组件！
