# K线图加载更多数据使用指南

本文档说明如何在K线图中实现"滑动到边界加载更多数据"的功能。

## 功能概述

当用户滑动到K线图的左侧边界（最早的历史数据）或右侧边界（最新数据）时，会自动触发数据加载回调，允许您加载更多数据。

### 核心特性

- ✅ **双向触发**：支持主动拖拽和惯性滚动两种触发方式
- ✅ **自定义加载指示器**：可传递自定义Widget显示加载状态
- ✅ **防抖机制**：防止短时间内重复触发
- ✅ **加载状态管理**：内部跟踪加载状态，避免重复加载
- ✅ **视口位置保持**：加载历史数据后保持用户当前查看位置不变

## 基本使用

### 1. 配置回调函数

```dart
CandlestickWidget(
  _kLineData,
  ChartStyle(),
  ChartColors(),
  // ... 其他参数

  // 边界回调 - 滑动到边界时触发
  onReachBoundary: (isLeft) async {
    // isLeft = true: 滑动到左侧，需要加载历史数据
    // isLeft = false: 滑动到右侧，需要加载最新数据

    if (isLeft) {
      await _loadHistoricalData();
    } else {
      await _loadLatestData();
    }
  },
)
```

### 2. 添加加载指示器（可选）

```dart
CandlestickWidget(
  // ... 其他参数

  // 自定义加载指示器
  loadingIndicatorBuilder: (isLeft) {
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isLeft ? '加载历史数据...' : '加载最新数据...',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  },
)
```

### 3. 自定义触发参数（可选）

```dart
CandlestickWidget(
  // ... 其他参数

  // 边界触发阈值（像素），默认 50
  // 用户在边界继续滑动超过此距离后才会触发回调
  boundaryThreshold: 50,

  // 防抖延迟（毫秒），默认 1000
  // 两次回调之间的最小间隔
  debounceDelay: 1000,
)
```

## 完整示例

### 基础示例：加载历史数据

```dart
class _MyChartState extends State<MyChart> {
  List<KLineEntity>? _kLineData;

  /// 加载更多历史数据
  Future<void> _loadMoreData(bool isLeft) async {
    if (_kLineData == null) return;

    if (isLeft) {
      // 获取当前最早数据的时间
      final oldestTime = _kLineData!.first.time!;

      // 从API或数据源加载更多历史数据
      final List<KLineEntity> newData = await _fetchHistoricalData(
        before: oldestTime,
        count: 50,
      );

      if (newData.isEmpty) {
        print('没有更多历史数据');
        return;
      }

      // 将新数据插入到前面
      final combinedData = [...newData, ..._kLineData!];

      // 重新计算技术指标
      DataUtil.calculate(combinedData);

      // 更新数据
      setState(() {
        _kLineData = combinedData;
      });
    } else {
      // 加载最新数据
      final latestTime = _kLineData!.last.time!;
      final List<KLineEntity> newData = await _fetchLatestData(
        after: latestTime,
        count: 50,
      );

      if (newData.isEmpty) {
        print('已是最新数据');
        return;
      }

      final combinedData = [..._kLineData!, ...newData];
      DataUtil.calculate(combinedData);

      setState(() {
        _kLineData = combinedData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CandlestickWidget(
      _kLineData,
      ChartStyle(),
      ChartColors(),
      isTrendLine: false,
      // 异步回调：加载完成后自动隐藏指示器
      onReachBoundary: (isLeft) async {
        await _loadMoreData(isLeft);
      },
      // 加载指示器
      loadingIndicatorBuilder: (isLeft) {
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isLeft ? '加载历史数据...' : '加载最新数据...',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 高级示例：带错误处理和重试

```dart
class _AdvancedChartState extends State<AdvancedChart> {
  List<KLineEntity>? _kLineData;

  /// 加载更多数据（可能失败）
  Future<void> _loadMoreData(bool isLeft) async {
    if (_kLineData == null) return;

    if (isLeft) {
      final oldestTime = _kLineData!.first.time!;

      // API调用可能会抛出异常
      final List<KLineEntity> newData = await _fetchHistoricalData(
        before: oldestTime,
        count: 50,
      );

      if (newData.isEmpty) {
        throw Exception('没有更多历史数据');
      }

      final combinedData = [...newData, ..._kLineData!];
      DataUtil.calculate(combinedData);

      setState(() {
        _kLineData = combinedData;
      });
    } else {
      // 类似的处理逻辑
      final latestTime = _kLineData!.last.time!;
      final List<KLineEntity> newData = await _fetchLatestData(
        after: latestTime,
        count: 50,
      );

      if (newData.isEmpty) {
        throw Exception('已是最新数据');
      }

      final combinedData = [..._kLineData!, ...newData];
      DataUtil.calculate(combinedData);

      setState(() {
        _kLineData = combinedData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CandlestickWidget(
      _kLineData,
      ChartStyle(),
      ChartColors(),
      isTrendLine: false,
      // 异步回调：失败会自动被捕获
      onReachBoundary: (isLeft) async {
        await _loadMoreData(isLeft);
      },
      // 加载指示器
      loadingIndicatorBuilder: (isLeft) {
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isLeft ? '加载历史数据...' : '加载最新数据...',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
      // 错误处理组件
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## 触发方式

### 1. 主动拖拽触发

用户在边界继续拖拽超过 `boundaryThreshold` 像素时触发。

```
┌─────────────────────────────┐
│ ← 继续向右拖拽超过50px      │  触发！加载历史数据
├─────────────────────────────┤
│ 已到达左边界(scrollX=max)   │
└─────────────────────────────┘

┌─────────────────────────────┐
│ → 继续向左拖拽超过50px      │  触发！加载最新数据
├─────────────────────────────┤
│ 已到达右边界(scrollX=0)     │
└─────────────────────────────┘
```

### 2. 惯性滚动触发

用户快速滑动后，如果惯性动画滚动到边界时自动触发。

```
用户快速向右滑动 → 惯性滚动 → 到达左边界(最早数据) → 触发加载历史！
用户快速向左滑动 → 惯性滚动 → 到达右边界(最新数据) → 触发加载最新！
```

## 参数说明

### onReachBoundary

- **类型**: `FutureOr<void> Function(bool isLeft)?`
- **说明**: 到达边界时的回调函数，支持同步和异步
- **参数**:
  - `isLeft`: `true` 表示到达左边界（需要加载历史数据），`false` 表示到达右边界（需要加载最新数据）
- **返回**: 可以返回 `void` 或 `Future<void>`
- **自动管理**:
  - 如果回调返回 `Future`，会自动等待其完成
  - 加载成功后自动隐藏加载指示器
  - 加载失败时：
    - 如果提供了 `loadingErrorBuilder`，显示错误组件
    - 如果未提供 `loadingErrorBuilder`，自动隐藏指示器
  - 异常会被自动捕获，不会导致应用崩溃

### loadingIndicatorBuilder

- **类型**: `Widget Function(bool isLeft)?`
- **说明**: 加载指示器构建器
- **参数**:
  - `isLeft`: `true` 表示在左侧加载，`false` 表示在右侧加载
- **返回**: 自定义的加载指示器Widget

### loadingErrorBuilder

- **类型**: `Widget Function(bool isLeft, Object error, VoidCallback retry)?`
- **说明**: 加载错误组件构建器（可选）
- **参数**:
  - `isLeft`: `true` 表示在左侧加载失败，`false` 表示在右侧加载失败
  - `error`: 错误对象
  - `retry`: 重试函数，调用后会重新触发加载
- **返回**: 自定义的错误显示Widget
- **行为**: 如果不提供，加载失败时会直接隐藏指示器

### boundaryThreshold

- **类型**: `double`
- **默认值**: `50.0`
- **说明**: 边界触发的最小拖拽距离（像素）

### debounceDelay

- **类型**: `int`
- **默认值**: `1000`
- **说明**: 防抖延迟时间（毫秒），两次回调之间的最小间隔

## 内部状态管理

K线图内部会自动管理加载状态：

1. **触发回调时**：设置加载状态，防止重复触发
2. **防抖检查**：如果距离上次触发时间小于 `debounceDelay`，则忽略
3. **方向检查**：如果已经在同一方向加载中，则忽略

加载完成后，内部状态会自动重置，允许再次触发。

## 注意事项

1. **数据更新后的位置保持**

   当在左侧加载历史数据后，K线图会自动调整滚动位置，使用户看到的K线位置保持不变。这是通过增加 `scrollX` 值来补偿新增的数据实现的。

2. **技术指标重新计算**

   加载新数据后，务必调用 `DataUtil.calculate()` 重新计算所有技术指标。

3. **异步加载**

   `onReachBoundary` 回调可以是异步的，但建议在回调中处理所有的加载逻辑，包括错误处理。

4. **边界检测和坐标系统**

   K线图的坐标系统：
   - `scrollX = 0`: 显示**右边界**（最新数据）
   - `scrollX = maxScrollX`: 显示**左边界**（最早的历史数据）

   因此：
   - 左边界（历史数据）: `scrollX >= maxScrollX`
   - 右边界（最新数据）: `scrollX <= 0`

## 常见问题

### Q: 如何禁用某一侧的加载？

A: 在 `onReachBoundary` 回调中判断方向并返回：

```dart
onReachBoundary: (isLeft) {
  if (!isLeft) {
    // 不处理右侧加载
    return;
  }
  _loadHistoricalData();
}
```

### Q: 如何显示"没有更多数据"的提示？

A: 在您的加载函数中检测数据为空，然后显示提示：

```dart
Future<void> _loadMoreData(bool isLeft) async {
  final newData = await _fetchData();

  if (newData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('没有更多数据')),
    );
    return;
  }

  // 处理新数据...
}
```

### Q: 防抖机制如何工作？

A: 内部使用时间戳记录上次触发时间，如果当前时间距离上次触发小于 `debounceDelay` 毫秒，则忽略本次触发。

### Q: 加载指示器显示在哪里？

A: 根据加载方向自动定位：
- 左侧加载：指示器显示在左上角
- 右侧加载：指示器显示在右上角

## 兼容性说明

本功能向后兼容旧的 `onLoadMore` 回调，但建议使用新的 `onReachBoundary`，它提供更清晰的API和更强大的功能。
