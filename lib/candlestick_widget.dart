import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'chart_translations.dart';
import 'components/popup_info_view.dart';
import 'entity/index.dart';
import 'renderer/base_dimension.dart';
import 'renderer/index.dart';
import 'utils/date_format_util.dart';

/// 价格格式化函数类型定义
/// 用于自定义价格显示格式，例如添加货币符号、千分位分隔符等
typedef PriceFormatter = String Function(double price);

/// 视口状态快照
/// 用于在数据更新后恢复视口位置
class ViewportSnapshot {
  /// 快照时数据的总长度
  final int dataLength;

  /// 快照时的 scrollX 值
  final double scrollX;

  /// 快照时的 scaleX 值
  final double scaleX;

  const ViewportSnapshot({
    required this.dataLength,
    required this.scrollX,
    required this.scaleX,
  });
}

/// 主图指标状态枚举
/// MA: 移动平均线 (Moving Average)
/// BOLL: 布林带 (Bollinger Bands)
/// SAR: 抛物线转向指标 (Parabolic SAR)
enum MainState { MA, BOLL, SAR }

/// 副图指标状态枚举
/// MACD: 指数平滑异同移动平均线 (Moving Average Convergence Divergence)
/// KDJ: 随机指标 (Stochastic Oscillator)
/// RSI: 相对强弱指标 (Relative Strength Index)
/// WR: 威廉指标 (Williams %R)
/// CCI: 顺势指标 (Commodity Channel Index)
enum SecondaryState { MACD, KDJ, RSI, WR, CCI }

/// 最新价格标识位置
/// left: 显示在图表左侧
/// right: 显示在图表右侧
enum NowPriceAlignment { left, right }

/// 十字准心价格标签位置
/// left: 固定显示在左侧
/// right: 固定显示在右侧
/// auto: 根据十字线位置自动调整（避免遮挡）
enum CrossPriceAlignment { left, right, auto }

/// 时间格式预设类
/// 提供常用的时间显示格式模板
class TimeFormat {
  /// 年-月-日格式 (例: 2024-01-15)
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];

  /// 年-月-日 时:分格式 (例: 2024-01-15 14:30)
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

/// K 线图主 Widget
/// 提供完整的 K 线图表功能，包括：
/// - 多种技术指标（MA、BOLL、MACD、KDJ 等）
/// - 手势交互（拖拽、缩放、长按、点击）
/// - 自定义样式和颜色
/// - 信息弹窗和十字线
class CandlestickWidget extends StatefulWidget {
  /// K 线数据列表，需要提前计算好技术指标
  final List<KLineEntity>? datas;

  /// 主图显示的指标集合（可多选）
  final Set<MainState> mainStateLi;

  /// 是否隐藏成交量图
  final bool volHidden;

  /// 副图显示的指标集合（可多选）
  final Set<SecondaryState> secondaryStateLi;

  /// 是否显示为分时图（折线图）模式
  final bool isLine;

  /// 是否启用点击显示详细数据
  final bool isTapShowInfoDialog;

  /// 是否隐藏网格线
  final bool hideGrid;

  /// 是否显示当前价格线（虚线）
  final bool showNowPrice;

  /// 是否显示信息弹窗
  final bool showInfoDialog;

  /// 是否使用 Material 风格的信息弹窗
  final bool materialInfoDialog;

  /// 图表文字翻译配置
  final ChartTranslations chartTranslations;

  /// 时间显示格式
  final List<String> timeFormat;

  /// 图表基础高度
  final double mBaseHeight;

  /// 滚动到边界时的回调
  /// 参数 true 表示滚动到右边界（最新数据），false 表示滚动到左边界（历史数据）
  /// 可用于实现加载更多数据的功能
  final Function(bool)? onLoadMore;

  /// 价格显示的小数位数
  final int fixedLength;

  /// MA 均线的周期列表，例如 [5, 10, 20] 表示显示 5 日、10 日、20 日均线
  final List<int> maDayList;

  /// 惯性滚动动画持续时间（毫秒）
  final int flingTime;

  /// 惯性滚动速度衰减系数（0-1），值越大滚动距离越远
  final double flingRatio;

  /// 惯性滚动动画曲线
  final Curve flingCurve;

  /// 拖拽状态变化回调
  final Function(bool)? isOnDrag;

  /// 图表颜色配置
  final ChartColors chartColors;

  /// 图表样式配置
  final ChartStyle chartStyle;

  /// 纵轴文字对齐方式（左侧或右侧）
  final VerticalTextAlignment verticalTextAlignment;

  /// 是否启用趋势线绘制功能
  final bool isTrendLine;

  /// 图表右侧留白距离（用于显示最新数据时留出空间）
  final double xFrontPadding;

  /// 图表左侧留白距离（用于显示最早数据时留出空间）
  final double xBackPadding;

  /// 自定义价格格式化函数
  final PriceFormatter? priceFormatter;

  /// 当前价格标签对齐方式
  final NowPriceAlignment? nowPriceAlignment;

  /// 十字线价格标签对齐方式
  final CrossPriceAlignment crossPriceAlignment;

  /// 滑动到边界时的回调
  /// [isLeft] 为 true 表示到达左边界（最早数据），false 表示到达右边界（最新数据）
  ///
  /// 支持同步和异步函数：
  /// - 同步: `(isLeft) { loadData(isLeft); }`
  /// - 异步: `(isLeft) async { await loadData(isLeft); }`
  ///
  /// 加载成功后会自动隐藏加载指示器
  /// 加载失败时会显示错误组件（如果提供了 loadingErrorBuilder）或隐藏指示器
  final FutureOr<void> Function(bool isLeft)? onReachBoundary;

  /// 是否启用自动切换分时图模式（缩放到阈值以下时自动切换）
  final bool autoSwitchToLine;

  /// 切换到分时图的缩放阈值（默认 0.5）
  final double lineThreshold;

  /// 水平拖动灵敏度系数（默认 1.0）
  /// 值越小，拖动时图表移动越慢，需要更多手指移动才能滚动相同距离
  /// 例如：0.5 表示灵敏度减半，需要滑动两倍距离；2.0 表示灵敏度加倍
  final double panSensitivity;

  /// 加载指示器构建器
  /// 当到达边界并触发加载更多数据时显示
  /// [isLeft] 为 true 表示在左侧(历史数据)加载，false 表示在右侧(最新数据)加载
  final Widget Function(bool isLeft)? loadingIndicatorBuilder;

  /// 加载错误组件构建器
  /// 当加载失败时显示，如果不提供则直接隐藏指示器
  /// [isLeft] 为 true 表示在左侧加载失败，false 表示在右侧加载失败
  /// [error] 错误对象
  /// [retry] 重试函数，调用后会重新触发加载
  final Widget Function(bool isLeft, Object error, VoidCallback retry)? loadingErrorBuilder;

  /// 边界触发的最小拖拽距离(像素)，默认 50
  /// 用户在边界继续滑动超过此距离后才会触发 onReachBoundary 回调
  final double boundaryThreshold;

  /// 防抖延迟时间(毫秒)，默认 1000
  /// 两次 onReachBoundary 回调之间的最小间隔，防止重复触发
  final int debounceDelay;

  const CandlestickWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    super.key,
    required this.isTrendLine,
    this.xFrontPadding = 100,
    this.xBackPadding = 100,
    this.mainStateLi = const <MainState>{},
    this.secondaryStateLi = const <SecondaryState>{},
    // this.onSecondaryTap,
    this.volHidden = false,
    this.isLine = false,
    this.isTapShowInfoDialog = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.materialInfoDialog = true,
    this.chartTranslations = const ChartTranslations(),
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.verticalTextAlignment = VerticalTextAlignment.left,
    this.mBaseHeight = 360,
    this.priceFormatter,
    this.nowPriceAlignment,
    this.crossPriceAlignment = CrossPriceAlignment.auto,
    this.onReachBoundary,
    this.autoSwitchToLine = false,
    this.lineThreshold = 0.5,
    this.panSensitivity = 1.0,
    this.loadingIndicatorBuilder,
    this.loadingErrorBuilder,
    this.boundaryThreshold = 50.0,
    this.debounceDelay = 1000,
  });

  @override
  _CandlestickWidgetState createState() => _CandlestickWidgetState();
}

/// K 线图状态管理类
/// 处理所有的交互逻辑、动画和状态更新
class _CandlestickWidgetState extends State<CandlestickWidget>
    with TickerProviderStateMixin {
  /// 信息弹窗数据流控制器
  /// 用于在绘制层（ChartPainter）和 Widget 层之间传递十字线选中的数据
  final StreamController<InfoWindowEntity?> mInfoWindowStream =
      StreamController<InfoWindowEntity?>();

  /// 水平缩放倍数（默认 1.0，范围 0.2 ~ 4.0）
  /// 值越大，K 线越宽，显示的数据越少
  double mScaleX = 1.0;

  /// 水平滚动偏移量（逻辑单位）
  /// 表示从右侧基准点偏移的距离
  double mScrollX = 0.0;

  /// 用户选择的 X 坐标（屏幕坐标）
  /// 用于计算十字线位置和选中的数据点
  double mSelectX = 0.0;

  /// 图表的宽度和高度（屏幕像素）
  double mHeight = 0, mWidth = 0;

  /// 惯性滚动动画控制器
  AnimationController? _controller;

  /// 惯性滚动 X 轴动画
  Animation<double>? aniX;

  /// 是否因缩放自动切换到分时图模式
  bool _isAutoLine = false;

  // ===== 趋势线相关变量 =====
  /// 已绘制的趋势线列表
  List<TrendLine> lines = [];

  /// 趋势线绘制时记录的上一个 X 位置
  double? changeinXposition;

  /// 趋势线绘制时记录的上一个 Y 位置
  double? changeinYposition;

  /// 当前选中的 Y 坐标（用于趋势线）
  double mSelectY = 0.0;

  /// 是否正在等待趋势线的第二个点
  bool waitingForOtherPairofCords = false;

  /// 是否启用坐标记录（用于趋势线绘制）
  bool enableCordRecord = false;

  /// 获取最小滚动值
  double getMinScrollX() {
    return mScaleX;
  }

  /// 当前触摸屏幕的手指数量（通过 Listener 实时跟踪）
  int _pointerCount = 0;

  /// 上一次处理手势时的手指数量（用于检测 1->2 或 2->1 的过渡）
  int _lastPointerCount = 0;

  /// 手势开始时的缩放倍数基线（用于相对缩放计算）
  double _scaleBase = 1.0;

  /// 手势开始时的 mScaleX 基线（用于相对缩放计算）
  double _scaleXBase = 1.0;

  /// 锚点：焦点下对应的数据索引
  /// 用于缩放时保持焦点位置不变
  int _anchorIndex = 0;

  /// 焦点的屏幕 X 坐标
  /// 用于在缩放后将锚点索引重新定位到该位置
  double _anchorScreenX = 0.0;

  /// 手势状态标志
  /// isScale: 是否正在缩放
  /// isDrag: 是否正在拖拽
  /// isLongPress: 是否长按中
  /// isOnTap: 是否点击
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  /// 十字线是否锁定显示
  /// - 点击图表时切换状态
  /// - 长按拖动后保持显示
  /// - 滑动或缩放时自动隐藏
  bool _isCrossLocked = false;

  /// 边界处累积的滑动距离，用于触发 onReachBoundary
  /// 当用户在边界继续滑动超过阈值（50像素）时，触发加载更多回调
  double _boundaryOverscroll = 0.0;

  /// 加载状态：true 表示左侧正在加载，false 表示右侧正在加载，null 表示未加载
  bool? _isLoadingAtLeft;

  /// 加载错误信息：存储最近的加载错误
  Object? _loadingError;

  /// 上次触发 onReachBoundary 的时间戳，用于防抖
  int? _lastBoundaryTriggerTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    mInfoWindowStream.sink.close();
    mInfoWindowStream.close();
    _controller?.dispose();
    super.dispose();
  }

  /// 构建图表 Widget
  @override
  Widget build(BuildContext context) {
    // 数据为空时重置所有状态
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }

    // 创建尺寸配置对象，用于计算各个区域的高度
    final BaseDimension baseDimension = BaseDimension(
      mBaseHeight: widget.mBaseHeight,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
      mainStateLi: widget.mainStateLi,
    );

    // 创建图表绘制器，负责所有的 Canvas 绘制工作
    final painter = ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      baseDimension: baseDimension,
      lines: lines, // 趋势线列表
      sink: mInfoWindowStream.sink, // 信息弹窗数据流
      xFrontPadding: widget.xFrontPadding,
      xBackPadding: widget.xBackPadding,
      isTrendLine: widget.isTrendLine, // 是否启用趋势线
      selectY: mSelectY, // 选中的 Y 坐标（趋势线用）
      datas: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      selectX: mSelectX,
      isLongPass: isLongPress,
      isOnTap: isOnTap,
      isTapShowInfoDialog: widget.isTapShowInfoDialog,
      mainStateLi: widget.mainStateLi,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
      isLine: widget.isLine || _isAutoLine,
      hideGrid: widget.hideGrid,
      showNowPrice: widget.showNowPrice,
      fixedLength: widget.fixedLength,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
      priceFormatter: widget.priceFormatter,
      nowPriceAlignment: widget.nowPriceAlignment,
      crossPriceAlignment: widget.crossPriceAlignment,
      isCrossLocked: _isCrossLocked, // 十字线锁定状态
    );

    // 使用 LayoutBuilder 获取图表的实际尺寸
    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;

        // ========== 使用 Listener 跟踪手指数量 ==========
        // 这是实现平滑手势过渡的关键
        return Listener(
          onPointerDown: (_) => setState(() => _pointerCount++),
          onPointerUp: (_) => setState(() => _pointerCount--),
          onPointerCancel: (_) => setState(() => _pointerCount--),
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque, // 确保空白区域也能接收事件
            gestures: <Type, GestureRecognizerFactory>{
              // ========== 统一的缩放手势 - 同时处理拖拽和缩放 ==========
              // 移除了 HorizontalDragGestureRecognizer 以避免手势竞技场冲突
              ScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                () => ScaleGestureRecognizer(),
                (ScaleGestureRecognizer instance) {
                  instance
                    // 手势开始
                    ..onStart = (details) {
                      isOnTap = false;
                      _stopAnimation(); // 停止惯性滚动

                      // 记录当前手指数量
                      _lastPointerCount = _pointerCount;

                      // 保存基线值，用于相对计算
                      _scaleBase = 1.0; // 手势开始时总是 1.0
                      _scaleXBase = mScaleX;

                      // 计算锚点：焦点位置对应的数据索引和屏幕坐标
                      // 这样缩放时可以保持焦点位置不变
                      _anchorScreenX = details.focalPoint.dx;
                      _anchorIndex = painter.calculateSelectedX(_anchorScreenX);

                      _boundaryOverscroll = 0.0; // 重置边界滑动累积
                      _onDragChanged(true); // 通知拖拽状态改变
                    }
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

                      // ===== 关键：检测手指数量变化，重置基线 =====
                      // 从 1->2 或 2->1 时，焦点会从单指位置跳到两指中点
                      // 必须重置锚点和基线，避免画面跳动
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
                        // 使用 focalPointDelta 避免受焦点定义变化影响
                        final dx = details.focalPointDelta.dx;
                        // 应用灵敏度系数，保持与放大时一致的滑动速度
                        final delta = (dx / mScaleX) * widget.panSensitivity;

                        mScrollX = (mScrollX + delta)
                            .clamp(0.0, ChartPainter.maxScrollX)
                            .toDouble();

                        // ===== 边界检测和加载更多逻辑 =====
                        if (widget.onReachBoundary != null) {
                          // 情况1: 在右边界（最新数据端）且向左滑动
                          if (mScrollX <= 0 && dx < 0) {
                            _boundaryOverscroll += dx.abs();
                            if (_boundaryOverscroll > widget.boundaryThreshold) {
                              _triggerBoundaryCallback(false);
                              _boundaryOverscroll = 0.0;
                            }
                          }
                          // 情况2: 在左边界（历史数据端）且向右滑动
                          else if (mScrollX >= ChartPainter.maxScrollX &&
                              ChartPainter.maxScrollX > 0 &&
                              dx > 0) {
                            _boundaryOverscroll += dx.abs();
                            if (_boundaryOverscroll > widget.boundaryThreshold) {
                              _triggerBoundaryCallback(true);
                              _boundaryOverscroll = 0.0;
                            }
                          } else {
                            _boundaryOverscroll = 0.0;
                          }
                        }

                        isScale = false;
                      } else {
                        // ===== 双指模式：缩放 =====
                        isScale = true;

                        // 相对缩放（避免绝对 scale 导致的基线漂移）
                        final relativeScale = details.scale / _scaleBase;
                        final newScaleX = (_scaleXBase * relativeScale).clamp(0.2, 4.0);

                        // 自动切换分时图模式
                        if (widget.autoSwitchToLine) {
                          _isAutoLine = newScaleX <= widget.lineThreshold;
                        }

                        // ===== 实现焦点锚定缩放 =====
                        // 核心思路：缩放后调整 scrollX，使锚点索引仍显示在焦点位置
                        //
                        // 坐标系统回顾：
                        // 1. getX(index) 返回索引的逻辑坐标
                        // 2. translateXtoX(logicX) 将逻辑坐标转为屏幕坐标
                        // 3. mScrollX 控制整体平移
                        //
                        // 目标：缩放后让 _anchorIndex 显示在 _anchorScreenX 位置

                        // 计算锚点在缩放前的逻辑坐标
                        final anchorLogicX = painter.getX(_anchorIndex);

                        // 计算缩放后，要让锚点显示在 _anchorScreenX，需要的 mTranslateX
                        // 公式推导：screenX = (logicX + mTranslateX) * scaleX
                        // => mTranslateX = screenX / scaleX - logicX
                        final newTranslateX = _anchorScreenX / newScaleX - anchorLogicX;

                        // 从 mTranslateX 反推 mScrollX
                        // 根据 base_chart_painter.dart 的公式：
                        // mTranslateX = scrollX + getMinTranslateX()
                        // => scrollX = mTranslateX - getMinTranslateX()
                        final dataLen = painter.mDataLen;
                        final pointWidth = painter.mPointWidth;
                        // 使用动态边距：xFrontPadding / newScaleX
                        final minTranslateX = -dataLen + mWidth / newScaleX - pointWidth / 2 - widget.xFrontPadding / newScaleX;
                        final effectiveMinTranslateX = minTranslateX >= 0 ? 0.0 : minTranslateX;

                        mScrollX = (newTranslateX - effectiveMinTranslateX)
                            .clamp(0.0, ChartPainter.maxScrollX)
                            .toDouble();

                        mScaleX = newScaleX;
                      }

                      notifyChanged(); // 触发重绘
                    }
                    // 手势结束
                    ..onEnd = (details) {
                      isScale = false;
                      _onDragChanged(false);

                      // 只有单指拖拽才启动惯性滚动
                      // 双指缩放不需要惯性
                      if (_pointerCount == 0 && _lastPointerCount == 1) {
                        var velocity = details.velocity.pixelsPerSecond.dx;
                        _onFling(velocity);
                      }
                    };
                },
              ),

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

                  // 趋势线模式：记录点击的坐标点
                  if (widget.isTrendLine && !isLongPress && enableCordRecord) {
                    enableCordRecord = false;
                    Offset p1 = Offset(getTrendLineX(), mSelectY);

                    // 第一次点击：创建趋势线的起点
                    if (!waitingForOtherPairofCords) {
                      lines.add(TrendLine(
                          p1, Offset(-1, -1), trendLineMax!, trendLineScale!));
                    }
                    // 第二次点击：完成趋势线的终点
                    if (waitingForOtherPairofCords) {
                      var a = lines.last;
                      lines.removeLast();
                      lines.add(
                          TrendLine(a.p1, p1, trendLineMax!, trendLineScale!));
                      waitingForOtherPairofCords = false;
                    } else {
                      waitingForOtherPairofCords = true;
                    }
                    notifyChanged();
                  }
                };
              },
            ),

            // ========== 4. 长按手势 - 显示十字线和详细信息 ==========
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(),
              (LongPressGestureRecognizer instance) {
                instance
                  // 长按开始
                  ..onLongPressStart = (details) {
                    isOnTap = false;
                    isLongPress = true;

                    // 普通模式：记录十字线位置
                    if ((mSelectX != details.localPosition.dx ||
                            mSelectY != details.globalPosition.dy) &&
                        !widget.isTrendLine) {
                      mSelectX = details.localPosition.dx;
                      notifyChanged();
                    }

                    // 趋势线模式：初始化位置记录
                    if (widget.isTrendLine && changeinXposition == null) {
                      mSelectX = changeinXposition = details.localPosition.dx;
                      mSelectY = changeinYposition = details.globalPosition.dy;
                      notifyChanged();
                    }
                    if (widget.isTrendLine && changeinXposition != null) {
                      changeinXposition = details.localPosition.dx;
                      changeinYposition = details.globalPosition.dy;
                      notifyChanged();
                    }
                  }
                  // 长按移动 - 更新十字线位置
                  ..onLongPressMoveUpdate = (details) {
                    // 普通模式：跟随手指移动十字线
                    if ((mSelectX != details.localPosition.dx ||
                            mSelectY != details.globalPosition.dy) &&
                        !widget.isTrendLine) {
                      mSelectX = details.localPosition.dx;
                      mSelectY = details.localPosition.dy;
                      notifyChanged();
                    }

                    // 趋势线模式：移动趋势线
                    if (widget.isTrendLine) {
                      // 计算相对移动距离
                      mSelectX = mSelectX +
                          (details.localPosition.dx - changeinXposition!);
                      changeinXposition = details.localPosition.dx;
                      mSelectY = mSelectY +
                          (details.globalPosition.dy - changeinYposition!);
                      changeinYposition = details.globalPosition.dy;
                      notifyChanged();
                    }
                  }
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
              },
            ),
          },
            // 图表视图层级结构
            child: Stack(
              children: <Widget>[
                // 底层：Canvas 绘制的图表
                CustomPaint(
                  size: Size(double.infinity, baseDimension.mDisplayHeight),
                  painter: painter,
                ),
                // 顶层：信息弹窗（如果启用）
                if (widget.showInfoDialog) _buildInfoDialog(),
                // 加载指示器
                if (_isLoadingAtLeft != null && widget.loadingIndicatorBuilder != null)
                  _buildLoadingIndicator(),
              ],
            ),
          ), // RawGestureDetector 结束
        ); // Listener 结束
      },
    );
  }

  /// 停止惯性滚动动画
  /// [needNotify] 是否需要触发重绘
  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  /// 拖拽状态变化回调
  /// 用于通知外部拖拽状态的变化
  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  /// 惯性滚动动画
  /// [x] 手指离开时的速度（像素/秒）
  void _onFling(double x) {
    // 创建动画控制器
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.flingTime), vsync: this);

    // 创建滚动动画
    // 起始值：当前滚动位置
    // 结束值：当前位置 + 速度 × 衰减系数 × 灵敏度系数
    aniX = null;
    aniX = Tween<double>(
      begin: mScrollX,
      end: (x * widget.flingRatio * widget.panSensitivity) + mScrollX,
    ).animate(CurvedAnimation(
            parent: _controller!.view, curve: widget.flingCurve));

    // 监听动画值变化
    aniX!.addListener(() {
      mScrollX = aniX!.value;

      // 到达右边界（最新数据）：停止动画并触发加载更多回调
      if (mScrollX <= 0) {
        mScrollX = 0;
        _triggerBoundaryCallback(false); // false = 加载最新数据
        // 兼容旧的 onLoadMore 回调
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      // 到达左边界（历史数据）：停止动画并触发加载更多回调
      else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        _triggerBoundaryCallback(true); // true = 加载历史数据
        // 兼容旧的 onLoadMore 回调
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      }

      notifyChanged(); // 每帧重绘
    });

    // 监听动画状态
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });

    // 启动动画
    _controller!.forward();
  }

  /// 触发 Widget 重建
  void notifyChanged() => setState(() {});

  /// 触发边界回调（带防抖和加载状态检查）
  /// [isLeft] 为 true 表示左边界（历史数据），false 表示右边界（最新数据）
  Future<void> _triggerBoundaryCallback(bool isLeft) async {
    if (widget.onReachBoundary == null) return;

    // 检查是否正在加载中（同方向）
    if (_isLoadingAtLeft == isLeft) return;

    // 防抖检查：距离上次触发是否超过设定的延迟时间
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastBoundaryTriggerTime != null) {
      final elapsed = now - _lastBoundaryTriggerTime!;
      if (elapsed < widget.debounceDelay) return;
    }

    // 设置加载状态
    setState(() {
      _isLoadingAtLeft = isLeft;
      _loadingError = null; // 清除之前的错误
      _lastBoundaryTriggerTime = now;
    });

    // 触发回调并等待完成
    try {
      await Future.value(widget.onReachBoundary!(isLeft));
      // 加载成功，重置状态
      resetLoadingState();
    } catch (error) {
      // 加载失败，保存错误信息
      setState(() {
        _loadingError = error;
      });
      // 如果没有提供错误构建器，则隐藏指示器
      if (widget.loadingErrorBuilder == null) {
        resetLoadingState();
      }
    }
  }

  /// 重置加载状态
  /// 在数据加载完成后调用此方法，允许再次触发加载
  void resetLoadingState() {
    if (_isLoadingAtLeft != null || _loadingError != null) {
      setState(() {
        _isLoadingAtLeft = null;
        _loadingError = null;
      });
    }
  }

  /// 创建当前视口状态的快照
  /// 在加载新数据前调用，用于之后恢复视口位置
  ViewportSnapshot createViewportSnapshot() {
    return ViewportSnapshot(
      dataLength: widget.datas?.length ?? 0,
      scrollX: mScrollX,
      scaleX: mScaleX,
    );
  }

  /// 恢复视口位置
  /// 在数据更新后调用，保持用户看到的K线位置不变
  ///
  /// [snapshot] 之前通过 createViewportSnapshot() 创建的快照
  /// [newDataCount] 新增数据的数量（正数表示左侧添加历史数据，负数表示右侧添加最新数据）
  void restoreViewport(ViewportSnapshot snapshot, int newDataCount) {
    if (widget.datas == null || widget.datas!.isEmpty) return;

    // 计算新的 scrollX
    // 如果是左侧加载历史数据（newDataCount > 0），需要增加 scrollX 来补偿新数据
    // 这样原来可见的K线索引位置不变
    final newScrollX = snapshot.scrollX + newDataCount;

    setState(() {
      // 恢复缩放级别
      mScaleX = snapshot.scaleX;
      // 调整滚动位置，确保在有效范围内
      mScrollX = newScrollX.clamp(0.0, ChartPainter.maxScrollX).toDouble();
    });
  }

  late List<String> infos;

  /// 构建加载指示器或错误组件
  Widget _buildLoadingIndicator() {
    if (_isLoadingAtLeft == null) {
      return const SizedBox.shrink();
    }

    Widget content;

    // 如果有错误且提供了错误构建器
    if (_loadingError != null && widget.loadingErrorBuilder != null) {
      // 保存当前加载方向，因为 resetLoadingState 会将其设为 null
      final loadingDirection = _isLoadingAtLeft!;
      content = widget.loadingErrorBuilder!(
        loadingDirection,
        _loadingError!,
        () {
          // 重试：先重置状态，再重新触发加载
          resetLoadingState();
          _triggerBoundaryCallback(loadingDirection);
        },
      );
    }
    // 否则显示加载指示器
    else if (widget.loadingIndicatorBuilder != null) {
      content = widget.loadingIndicatorBuilder!(_isLoadingAtLeft!);
    }
    // 如果都没有提供，显示空
    else {
      return const SizedBox.shrink();
    }

    // 根据加载方向定位指示器
    return Positioned(
      top: 0,
      left: _isLoadingAtLeft! ? 0 : null,
      right: _isLoadingAtLeft! ? null : 0,
      child: content,
    );
  }

  /// 构建信息弹窗
  /// 使用 StreamBuilder 监听十字线选中的数据变化
  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
      stream: mInfoWindowStream.stream,
      builder: (context, snapshot) {
        // 隐藏弹窗的条件：
        // 1. 没有长按、点击或锁定状态
        // 2. 分时图模式
        // 3. 没有数据
        if ((!isLongPress && !isOnTap && !_isCrossLocked) ||
            widget.isLine == true ||
            !snapshot.hasData ||
            snapshot.data?.kLineEntity == null) return SizedBox();

        KLineEntity entity = snapshot.data!.kLineEntity;
        final dialogWidth = mWidth / 3;

        // 十字线在右侧时，弹窗显示在左侧
        if (snapshot.data!.isLeft) {
          return Positioned(
            top: 25,
            left: 10.0,
            child: PopupInfoView(
              entity: entity,
              width: dialogWidth,
              chartColors: widget.chartColors,
              chartStyle: widget.chartStyle,
              chartTranslations: widget.chartTranslations,
              materialInfoDialog: widget.materialInfoDialog,
              timeFormat: widget.timeFormat,
              fixedLength: widget.fixedLength,
              priceFormatter: widget.priceFormatter,
            ),
          );
        }
        return Positioned(
          top: 25,
          right: 80.0,
          child: PopupInfoView(
            entity: entity,
            width: dialogWidth,
            chartColors: widget.chartColors,
            chartStyle: widget.chartStyle,
            chartTranslations: widget.chartTranslations,
            materialInfoDialog: widget.materialInfoDialog,
            timeFormat: widget.timeFormat,
            fixedLength: widget.fixedLength,
            priceFormatter: widget.priceFormatter,
          ),
        );
      },
    );
  }
}
