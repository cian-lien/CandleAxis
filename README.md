# CandleX

一个用于金融数据可视化的 Flutter K 线图组件。

## 功能特性

- **K 线图**：支持蜡烛图和分时图模式
- **技术指标**：MA（均线）、BOLL（布林带）、SAR（抛物线转向）、MACD、KDJ、RSI、WR、CCI
- **深度图**：订单簿可视化
- **手势交互**：拖拽、双指缩放、长按十字线、点击切换十字线
- **趋势线**：支持绘制趋势线
- **自定义样式**：颜色、尺寸、弹窗信息、网格、价格格式化
- **边界加载**：滚动到边缘时自动触发数据加载，支持防抖和错误处理
- **国际化**：可配置文本翻译

## 快速开始

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  candlestick:
    path: ../  # 或你的包路径
```

## 使用方法

```dart
import 'package:candlestick/candlestick.dart';

// 1. 准备数据
List<KLineEntity> data = [...]; // 你的 OHLC 数据
DataUtil.calculate(data);       // 计算所有技术指标

// 2. 使用组件
CandlestickWidget(
  data,
  ChartStyle(),
  ChartColors(),
  isTrendLine: false,
  mainStateLi: {MainState.MA},
  secondaryStateLi: {SecondaryState.MACD},
)
```

## 项目结构

```
lib/
├── candlestick.dart          # 库入口，导出
├── candlestick_widget.dart   # 主图表组件（手势、布局）
├── chart_style.dart          # ChartColors 和 ChartStyle 配置
├── chart_translations.dart   # 国际化文本定义
├── depth_chart.dart          # 深度图（订单簿）
├── components/               # UI 组件（弹窗信息视图）
├── entity/                   # 数据模型（KLineEntity 等）
├── renderer/                 # Canvas 绘制器（主图、成交量、副图）
├── extension/                # Dart 扩展
└── utils/                    # DataUtil（指标计算）、日期/数字工具
```

## 环境要求

- Dart SDK: `>=3.0.5 <4.0.0`
- Flutter

## 致谢

本项目基于 [k_chart](https://github.com/OpenFlutter/k_chart) (OpenFlutter) 开发，感谢原作者的优秀工作！
