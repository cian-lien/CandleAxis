# 十字准心交互功能实现文档

## 概述

本文档详细说明了 K 线图表中十字准心（Crosshair）切换交互功能的实现方案。该功能允许用户通过点击和长按手势来控制十字准心的显示与隐藏。

## 需求分析

### 用户交互需求

| 操作 | 预期行为 |
|------|----------|
| 点击图表 | 显示十字准心，吸附到最近的 K 线数据点 |
| 再次点击 | 隐藏十字准心 |
| 长按并拖动 | 显示十字准心，跟随手指移动 |
| 长按后松开手指 | 十字准心保持显示在最后位置 |
| 滑动/缩放图表 | 自动隐藏十字准心 |

### 与信息弹窗的联动

- 十字准心显示时，同步显示信息弹窗
- 十字准心隐藏时，同步隐藏信息弹窗

## 架构设计

### 状态机模型

```
┌─────────────────────────────────────────────────────────┐
│                    十字准心状态机                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   [隐藏] ──────点击──────→ [锁定显示]                     │
│     ↑                          │                        │
│     │                          │                        │
│     ├──────────点击────────────┘                        │
│     │                                                   │
│     ├──────滑动/缩放───────┐                            │
│     │                      │                            │
│   [隐藏] ←─────────────[锁定显示]                        │
│     ↑                      ↑                            │
│     │                      │                            │
│   [拖动中] ────手指抬起─────┘                            │
│     ↑                                                   │
│     │                                                   │
│   长按开始                                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 核心状态变量

在 `_CandlestickWidgetState` 类中新增了关键状态变量：

```dart
/// 十字线是否锁定显示
/// - 点击图表时切换状态
/// - 长按拖动后保持显示
/// - 滑动或缩放时自动隐藏
bool _isCrossLocked = false;
```

### 状态传递链路

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│  CandlestickWidget  │ ──→ │    ChartPainter     │ ──→ │   Canvas 绘制       │
│  (_isCrossLocked)   │     │   (isCrossLocked)   │     │   (drawCrossLine)   │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
         │
         ↓
┌─────────────────────┐
│  _buildInfoDialog   │
│  (显示/隐藏弹窗)     │
└─────────────────────┘
```

## 实现细节

### 1. 状态变量定义

**文件**: `lib/candlestick_widget.dart`
**位置**: 第 349-353 行

```dart
/// 十字线是否锁定显示
/// - 点击图表时切换状态
/// - 长按拖动后保持显示
/// - 滑动或缩放时自动隐藏
bool _isCrossLocked = false;
```

**设计考量**:
- 使用私有变量 `_isCrossLocked` 封装内部状态
- 与现有的 `isLongPress` 和 `isOnTap` 协同工作
- 保持向后兼容，不影响 `isTapShowInfoDialog` 的原有行为

### 2. 点击手势处理

**文件**: `lib/candlestick_widget.dart`
**位置**: 第 590-611 行

```dart
// ========== 3. 点击手势 - 切换十字线显示或绘制趋势线 ==========
TapGestureRecognizer:
    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
  () => TapGestureRecognizer(),
  (TapGestureRecognizer instance) {
    instance.onTapUp = (details) {
      // 普通点击模式：切换十字线显示状态
      if (!widget.isTrendLine &&
          painter.isInMainRect(details.localPosition)) {
        if (_isCrossLocked) {
          // 十字线已显示，点击则隐藏
          _isCrossLocked = false;
          isOnTap = false;
          mInfoWindowStream.sink.add(null); // 清空信息弹窗
        } else {
          // 十字线未显示，点击则显示并锁定
          _isCrossLocked = true;
          isOnTap = true;
          mSelectX = details.localPosition.dx;
        }
        notifyChanged();
      }
      // ... 趋势线逻辑保持不变
    };
  },
),
```

**实现要点**:
- 使用 `_isCrossLocked` 作为切换条件，实现 toggle 效果
- 点击隐藏时，同时清空 `mInfoWindowStream` 以隐藏信息弹窗
- 点击显示时，更新 `mSelectX` 记录点击位置
- 仅在主图区域内响应点击（通过 `painter.isInMainRect` 判断）

### 3. 长按手势处理

**文件**: `lib/candlestick_widget.dart`
**位置**: 第 688-700 行

```dart
// 长按结束
..onLongPressEnd = (details) {
  isLongPress = false;
  enableCordRecord = true; // 启用趋势线坐标记录
  // 长按结束后锁定十字线，保持显示
  if (!widget.isTrendLine) {
    _isCrossLocked = true;
    isOnTap = true; // 保持 isOnTap 为 true 以显示十字线
  } else {
    mInfoWindowStream.sink.add(null); // 趋势线模式清空信息弹窗
  }
  notifyChanged();
};
```

**实现要点**:
- 长按结束时设置 `_isCrossLocked = true`，使十字线保持显示
- 同时设置 `isOnTap = true` 以兼容绘制条件
- 区分趋势线模式和普通模式的处理逻辑

### 4. 滑动/缩放隐藏逻辑

**文件**: `lib/candlestick_widget.dart`
**位置**: 第 476-481 行

```dart
// 手势更新 - 核心逻辑
..onUpdate = (details) {
  // 长按状态下不处理（避免与十字线冲突）
  if (isLongPress) return;

  // 滑动或缩放时隐藏十字线
  if (_isCrossLocked) {
    _isCrossLocked = false;
    isOnTap = false;
    mInfoWindowStream.sink.add(null);
  }
  // ... 原有滑动/缩放逻辑
}
```

**实现要点**:
- 在 `ScaleGestureRecognizer.onUpdate` 开头检查并重置状态
- 确保长按状态下不会意外隐藏十字线
- 统一处理单指滑动和双指缩放两种情况

### 5. ChartPainter 参数扩展

**文件**: `lib/renderer/chart_painter.dart`
**位置**: 第 40 行, 第 90-91 行

```dart
// 新增成员变量
final bool isCrossLocked; // 十字线是否锁定显示

// 构造函数参数
ChartPainter(
  // ... 其他参数
  this.isCrossLocked = false,
)
```

### 6. 十字线绘制条件更新

**文件**: `lib/renderer/chart_painter.dart`
**位置**: 第 232-235 行

```dart
// 原条件:
// if ((isLongPress == true || (isTapShowInfoDialog && isOnTap)) && isTrendLine == false)

// 新条件:
if ((isLongPress == true || isCrossLocked || (isTapShowInfoDialog && isOnTap)) &&
    isTrendLine == false) {
  drawCrossLine(canvas, size);
}
```

**条件逻辑说明**:
- `isLongPress`: 长按拖动时显示
- `isCrossLocked`: 锁定状态下显示（核心新增）
- `isTapShowInfoDialog && isOnTap`: 兼容原有点击显示逻辑
- `!isTrendLine`: 趋势线模式下使用独立的绘制逻辑

### 7. 数据文本显示条件更新

**文件**: `lib/renderer/chart_painter.dart`
**位置**: 第 375-378 行

```dart
@override
void drawText(Canvas canvas, KLineEntity data, double x) {
  // 更新条件以包含 isCrossLocked
  if (isLongPress || isCrossLocked || (isTapShowInfoDialog && isOnTap)) {
    var index = calculateSelectedX(selectX);
    data = getItem(index);
  }
  // ... 绘制逻辑
}
```

### 8. 信息弹窗显示条件更新

**文件**: `lib/candlestick_widget.dart`
**位置**: 第 930-937 行

```dart
// 隐藏弹窗的条件：
// 1. 没有长按、点击或锁定状态
// 2. 分时图模式
// 3. 没有数据
if ((!isLongPress && !isOnTap && !_isCrossLocked) ||
    widget.isLine == true ||
    !snapshot.hasData ||
    snapshot.data?.kLineEntity == null) return SizedBox();
```

## 文件变更摘要

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `lib/candlestick_widget.dart` | 修改 | 添加状态变量，修改手势处理逻辑 |
| `lib/renderer/chart_painter.dart` | 修改 | 添加参数，更新绘制条件 |

## 向后兼容性

本实现保持完全向后兼容：

1. **`isTapShowInfoDialog` 参数**: 原有行为不受影响
   - 当 `isTapShowInfoDialog = true` 时，点击显示信息弹窗的行为保持
   - 新增的 `_isCrossLocked` 状态独立于此参数工作

2. **趋势线模式**: 趋势线功能不受影响
   - 通过 `widget.isTrendLine` 条件分支处理
   - 趋势线模式下不触发十字线锁定

3. **分时图模式**: 分时图不显示十字线和信息弹窗
   - 通过 `widget.isLine` 条件保持原有行为

## 测试建议

### 功能测试用例

1. **点击切换测试**
   - 点击图表空白区域，验证十字线显示
   - 再次点击，验证十字线隐藏
   - 连续快速点击，验证状态切换正确

2. **长按保持测试**
   - 长按并拖动，验证十字线跟随
   - 松开手指，验证十字线保持显示
   - 点击图表，验证十字线隐藏

3. **滑动隐藏测试**
   - 显示十字线后，单指滑动图表
   - 验证十字线自动隐藏

4. **缩放隐藏测试**
   - 显示十字线后，双指缩放图表
   - 验证十字线自动隐藏

5. **信息弹窗联动测试**
   - 验证十字线显示时弹窗同步显示
   - 验证十字线隐藏时弹窗同步隐藏

### 边界条件测试

1. 图表边缘点击
2. 数据为空时的行为
3. 分时图模式下的行为
4. 趋势线模式下的行为

## 性能考虑

1. **状态更新最小化**: 仅在状态实际改变时调用 `notifyChanged()`
2. **Stream 清理**: 隐藏时及时发送 `null` 到 `mInfoWindowStream`
3. **条件短路**: 绘制条件使用 `||` 短路求值，避免不必要计算

## 扩展建议

### 可能的后续优化

1. **添加动画效果**: 十字线显示/隐藏时添加淡入淡出动画
2. **震动反馈**: 点击切换时添加触觉反馈
3. **外部控制接口**: 暴露 API 允许外部代码控制十字线显示状态
4. **自定义超时**: 添加自动隐藏超时配置

### 外部控制接口示例

```dart
// 可以在 CandlestickWidget 中添加 GlobalKey 支持
class CandlestickWidgetState extends State<CandlestickWidget> {
  /// 显示十字线
  void showCrossLine(double x) {
    _isCrossLocked = true;
    isOnTap = true;
    mSelectX = x;
    notifyChanged();
  }

  /// 隐藏十字线
  void hideCrossLine() {
    _isCrossLocked = false;
    isOnTap = false;
    mInfoWindowStream.sink.add(null);
    notifyChanged();
  }

  /// 十字线是否显示
  bool get isCrossLineVisible => _isCrossLocked || isLongPress;
}
```

---

**文档版本**: 1.0
**最后更新**: 2025-12-15
**作者**: Claude Code
