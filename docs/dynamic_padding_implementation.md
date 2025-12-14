# K线图动态边距实现详解

## 概述

本文档详细说明了K线图中**动态边距（Dynamic Padding）**功能的实现原理。该功能确保在不同缩放级别下，图表左右两侧的留白区域在视觉上保持一致的大小。

## 问题背景

### 原有实现的问题

在原始实现中，`xFrontPadding`（右侧留白）和 `xBackPadding`（左侧留白）使用**固定像素值**（例如100px）。这导致了以下用户体验问题：

#### 场景1：缩小K线时（scaleX < 1.0）
```
用户操作：双指捏合，缩小K线
问题：每根K线变窄，100px的固定留白显得过小
结果：用户几乎看不到明显的空白区域
```

#### 场景2：放大K线时（scaleX > 1.0）
```
用户操作：双指展开，放大K线
问题：每根K线变宽，100px的固定留白显得过大
结果：留白区域占据过多屏幕空间，浪费显示区域
```

### 期望行为

无论用户如何缩放K线图，左右两侧的留白区域应该在**视觉上保持一致的大小**，提供稳定的用户体验。

---

## 解决方案：动态边距计算

### 核心思想

将边距从**固定像素值**转换为**逻辑单位**，通过除以缩放系数 `scaleX` 来实现动态调整。

### 数学原理

K线图的坐标系统包含两个层次：

1. **逻辑坐标**：与数据相关的抽象坐标（不受缩放影响）
2. **屏幕坐标**：用户看到的实际像素坐标

两者之间的转换关系：
```
屏幕坐标 = 逻辑坐标 × scaleX
```

#### 动态边距公式

要保持屏幕上的边距始终为固定像素值（如100px），我们需要：

```dart
逻辑边距 = 固定像素值 / scaleX
```

这样，最终的屏幕边距为：
```
屏幕边距 = 逻辑边距 × scaleX
         = (固定像素值 / scaleX) × scaleX
         = 固定像素值 ✓
```

#### 实例演算

假设 `xFrontPadding = 100`（基础边距为100px）：

| 缩放级别 | scaleX | 逻辑边距计算 | 逻辑边距 | 屏幕边距 |
|---------|--------|-------------|---------|---------|
| 缩小50% | 0.5 | 100 / 0.5 | 200 | 200 × 0.5 = 100px |
| 正常 | 1.0 | 100 / 1.0 | 100 | 100 × 1.0 = 100px |
| 放大2倍 | 2.0 | 100 / 2.0 | 50 | 50 × 2.0 = 100px |
| 放大4倍 | 4.0 | 100 / 4.0 | 25 | 25 × 4.0 = 100px |

**结论**：无论缩放级别如何，屏幕上显示的边距始终为100px。

---

## 代码实现

### 1. 修改最小平移值计算（右侧边距）

**文件**：`lib/renderer/base_chart_painter.dart`

**修改前**：
```dart
double getMinTranslateX() {
  var x = -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding;
  return x >= 0 ? 0.0 : x;
}
```

**修改后**：
```dart
double getMinTranslateX() {
  // 使用 xFrontPadding / scaleX 实现动态边距
  var x = -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding / scaleX;
  return x >= 0 ? 0.0 : x;
}
```

**关键变化**：
- `xFrontPadding` → `xFrontPadding / scaleX`
- 这确保了右侧边距随缩放级别动态调整

---

### 2. 修改最大平移值计算（左侧边距）

**文件**：`lib/renderer/base_chart_painter.dart`

**修改前**：
```dart
double getMaxTranslateX() {
  return xBackPadding - mPointWidth / 2;
}
```

**修改后**：
```dart
double getMaxTranslateX() {
  // 使用 xBackPadding / scaleX 实现动态边距
  return xBackPadding / scaleX - mPointWidth / 2;
}
```

**关键变化**：
- `xBackPadding` → `xBackPadding / scaleX`
- 这确保了左侧边距随缩放级别动态调整

---

### 3. 更新缩放时的锚点计算

**文件**：`lib/candlestick_widget.dart`

**修改位置**：`onUpdate` 回调中的双指缩放逻辑

**修改前**：
```dart
final minTranslateX = -dataLen + mWidth / newScaleX - pointWidth / 2 - widget.xFrontPadding;
```

**修改后**：
```dart
// 使用动态边距：xFrontPadding / newScaleX
final minTranslateX = -dataLen + mWidth / newScaleX - pointWidth / 2 - widget.xFrontPadding / newScaleX;
```

**重要性**：
- 在用户缩放时，需要使用**新的缩放级别** `newScaleX` 来计算边距
- 这确保了缩放过程中锚点位置的正确计算，避免画面跳动

---

## 工作流程图

```
用户缩放手势
    ↓
更新 scaleX（例如：1.0 → 0.5）
    ↓
调用 getMinTranslateX() 和 getMaxTranslateX()
    ↓
计算逻辑边距
  - 右侧：100 / 0.5 = 200（逻辑单位）
  - 左侧：100 / 0.5 = 200（逻辑单位）
    ↓
渲染到屏幕
  - 右侧：200 × 0.5 = 100px（屏幕像素）
  - 左侧：200 × 0.5 = 100px（屏幕像素）
    ↓
视觉效果：边距大小不变 ✓
```

---

## 使用方法

### 基础用法

```dart
CandlestickWidget(
  _kLineData,
  ChartStyle(),
  ChartColors(),
  isTrendLine: false,
  xFrontPadding: 100,  // 右侧基础边距
  xBackPadding: 100,   // 左侧基础边距
  // ... 其他参数
)
```

### 自定义边距

```dart
CandlestickWidget(
  _kLineData,
  ChartStyle(),
  ChartColors(),
  isTrendLine: false,
  xFrontPadding: 150,  // 更大的右侧边距
  xBackPadding: 80,    // 更小的左侧边距
  // ... 其他参数
)
```

### 不对称边距

```dart
CandlestickWidget(
  _kLineData,
  ChartStyle(),
  ChartColors(),
  isTrendLine: false,
  xFrontPadding: 120,  // 右侧120px
  xBackPadding: 60,    // 左侧60px（不对称设计）
  // ... 其他参数
)
```

---

## 技术细节

### 坐标系统回顾

K线图使用三层坐标系统：

1. **数据索引**（index）：K线在数据列表中的位置（0, 1, 2, ...）
2. **逻辑坐标**（translateX）：考虑了数据位置但不考虑缩放的坐标
3. **屏幕坐标**（x）：用户看到的实际像素位置

### 转换关系

```dart
// 数据索引 → 逻辑坐标
double getX(int position) => position * mPointWidth + mPointWidth / 2;

// 逻辑坐标 → 屏幕坐标
double translateXtoX(double translateX) => (translateX + mTranslateX) * scaleX;

// 屏幕坐标 → 逻辑坐标
double xToTranslateX(double x) => -mTranslateX + x / scaleX;
```

### 滚动范围计算

```dart
// 最大滚动距离 = 左侧可滚动范围 + 右侧可滚动范围
maxScrollX = getMinTranslateX().abs() + getMaxTranslateX();
```

**说明**：
- `getMinTranslateX().abs()`：从默认位置（右侧对齐）到最右侧边界的距离
- `getMaxTranslateX()`：从默认位置到最左侧边界的距离
- 两者相加得到总的可滚动范围

---

## 边界情况处理

### 极端缩放保护

虽然当前实现未添加上限保护，但可以通过以下方式扩展：

```dart
double getEffectivePadding(double basePadding, double maxRatio) {
  // 计算动态边距
  double dynamicPadding = basePadding / scaleX;

  // 限制最大边距（例如：不超过屏幕宽度的30%）
  double maxPadding = mWidth * maxRatio;

  return min(dynamicPadding, maxPadding);
}
```

**使用场景**：
- 当 `scaleX` 非常小时（如0.2），边距可能变得过大
- 通过设置上限避免边距占据过多屏幕空间

### 数据量较少的情况

```dart
double getMinTranslateX() {
  var x = -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding / scaleX;
  // 当数据量很少时，返回0（不需要平移）
  return x >= 0 ? 0.0 : x;
}
```

**保护机制**：
- 当数据总宽度小于屏幕宽度时，返回0
- 避免负数平移导致的显示异常

---

## 性能考虑

### 计算复杂度

- **时间复杂度**：O(1) - 所有计算都是简单的算术运算
- **空间复杂度**：O(1) - 不需要额外的存储空间

### 优化点

1. **缓存 scaleX**：缩放系数已经作为状态变量缓存，无需重复计算
2. **延迟计算**：边距只在必要时（滚动、缩放、初始化）计算
3. **整数运算**：除法运算由硬件加速，性能影响可忽略

---

## 测试场景

### 1. 基础缩放测试

```
步骤：
1. 打开K线图应用
2. 滚动到最左侧，观察左侧边距
3. 双指捏合缩小图表（scaleX → 0.5）
4. 再次滚动到最左侧，观察左侧边距

预期结果：
- 左侧边距在视觉上大小一致（约100px）
```

### 2. 极端缩放测试

```
步骤：
1. 极度缩小（scaleX → 0.2）
2. 观察左右边距是否仍然合理
3. 极度放大（scaleX → 4.0）
4. 观察左右边距是否未消失

预期结果：
- 边距始终可见
- 不会占据过多或过少空间
```

### 3. 锚点稳定性测试

```
步骤：
1. 长按某根K线，显示十字线
2. 保持十字线不动，进行缩放
3. 观察十字线是否锁定在同一根K线上

预期结果：
- 缩放时十字线位置不发生跳动
- 始终指向同一根K线
```

---

## 常见问题

### Q1: 为什么不直接使用固定像素值？

**A**: 固定像素值在不同缩放级别下会导致视觉不一致。动态调整确保用户体验的连贯性。

### Q2: 如果我想要左右不同大小的边距怎么办？

**A**: 完全支持！只需设置不同的 `xFrontPadding` 和 `xBackPadding` 值即可：
```dart
xFrontPadding: 150,  // 右侧150px
xBackPadding: 80,    // 左侧80px
```

### Q3: 动态边距会影响性能吗？

**A**: 影响微乎其微。除法运算由硬件加速，且只在滚动和缩放时计算。

### Q4: 能否禁用动态边距，使用固定边距？

**A**: 当前版本不支持配置开关。如需固定边距，可以修改代码：
```dart
// 移除 / scaleX 即可恢复固定边距
double getMinTranslateX() {
  var x = -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding; // 固定
  return x >= 0 ? 0.0 : x;
}
```

---

## 总结

动态边距功能通过一个简单而巧妙的数学变换（`边距 / scaleX`），解决了K线图缩放时边距大小不一致的问题。该实现具有以下优点：

✅ **简洁高效**：仅需修改三处代码
✅ **性能优良**：O(1)时间复杂度，无性能损耗
✅ **用户友好**：提供一致的视觉体验
✅ **灵活可配**：支持自定义左右边距大小
✅ **向后兼容**：不影响现有API和使用方式

---

## 相关文件

- **核心逻辑**：[lib/renderer/base_chart_painter.dart](../lib/renderer/base_chart_painter.dart)
- **交互处理**：[lib/candlestick_widget.dart](../lib/candlestick_widget.dart)
- **示例应用**：[example/lib/main.dart](../example/lib/main.dart)

---

**文档版本**：1.0
**最后更新**：2025-12-14
**作者**：Claude Code Implementation
