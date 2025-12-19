# K 线图源码学习指南

## 项目概览

这是一个基于 Flutter 的高性能 K 线图库，支持多种技术指标、手势交互和自定义样式。本指南将帮助你系统地学习和理解源码实现。

### 核心特性
- 完整的 K 线图和分时图显示
- 多种技术指标：MA、BOLL、MACD、KDJ、RSI、WR、CCI、SAR
- 流畅的手势交互：拖拽、缩放、长按、点击
- 自定义样式和颜色配置
- 十字线和信息弹窗
- 边界加载更多数据
- 趋势线绘制（可选）

## 学习路径

建议按以下顺序学习源码，从数据层到视图层，逐步深入：

### 阶段一：基础数据结构（1-2小时）
理解 K 线数据的组织方式和技术指标的计算原理

### 阶段二：绘制系统（2-3小时）
学习 Flutter CustomPainter 的使用和图表渲染机制

### 阶段三：交互系统（2-3小时）
深入理解手势识别、动画和状态管理

### 阶段四：高级功能（1-2小时）
学习边界加载、自定义配置等高级特性

---

## 阶段一：基础数据结构

### 1. 数据实体类（lib/entity/）

#### 核心文件：[k_line_entity.dart](lib/entity/k_line_entity.dart)

**学习重点：**
- K 线的基本数据结构：开盘价(open)、最高价(high)、最低价(low)、收盘价(close)、成交量(vol)
- JSON 数据的解析和序列化
- 时间戳的处理

```dart
// K 线实体包含的核心字段
class KLineEntity {
  double open;    // 开盘价
  double high;    // 最高价
  double low;     // 最低价
  double close;   // 收盘价
  double vol;     // 成交量
  int? time;      // 时间戳（毫秒）
}
```

**实践建议：**
1. 查看 `fromJson` 和 `fromCustom` 两种构造方法的区别
2. 理解为什么使用 late 关键字
3. 注意时间戳的单位（毫秒）

#### 技术指标实体（lib/entity/）

K 线实体通过继承扩展了各种技术指标字段：

- [k_entity.dart](lib/entity/k_entity.dart) - 基础 K 线实体
- [macd_entity.dart](lib/entity/macd_entity.dart) - MACD 指标（dif、dea、macd）
- [kdj_entity.dart](lib/entity/kdj_entity.dart) - KDJ 指标（k、d、j）
- [rsi_entity.dart](lib/entity/rsi_entity.dart) - RSI 指标
- [volume_entity.dart](lib/entity/volume_entity.dart) - 成交量 MA

**继承关系：**
```
KLineEntity
  └─ extends KEntity
       └─ with MACDEntity, KDJEntity, RSIEntity, ...
```

### 2. 技术指标计算（lib/utils/data_util.dart）⭐

这是最重要的工具类，包含所有技术指标的计算逻辑。

**学习要点：**

#### 2.1 入口函数：`calculate()`
```dart
DataUtil.calculate(
  List<KLineEntity> dataList,  // K 线数据
  [5, 10, 20],                  // MA 周期
  20,                            // BOLL 周期
  2                             // BOLL 标准差倍数
);
```

这个函数会依次计算所有指标，直接修改 dataList。

#### 2.2 核心算法：MA（移动平均线）

**算法亮点：** 使用滑动窗口优化，时间复杂度 O(n)

```dart
// 关键代码解析（简化版）
void calcMA(List<KLineEntity> dataList, List<int> maDayList) {
  List<double> ma = [0, 0, 0];  // 存储各周期的累加和

  for (int i = 0; i < dataList.length; i++) {
    double close = dataList[i].close;

    for (int j = 0; j < maDayList.length; j++) {
      ma[j] += close;  // 累加

      if (i >= maDayList[j]) {
        // 窗口滑动：减去最早的值
        ma[j] -= dataList[i - maDayList[j]].close;
        dataList[i].maValueList[j] = ma[j] / maDayList[j];
      }
    }
  }
}
```

**学习建议：**
1. 手动计算前 10 个数据点的 MA5 值，验证算法正确性
2. 思考为什么不用简单的嵌套循环（会是 O(n²)）
3. 对比 MACD 的 EMA 算法（指数移动平均）

#### 2.3 MACD 计算详解

MACD 是最重要的趋势指标，理解其计算公式：

```dart
// 指数移动平均（EMA）计算
ema12 = ema12 * 11/13 + closePrice * 2/13;  // 12日EMA
ema26 = ema26 * 25/27 + closePrice * 2/27;  // 26日EMA

// 三条线
dif = ema12 - ema26;              // 快线（差离值）
dea = dea * 8/10 + dif * 2/10;    // 慢线（信号线）
macd = (dif - dea) * 2;           // 柱状图
```

**关键理解：**
- EMA 公式：新 EMA = 旧 EMA × (n-1)/(n+1) + 今日价格 × 2/(n+1)
- DIF 上穿 DEA = 金叉（买入信号）
- DIF 下穿 DEA = 死叉（卖出信号）

#### 2.4 其他指标概览

| 指标 | 文件位置 | 用途 | 学习难度 |
|------|----------|------|----------|
| KDJ | `calcKDJ()` | 随机指标，判断超买超卖 | ⭐⭐ |
| RSI | `calcRSI()` | 相对强弱，判断趋势强度 | ⭐⭐ |
| BOLL | `calcBOLL()` | 布林带，判断价格波动 | ⭐⭐⭐ |
| SAR | `calcSAR()` | 抛物线转向，判断趋势反转 | ⭐⭐⭐ |
| WR | `calcWR()` | 威廉指标 | ⭐ |
| CCI | `calcCCI()` | 顺势指标 | ⭐⭐ |

**实践任务：**
1. 在 [main.dart:93](example/lib/main.dart#L93) 看到 `DataUtil.calculate(data)` 的实际使用
2. 尝试修改 MA 周期，观察图表变化
3. 阅读每个指标的维基百科，理解其金融含义

---

## 阶段二：绘制系统

### 3. 图表绘制架构

#### 架构概览

```
CandlestickWidget (Widget层)
    └─ ChartPainter (CustomPainter)
         ├─ BaseChartPainter (基类，坐标转换)
         │    ├─ 计算坐标系统
         │    ├─ 管理缩放和滚动
         │    └─ 计算可见区域
         │
         └─ 渲染器集合
              ├─ MainRenderer (主图)
              ├─ VolRenderer (成交量)
              └─ SecondaryRenderer (副图指标)
```

### 4. 基础绘制类（lib/renderer/base_chart_painter.dart）⭐⭐⭐

这是整个绘制系统的核心基类，负责坐标系统和数据映射。

#### 4.1 核心概念：坐标系统

**三种坐标：**
1. **数据索引（index）**：0, 1, 2, ... 表示第几个 K 线
2. **逻辑坐标（logic X）**：以 mPointWidth 为单位的抽象坐标
3. **屏幕坐标（screen X）**：实际像素位置

**转换关系：**
```dart
// 索引 → 逻辑坐标
double getX(int index) {
  return (index - mStartIndex) * mPointWidth + mPointWidth / 2;
}

// 逻辑坐标 → 屏幕坐标
double translateXtoX(double logicX) {
  return (logicX + mTranslateX) * scaleX;
}

// 价格值 → 屏幕 Y 坐标
double getMainY(double price) {
  return (mMainMaxValue - price) * scale + mMainRect.top;
}
```

**学习要点：**
- `mTranslateX`：控制整体平移（用于滚动）
- `scaleX`：水平缩放倍数（1.0 = 正常，2.0 = 放大 2 倍）
- `mPointWidth`：每根 K 线的宽度（逻辑单位）

#### 4.2 关键方法：`calculateValue()`

每次绘制前都会调用，计算可见区域的数据：

```dart
void calculateValue() {
  // 1. 计算可见区域的起止索引
  mStartIndex = indexOfTranslateX(-mTranslateX);
  mStopIndex = indexOfTranslateX(-mTranslateX + mWidth / scaleX);

  // 2. 遍历可见区域，找出价格的最大最小值
  for (int i = mStartIndex; i <= mStopIndex; i++) {
    mMainMaxValue = max(mMainMaxValue, data[i].high);
    mMainMinValue = min(mMainMinValue, data[i].low);
    // ... 同时计算成交量和副图指标的最大最小值
  }
}
```

**为什么重要：**
- 决定了 Y 轴的比例尺
- 优化性能：只计算可见区域的数据
- 实现自适应：缩放时自动调整比例

#### 4.3 绘制流程（paint 方法）

```dart
@override
void paint(Canvas canvas, Size size) {
  // 1. 初始化矩形区域
  initRect(size);

  // 2. 计算可见数据的范围
  calculateValue();

  // 3. 初始化渲染器
  initChartRenderer();

  // 4. 绘制各个层次
  drawBg(canvas, size);        // 背景
  drawGrid(canvas);            // 网格
  drawChart(canvas, size);     // K线和指标
  drawVerticalText(canvas);    // Y轴价格文字
  drawDate(canvas, size);      // X轴日期
  drawMaxAndMin(canvas);       // 最高最低价标注
  drawNowPrice(canvas);        // 当前价格线
  drawCrossLineText(canvas, size); // 十字线（如果有）
}
```

### 5. 主图渲染器（lib/renderer/main_renderer.dart）

负责绘制 K 线图和主图指标（MA、BOLL、SAR）。

#### 5.1 蜡烛图绘制（drawChart）

**核心代码简化：**
```dart
void drawChart(...) {
  // 1. 计算蜡烛实体的矩形
  double top = getY(max(curPoint.open, curPoint.close));
  double bottom = getY(min(curPoint.open, curPoint.close));
  double left = curX - mCandleWidth / 2;
  double right = curX + mCandleWidth / 2;

  // 2. 绘制影线（high-low 线）
  canvas.drawLine(
    Offset(curX, getY(curPoint.high)),
    Offset(curX, getY(curPoint.low)),
    shadowPaint
  );

  // 3. 绘制实体（open-close 矩形）
  canvas.drawRect(
    Rect.fromLTRB(left, top, right, bottom),
    curPoint.close > curPoint.open ? upPaint : downPaint
  );
}
```

**学习要点：**
- 涨跌颜色：收盘价 > 开盘价 = 红色（涨），反之 = 绿色（跌）
- 影线宽度：需要补偿 scaleX 的影响（在 [candlestick_widget.dart:561](lib/candlestick_widget.dart#L561) 可见）
- 分时图模式：绘制折线图而不是蜡烛图

#### 5.2 MA 指标绘制

```dart
// 遍历每个周期的 MA 线
for (int i = 0; i < maDayList.length; i++) {
  if (lastPoint.maValueList?[i] != null && curPoint.maValueList?[i] != null) {
    // 连接前后两个点
    canvas.drawLine(
      Offset(lastX, getY(lastPoint.maValueList![i])),
      Offset(curX, getY(curPoint.maValueList![i])),
      maPaint..color = chartColors.getMAColor(i)
    );
  }
}
```

### 6. 成交量渲染器（lib/renderer/vol_renderer.dart）

绘制成交量柱状图和成交量 MA。

**特点：**
- 独立的 Y 轴范围（mVolMaxValue - mVolMinValue）
- 颜色跟随 K 线涨跌色
- 可选隐藏（volHidden 参数）

### 7. 副图渲染器（lib/renderer/secondary_renderer.dart）

支持多个副图指标同时显示（MACD、KDJ、RSI 等）。

**设计亮点：**
- 每个副图有独立的矩形区域（mSecondaryRectList）
- 动态计算高度（根据启用的指标数量）
- 共享相同的绘制接口（BaseChartRenderer）

---

## 阶段三：交互系统

### 8. 交互管理（lib/candlestick_widget.dart）⭐⭐⭐⭐

这是整个项目最复杂的部分，处理所有用户交互。

#### 8.1 手势系统架构

**关键组件：**
```dart
Listener(
  onPointerDown: (_) => _pointerCount++,  // 跟踪手指数量
  child: RawGestureDetector(
    gestures: {
      ScaleGestureRecognizer,    // 拖拽 + 缩放
      TapGestureRecognizer,      // 点击
      LongPressGestureRecognizer // 长按
    }
  )
)
```

**为什么这样设计？**
- `Listener` 实时跟踪手指数量（_pointerCount）
- `ScaleGestureRecognizer` 统一处理单指拖拽和双指缩放
- 避免手势竞技场冲突（不使用 HorizontalDragGestureRecognizer）

#### 8.2 拖拽实现（单指）

**核心逻辑（简化）：**
```dart
onUpdate: (details) {
  if (_pointerCount == 1) {
    // 单指拖拽
    final dx = details.focalPointDelta.dx;
    final delta = (dx / mScaleX) * panSensitivity;  // 补偿缩放影响

    mScrollX = (mScrollX + delta).clamp(0.0, maxScrollX);

    // 边界检测
    if (mScrollX >= maxScrollX && dx > 0) {
      _boundaryOverscroll += dx.abs();
      if (_boundaryOverscroll > boundaryThreshold) {
        _triggerBoundaryCallback(true);  // 加载历史数据
      }
    }
  }
}
```

**关键点：**
1. 使用 `focalPointDelta` 而不是 `focalPoint` 的变化量
2. 除以 `mScaleX` 保证放大后滑动速度一致
3. 边界累积超过阈值才触发加载（防抖）

#### 8.3 缩放实现（双指）⭐⭐⭐⭐

**最难的部分：焦点锚定缩放**

**目标：** 缩放时保持焦点位置的 K 线不动

**实现步骤：**
```dart
// 1. 手势开始时记录锚点
onStart: (details) {
  _anchorScreenX = details.focalPoint.dx;  // 焦点的屏幕位置
  _anchorIndex = calculateSelectedX(_anchorScreenX);  // 焦点对应的数据索引
}

// 2. 缩放时调整 scrollX，保持锚点位置
onUpdate: (details) {
  if (_pointerCount >= 2) {
    // 计算新的缩放倍数
    final relativeScale = details.scale / _scaleBase;
    final newScaleX = (_scaleXBase * relativeScale).clamp(0.2, 4.0);

    // 计算锚点的逻辑坐标
    final anchorLogicX = painter.getX(_anchorIndex);

    // 反推 scrollX，使锚点显示在 _anchorScreenX 位置
    final newTranslateX = _anchorScreenX / newScaleX - anchorLogicX;
    mScrollX = (newTranslateX - minTranslateX).clamp(0.0, maxScrollX);

    mScaleX = newScaleX;
  }
}
```

**为什么复杂？**
- 需要在三种坐标系统之间转换
- 要处理 1→2 指、2→1 指的过渡（焦点会跳动）
- 必须同时更新 scaleX 和 scrollX

**学习建议：**
1. 在 [candlestick_widget.dart:552-584](lib/candlestick_widget.dart#L552-L584) 仔细阅读注释
2. 在纸上画出坐标转换的示意图
3. 修改代码，去掉 scrollX 的调整，观察缩放效果的差异

#### 8.4 手指数量过渡处理

**问题：** 从单指拖拽切换到双指缩放时，焦点会突然跳变

**解决方案：**
```dart
onUpdate: (details) {
  // 检测手指数量变化
  if (_pointerCount != _lastPointerCount) {
    // 重置基线，避免画面跳动
    _scaleBase = details.scale;
    _scaleXBase = mScaleX;
    _anchorScreenX = details.focalPoint.dx;
    _anchorIndex = painter.calculateSelectedX(_anchorScreenX);
    _lastPointerCount = _pointerCount;
  }

  // ... 继续处理手势
}
```

**关键理解：**
- 使用**相对缩放**而不是绝对缩放
- 每次手指数量变化时重置基线
- 这是实现流畅过渡的关键技巧

#### 8.5 惯性滚动动画

手指离开时启动惯性滚动：

```dart
void _onFling(double velocity) {
  _controller = AnimationController(duration: Duration(milliseconds: 600));

  aniX = Tween<double>(
    begin: mScrollX,
    end: mScrollX + (velocity * flingRatio * panSensitivity)
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));

  aniX.addListener(() {
    mScrollX = aniX.value;
    // 到达边界时停止并触发加载
    if (mScrollX >= maxScrollX) {
      _stopAnimation();
      _triggerBoundaryCallback(true);
    }
  });

  _controller.forward();
}
```

**参数调节：**
- `flingTime`：动画持续时间（默认 600ms）
- `flingRatio`：速度衰减系数（默认 0.5）
- `flingCurve`：动画曲线（默认 Curves.decelerate）

#### 8.6 十字线交互

**三种显示方式：**
1. **长按显示**：长按时显示，移动手指跟随
2. **点击切换**：点击空白区域切换显示/隐藏
3. **锁定显示**：长按结束后保持显示

**状态管理：**
```dart
bool isLongPress = false;  // 正在长按
bool isOnTap = false;      // 已点击
bool _isCrossLocked = false; // 十字线锁定显示

// 滑动或缩放时自动隐藏
if (_isCrossLocked) {
  _isCrossLocked = false;
  isOnTap = false;
  mInfoWindowStream.sink.add(null);
}
```

#### 8.7 信息弹窗（StreamBuilder）

**数据流：**
```
ChartPainter (绘制层)
    ↓ (计算选中的数据)
StreamController<InfoWindowEntity>
    ↓
StreamBuilder (Widget层)
    ↓
PopupInfoView (显示弹窗)
```

**为什么用 Stream？**
- 绘制层（ChartPainter）无法直接更新 Widget
- Stream 实现跨层通信
- 避免频繁 rebuild 整个 Widget

---

## 阶段四：高级功能

### 9. 边界加载更多数据⭐⭐⭐

#### 9.1 实现原理

**触发条件：**
1. 滑动到左边界（历史数据）或右边界（最新数据）
2. 继续滑动超过阈值（默认 50 像素）
3. 距离上次触发超过防抖延迟（默认 1 秒）

**代码位置：** [candlestick_widget.dart:514-536](lib/candlestick_widget.dart#L514-L536)

```dart
// 边界检测
if (mScrollX >= maxScrollX && dx > 0) {
  _boundaryOverscroll += dx.abs();
  if (_boundaryOverscroll > boundaryThreshold) {
    _triggerBoundaryCallback(true);  // isLeft = true
    _boundaryOverscroll = 0.0;
  }
}
```

#### 9.2 使用示例

在 [main.dart:221-223](example/lib/main.dart#L221-L223) 查看完整示例：

```dart
CandlestickWidget(
  data,
  ChartStyle(),
  ChartColors(),
  onReachBoundary: (isLeft) async {
    // isLeft = true: 加载历史数据
    // isLeft = false: 加载最新数据

    await Future.delayed(Duration(seconds: 2)); // 模拟网络请求

    // 生成新数据
    final newData = generateMoreData();

    // 合并数据
    setState(() {
      _kLineData = [...newData, ..._kLineData];
    });
  },
  // 自定义加载指示器
  loadingIndicatorBuilder: (isLeft) {
    return Container(...); // 你的加载组件
  },
  // 错误处理
  loadingErrorBuilder: (isLeft, error, retry) {
    return Container(...); // 错误提示 + 重试按钮
  },
)
```

#### 9.3 视口恢复（重要）⭐⭐⭐

**问题：** 加载历史数据后，用户看到的 K 线会跳动

**解决方案：** 使用视口快照
```dart
// 1. 加载前保存快照
final snapshot = _candlestickWidgetState.createViewportSnapshot();

// 2. 加载新数据
final newData = await loadHistoryData();
setState(() {
  _kLineData = [...newData, ..._kLineData];
});

// 3. 恢复视口
_candlestickWidgetState.restoreViewport(snapshot, newData.length);
```

**实现原理：**
- 记录加载前的 scrollX 和数据长度
- 加载后调整 scrollX，补偿新增数据的长度
- 保证用户看到的 K 线位置不变

### 10. 自定义配置

#### 10.1 样式配置（ChartStyle）

**文件位置：** [lib/chart_style.dart](lib/chart_style.dart)

**常用配置：**
```dart
ChartStyle(
  pointWidth: 11.0,         // K线宽度
  candleWidth: 8.5,         // 蜡烛实体宽度
  candleLineWidth: 1.5,     // 影线宽度
  gridRows: 4,              // 网格行数
  gridColumns: 4,           // 网格列数
  vCrossWidth: 0.5,         // 十字线竖线宽度
  hCrossWidth: 0.5,         // 十字线横线宽度
  nowPriceLineWidth: 1.0,   // 当前价格线宽度
)
```

#### 10.2 颜色配置（ChartColors）

```dart
ChartColors(
  bgColor: Color(0xFF0D141E),        // 背景色
  upColor: Color(0xFF00A756),        // 涨色
  dnColor: Color(0xFFE74C3C),        // 跌色
  ma5Color: Color(0xFFC9B885),       // MA5 颜色
  ma10Color: Color(0xFF6CB0A6),      // MA10 颜色
  ma30Color: Color(0xFF9979C6),      // MA30 颜色
  gridColor: Color(0xFF4C5265),      // 网格线颜色
  // ... 更多颜色配置
)
```

#### 10.3 价格格式化

```dart
CandlestickWidget(
  data,
  priceFormatter: (price) {
    return '¥${price.toStringAsFixed(2)}';  // 添加货币符号
  },
)
```

#### 10.4 自动切换分时图

```dart
CandlestickWidget(
  data,
  autoSwitchToLine: true,   // 启用自动切换
  lineThreshold: 0.5,       // 缩放到 0.5 以下时切换
)
```

### 11. 性能优化要点

#### 11.1 只绘制可见区域

**代码位置：** [base_chart_painter.dart:mStartIndex, mStopIndex](lib/renderer/base_chart_painter.dart)

```dart
// 只遍历可见的 K 线
for (int i = mStartIndex; i <= mStopIndex; i++) {
  drawCandle(datas[i]);
}
```

**收益：** 即使数据有 10000 条，每次只绘制屏幕上的约 50-100 条

#### 11.2 技术指标预计算

所有指标在 `DataUtil.calculate()` 中一次性计算完成，绘制时直接读取，无需重复计算。

#### 11.3 滑动窗口算法

MA 计算使用滑动窗口，避免每个点都遍历前 N 个数据。

---

## 核心文件速查表

| 文件 | 功能 | 重要程度 | 代码量 |
|------|------|----------|--------|
| [candlestick_widget.dart](lib/candlestick_widget.dart) | 主 Widget，手势交互 | ⭐⭐⭐⭐⭐ | 1000+ 行 |
| [chart_painter.dart](lib/renderer/chart_painter.dart) | 图表绘制入口 | ⭐⭐⭐⭐ | 700 行 |
| [base_chart_painter.dart](lib/renderer/base_chart_painter.dart) | 坐标系统基类 | ⭐⭐⭐⭐⭐ | 600 行 |
| [main_renderer.dart](lib/renderer/main_renderer.dart) | 主图渲染器 | ⭐⭐⭐⭐ | 500 行 |
| [data_util.dart](lib/utils/data_util.dart) | 技术指标计算 | ⭐⭐⭐⭐⭐ | 400 行 |
| [k_line_entity.dart](lib/entity/k_line_entity.dart) | K 线数据实体 | ⭐⭐⭐ | 60 行 |
| [chart_style.dart](lib/chart_style.dart) | 样式配置 | ⭐⭐ | 200 行 |
| [secondary_renderer.dart](lib/renderer/secondary_renderer.dart) | 副图渲染器 | ⭐⭐⭐ | 400 行 |
| [vol_renderer.dart](lib/renderer/vol_renderer.dart) | 成交量渲染器 | ⭐⭐ | 200 行 |

---

## 学习实践任务

### 入门级任务
1. 修改 MA 周期为 [7, 14, 30]，观察图表变化
2. 更改涨跌颜色为自定义颜色
3. 调整 K 线宽度和间距
4. 实现加载更多数据（参考 main.dart 示例）

### 中级任务
1. 添加一个新的技术指标（如 EMA）
2. 自定义信息弹窗的样式和内容
3. 实现双击快速缩放到默认级别
4. 添加水印或自定义绘制元素

### 高级任务
1. 优化缩放算法，支持更平滑的过渡
2. 实现 K 线数据的增量更新（WebSocket 实时数据）
3. 添加绘图工具（趋势线、斐波那契回撤等）
4. 实现多时间周期切换（1分钟、5分钟、日线等）

---

## 常见问题

### Q1: 为什么缩放时 K 线会跳动？
A: 需要实现焦点锚定缩放，参考 [candlestick_widget.dart:552-584](lib/candlestick_widget.dart#L552-L584)

### Q2: 如何实现实时更新数据？
A: 定时更新最后一个 KLineEntity，并调用 `setState()` 触发重绘

### Q3: 为什么自定义颜色不生效？
A: 确保传递了自定义的 `ChartColors` 对象，而不是使用默认构造函数

### Q4: 如何禁用某个功能？
A: 查看 CandlestickWidget 的构造参数，大部分功能都可以通过参数控制

### Q5: 技术指标显示不正确？
A: 确保在显示前调用了 `DataUtil.calculate(data)`

---

## 推荐学习资源

### Flutter 相关
- [CustomPainter 官方文档](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [手势识别系统](https://docs.flutter.dev/development/ui/advanced/gestures)
- [Canvas 绘制教程](https://docs.flutter.dev/cookbook/animation/draw-circle)

### 金融技术指标
- [MACD 指标详解](https://zh.wikipedia.org/wiki/MACD)
- [K 线图基础知识](https://zh.wikipedia.org/wiki/K线)
- [技术分析入门](https://www.investopedia.com/terms/t/technicalanalysis.asp)

### 算法与数据结构
- 滑动窗口算法
- EMA（指数移动平均）计算原理
- 坐标系转换数学

---

## 总结

### 核心技术点
1. Flutter CustomPainter 和 Canvas 绘图
2. 手势识别和动画
3. 坐标系统设计和转换
4. 技术指标算法实现
5. 性能优化（可见区域裁剪、预计算）

### 代码设计亮点
- **分层架构**：Widget 层、绘制层、渲染器层职责清晰
- **可扩展性**：新增指标只需添加渲染器
- **高性能**：只计算和绘制可见区域
- **用户体验**：流畅的手势交互、焦点锚定缩放

### 改进方向
- 支持更多图表类型（面积图、OHLC 图）
- 添加更多绘图工具
- 支持导出图表为图片
- 实现主题切换动画

---

**祝学习愉快！有问题欢迎在 GitHub Issues 中讨论。**
