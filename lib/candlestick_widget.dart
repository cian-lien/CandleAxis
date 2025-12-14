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

  /// 自定义价格格式化函数
  final PriceFormatter? priceFormatter;

  /// 当前价格标签对齐方式
  final NowPriceAlignment? nowPriceAlignment;

  /// 十字线价格标签对齐方式
  final CrossPriceAlignment crossPriceAlignment;

  /// 滑动到边界时的回调
  /// [isLeft] 为 true 表示到达左边界（最早数据），false 表示到达右边界（最新数据）
  final Function(bool isLeft)? onReachBoundary;

  /// 是否启用自动切换分时图模式（缩放到阈值以下时自动切换）
  final bool autoSwitchToLine;

  /// 切换到分时图的缩放阈值（默认 0.5）
  final double lineThreshold;

  const CandlestickWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    super.key,
    required this.isTrendLine,
    this.xFrontPadding = 100,
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

  /// 记录上一次的缩放倍数（用于增量缩放计算）
  double _lastScale = 1.0;

  /// 初始触摸点数量（用于区分单指拖拽和双指缩放）
  int _initialPointerCount = 1;

  /// 手势状态标志
  /// isScale: 是否正在缩放
  /// isDrag: 是否正在拖拽
  /// isLongPress: 是否长按中
  /// isOnTap: 是否点击
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  /// 边界处累积的滑动距离，用于触发 onReachBoundary
  /// 当用户在边界继续滑动超过阈值（50像素）时，触发加载更多回调
  double _boundaryOverscroll = 0.0;

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
    );

    // 使用 LayoutBuilder 获取图表的实际尺寸
    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;

        // 使用 RawGestureDetector 组合多种手势识别器
        // 这是实现复杂手势交互的关键
        return RawGestureDetector(
          behavior: HitTestBehavior.opaque, // 确保空白区域也能接收事件
          gestures: <Type, GestureRecognizerFactory>{
            // ========== 1. 水平拖拽手势 - 实现图表滚动 ==========
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                    HorizontalDragGestureRecognizer>(
              () => HorizontalDragGestureRecognizer(),
              (HorizontalDragGestureRecognizer instance) {
                instance
                  // 拖拽开始
                  ..onStart = (details) {
                    isScale = true;
                    isOnTap = false;
                    _initialPointerCount = 1;
                    _boundaryOverscroll = 0.0; // 重置边界滑动累积
                    _stopAnimation(); // 停止正在进行的惯性滚动动画
                    _onDragChanged(true); // 通知拖拽状态改变
                  }
                  // 拖拽更新 - 核心滚动逻辑
                  ..onUpdate = (details) {
                    // 长按状态下不处理拖拽（避免与十字线冲突）
                    if (isLongPress) return;

                    // 计算滚动距离
                    // delta.dx: 本次移动的像素距离
                    // delta / mScaleX: 转换为逻辑距离（考虑缩放）
                    final delta = details.delta.dx;
                    mScrollX = (delta / mScaleX + mScrollX)
                        .clamp(0.0, ChartPainter.maxScrollX)
                        .toDouble();

                    // ===== 边界检测和加载更多逻辑 =====
                    if (widget.onReachBoundary != null) {
                      // 情况1: 在左边界（历史数据端）且向右滑动
                      if (mScrollX <= 0 && delta > 0) {
                        _boundaryOverscroll += delta;
                        // 累积超过 50 像素时触发回调
                        if (_boundaryOverscroll > 50) {
                          widget.onReachBoundary!(true); // true = 左边界
                          _boundaryOverscroll = 0.0; // 重置累积
                        }
                      }
                      // 情况2: 在右边界（最新数据端）且向左滑动
                      else if (mScrollX >= ChartPainter.maxScrollX &&
                          ChartPainter.maxScrollX > 0 &&
                          delta < 0) {
                        _boundaryOverscroll += delta.abs();
                        if (_boundaryOverscroll > 50) {
                          widget.onReachBoundary!(false); // false = 右边界
                          _boundaryOverscroll = 0.0;
                        }
                      } else {
                        // 不在边界，重置累积
                        _boundaryOverscroll = 0.0;
                      }
                    }
                    notifyChanged(); // 触发重绘
                  }
                  // 拖拽结束 - 启动惯性滚动
                  ..onEnd = (details) {
                    isScale = false;
                    _onDragChanged(false);
                    // 获取手指离开时的速度，用于惯性滚动
                    var velocity = details.velocity.pixelsPerSecond.dx;
                    _onFling(velocity);
                  };
              },
            ),

            // ========== 2. 缩放手势 - 实现双指缩放 ==========
            ScaleGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
              () => ScaleGestureRecognizer(),
              (ScaleGestureRecognizer instance) {
                instance
                  // 缩放开始
                  ..onStart = (details) {
                    // 只有双指及以上才处理缩放
                    if (details.pointerCount >= 2) {
                      isScale = true;
                      _initialPointerCount = details.pointerCount;
                      _stopAnimation(); // 停止惯性滚动
                    }
                  }
                  // 缩放更新 - 核心缩放逻辑
                  ..onUpdate = (details) {
                    if (details.pointerCount >= 2) {
                      // 计算新的缩放值
                      // _lastScale: 上次的缩放倍数
                      // details.scale: 本次相对上次的缩放比例
                      // clamp(0.2, 4.0): 限制缩放范围在 0.2 ~ 4 倍
                      mScaleX = (_lastScale * details.scale).clamp(0.2, 4.0);

                      // 自动切换分时图模式
                      // 当缩放到很小时（例如 0.5），自动切换为分时图
                      if (widget.autoSwitchToLine) {
                        _isAutoLine = mScaleX <= widget.lineThreshold;
                      }

                      notifyChanged(); // 触发重绘
                    }
                  }
                  // 缩放结束
                  ..onEnd = (details) {
                    isScale = false;
                    _lastScale = mScaleX; // 保存本次缩放值，供下次使用
                  };
              },
            ),

            // ========== 3. 点击手势 - 显示信息弹窗或绘制趋势线 ==========
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer instance) {
                instance.onTapUp = (details) {
                  // 普通点击模式：显示点击位置的详细信息
                  if (!widget.isTrendLine &&
                      painter.isInMainRect(details.localPosition)) {
                    isOnTap = true;
                    // 只有位置变化时才更新（避免重复触发）
                    if (mSelectX != details.localPosition.dx &&
                        widget.isTapShowInfoDialog) {
                      mSelectX = details.localPosition.dx;
                      notifyChanged();
                    }
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
                    mInfoWindowStream.sink.add(null); // 清空信息弹窗
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
              if (widget.showInfoDialog) _buildInfoDialog()
            ],
          ),
        );
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
    // 结束值：当前位置 + 速度 × 衰减系数
    aniX = null;
    aniX = Tween<double>(begin: mScrollX, end: x * widget.flingRatio + mScrollX)
        .animate(CurvedAnimation(
            parent: _controller!.view, curve: widget.flingCurve));

    // 监听动画值变化
    aniX!.addListener(() {
      mScrollX = aniX!.value;

      // 到达左边界：停止动画并触发加载更多回调
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true); // true = 加载历史数据
        }
        _stopAnimation();
      }
      // 到达右边界：停止动画并触发加载更多回调
      else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false); // false = 加载最新数据
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

  late List<String> infos;

  /// 构建信息弹窗
  /// 使用 StreamBuilder 监听十字线选中的数据变化
  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
      stream: mInfoWindowStream.stream,
      builder: (context, snapshot) {
        // 隐藏弹窗的条件：
        // 1. 没有长按或点击
        // 2. 分时图模式
        // 3. 没有数据
        if ((!isLongPress && !isOnTap) ||
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
