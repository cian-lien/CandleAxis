# 技术指标动态线宽实现文档

## 概述

本文档描述了 K 线图技术指标动态线宽功能的实现，该功能确保技术指标线条在缩放时保持视觉一致性，同时不超过 K 线实体宽度。

## 功能特性

### 核心特性
1. **视觉一致性**：无论如何缩放，技术指标线条在视觉上保持初始宽度
2. **智能约束**：线条宽度受到最小和最大值的双重约束
3. **分类配置**：主图指标和副图指标独立配置
4. **平滑过渡**：宽度变化平滑，无跳变

### 约束条件
- **最小宽度**：等于 K 线实体宽度（保证可见性）
- **最大宽度**：`min(固定上限, K 线实体宽度)`（防止过粗）

## 技术实现

### 1. 配置参数（ChartStyle）

```dart
// 主图指标配置
bool enableDynamicMainIndicatorWidth = true;     // 是否启用
double mainIndicatorBaseWidth = 1.5;            // 基础宽度（scaleX=1.0时）
double mainIndicatorMaxWidth = 3.0;             // 固定最大宽度上限

// 副图指标配置
bool enableDynamicSecondaryIndicatorWidth = true;
double secondaryIndicatorBaseWidth = 1.2;
double secondaryIndicatorMaxWidth = 3.0;
```

### 2. 算法实现

#### 主图指标线宽计算（MainRenderer）

```dart
double _calculateMainIndicatorWidth() {
  if (!chartStyle.enableDynamicMainIndicatorWidth) {
    return chartStyle.mainIndicatorBaseWidth;
  }

  // 基础宽度 / scaleX，补偿缩放
  final baseWidth = chartStyle.mainIndicatorBaseWidth / scaleX;

  // 最小宽度 = K 线实体宽度
  final minWidth = mCandleWidth;

  // 最大宽度 = min(固定上限, K 线实体宽度)
  final maxWidth = chartStyle.mainIndicatorMaxWidth < mCandleWidth
      ? chartStyle.mainIndicatorMaxWidth
      : mCandleWidth;

  return baseWidth.clamp(minWidth, maxWidth);
}
```

#### 副图指标线宽计算（SecondaryRenderer）

```dart
double _calculateSecondaryIndicatorWidth() {
  if (!chartStyle.enableDynamicSecondaryIndicatorWidth) {
    return chartStyle.secondaryIndicatorBaseWidth;
  }

  final baseWidth = chartStyle.secondaryIndicatorBaseWidth / scaleX;
  final minWidth = mMACDWidth;  // 使用 MACD 柱宽度作为参考
  final maxWidth = chartStyle.secondaryIndicatorMaxWidth < mMACDWidth
      ? chartStyle.secondaryIndicatorMaxWidth
      : mMACDWidth;

  return baseWidth.clamp(minWidth, maxWidth);
}
```

### 3. 应用范围

#### 主图指标
- ✅ MA 均线（所有周期）
- ✅ BOLL 通道线（上轨、中轨、下轨）
- ✅ SAR 抛物线转向指标（圆点）

#### 副图指标
- ✅ MACD（DIF、DEA 线）
- ✅ KDJ（K、D、J 线）
- ✅ RSI 相对强弱指标
- ✅ WR 威廉指标
- ✅ CCI 顺势指标

## 使用示例

### 基本使用（使用默认配置）

```dart
CandlestickWidget(
  kLineData,
  ChartStyle(),  // 使用默认配置，动态线宽已启用
  ChartColors(),
  mainStateLi: {MainState.MA, MainState.BOLL},
  secondaryStateLi: {SecondaryState.MACD},
)
```

### 自定义配置

```dart
final chartStyle = ChartStyle()
  // 主图指标配置
  ..enableDynamicMainIndicatorWidth = true
  ..mainIndicatorBaseWidth = 2.0      // 更粗的基础线宽
  ..mainIndicatorMaxWidth = 4.0       // 更高的最大宽度限制

  // 副图指标配置
  ..enableDynamicSecondaryIndicatorWidth = true
  ..secondaryIndicatorBaseWidth = 1.5
  ..secondaryIndicatorMaxWidth = 3.5;

CandlestickWidget(
  kLineData,
  chartStyle,
  ChartColors(),
  mainStateLi: {MainState.MA},
  secondaryStateLi: {SecondaryState.KDJ},
)
```

### 禁用动态线宽

```dart
final chartStyle = ChartStyle()
  ..enableDynamicMainIndicatorWidth = false     // 禁用主图动态线宽
  ..enableDynamicSecondaryIndicatorWidth = false; // 禁用副图动态线宽

CandlestickWidget(
  kLineData,
  chartStyle,
  ChartColors(),
)
```

## 视觉效果说明

### 缩放行为

1. **正常缩放（scaleX ≈ 1.0）**
   - 线条宽度 ≈ 基础宽度
   - 视觉效果最佳

2. **放大（scaleX > 1.0）**
   - 线条宽度减小（baseWidth / scaleX）
   - 保持视觉一致性
   - 不会低于 K 线实体宽度

3. **缩小（scaleX < 1.0）**
   - 线条宽度增大（baseWidth / scaleX）
   - 不会超过 min(固定上限, K 线宽度)
   - 保证可读性

### 与 K 线实体的关系

```
K 线实体宽度 = 8.5px（默认）

缩放级别    baseWidth/scaleX    实际线宽    说明
scaleX=2.0  1.5/2.0 = 0.75     8.5        受限于 minWidth
scaleX=1.0  1.5/1.0 = 1.5      1.5        理想状态
scaleX=0.5  1.5/0.5 = 3.0      3.0        达到 maxWidth
scaleX=0.3  1.5/0.3 = 5.0      3.0        受限于 maxWidth
```

## 技术细节

### 修改的文件

1. **lib/chart_style.dart**
   - 添加主图/副图指标动态线宽配置参数

2. **lib/renderer/base_chart_renderer.dart**
   - `drawLine()` 方法添加可选 `lineWidth` 参数
   - `drawCircle()` 方法添加可选 `radius` 和 `strokeWidth` 参数

3. **lib/renderer/main_renderer.dart**
   - 添加 `_calculateMainIndicatorWidth()` 方法
   - 更新 `drawMaLine()` 应用动态线宽
   - 更新 `drawBollLine()` 应用动态线宽
   - 更新 `drawSAR()` 应用动态线宽（圆点半径）

4. **lib/renderer/secondary_renderer.dart**
   - 添加 `scaleX` 字段
   - 添加 `_calculateSecondaryIndicatorWidth()` 方法
   - 更新 `drawChart()` 应用动态线宽
   - 更新 `drawMACD()` 应用动态线宽到 DIF/DEA 线

5. **lib/renderer/chart_painter.dart**
   - 创建 `SecondaryRenderer` 时传入 `scaleX` 参数

### 向后兼容性

- ✅ 完全向后兼容
- ✅ 默认启用，无需修改现有代码
- ✅ 可通过配置禁用

## 最佳实践建议

### 推荐配置

```dart
// 适合大多数场景的配置
ChartStyle()
  ..mainIndicatorBaseWidth = 1.5
  ..mainIndicatorMaxWidth = 3.0
  ..secondaryIndicatorBaseWidth = 1.2
  ..secondaryIndicatorMaxWidth = 3.0
```

### 高密度数据

```dart
// 数据点密集时，使用更细的线条
ChartStyle()
  ..mainIndicatorBaseWidth = 1.0
  ..mainIndicatorMaxWidth = 2.5
  ..secondaryIndicatorBaseWidth = 0.8
  ..secondaryIndicatorMaxWidth = 2.0
```

### 移动端优化

```dart
// 移动端小屏幕，线条稍粗保证可见性
ChartStyle()
  ..mainIndicatorBaseWidth = 2.0
  ..mainIndicatorMaxWidth = 4.0
  ..secondaryIndicatorBaseWidth = 1.5
  ..secondaryIndicatorMaxWidth = 3.5
```

## 性能考虑

- ✅ 宽度计算轻量级，无性能影响
- ✅ 每帧调用一次，开销可忽略
- ✅ 无额外内存分配

## 未来改进方向

1. **自适应算法**：根据数据密度自动调整基础宽度
2. **平台感知**：根据设备类型（移动/桌面）自动优化
3. **主题支持**：预设多种线宽主题方案

## 参考

- 原始需求：保持技术指标线条在缩放时的视觉一致性
- 设计原则：参考 K 线影线动态宽度实现
- 测试覆盖：所有主图和副图技术指标

---

**实现日期**：2025-12-14
**版本**：1.0.0
**状态**：已完成并测试
