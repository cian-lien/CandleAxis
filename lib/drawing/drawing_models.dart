import 'package:flutter/material.dart';

enum DrawingMode { browse, draw, edit, statistics, erase }

enum DrawingToolCategory { line, wave, shape, fibonacci, brush, text }

enum DrawingLineStyle { solid, dashed, dotted }

enum DrawingTool {
  trendLine(2),
  extendedLine(2),
  ray(2),
  horizontalLine(1),
  verticalLine(1),
  parallelChannel(3),
  // 价格线：从锚点向右的水平射线，线上标注价格。
  priceLine(1),
  rectangle(2),
  measure(2),
  fibonacci(2),
  threeWave(4),
  fiveWave(6),
  // 自由手绘按指针轨迹累积锚点，没有固定锚点数。
  brush(null),
  text(1);

  const DrawingTool(this.anchorCount);

  /// 固定锚点数；null 表示锚点数由手势决定（画笔）。
  final int? anchorCount;
  bool get isFreehand => this == brush;
  bool get supportsFill =>
      this == rectangle || this == parallelChannel || this == measure;
  bool get supportsExtend => this == parallelChannel || this == fibonacci;

  DrawingToolCategory get category => switch (this) {
        fibonacci => DrawingToolCategory.fibonacci,
        threeWave || fiveWave => DrawingToolCategory.wave,
        rectangle || measure => DrawingToolCategory.shape,
        brush => DrawingToolCategory.brush,
        text => DrawingToolCategory.text,
        _ => DrawingToolCategory.line,
      };
}

extension DrawingCategoryTools on DrawingToolCategory {
  List<DrawingTool> get tools => [
        for (final tool in DrawingTool.values)
          if (tool.category == this) tool,
      ];

  /// 只有一个工具的分类点击即用，不再展开二级面板。
  bool get isDirect => tools.length == 1;
}

/// Persistent coordinates are UTC milliseconds and unscaled market prices.
@immutable
class DrawingAnchor {
  const DrawingAnchor({required this.time, required this.price});
  final int time;
  final double price;
  bool get isValid => price.isFinite;
  @override
  bool operator ==(Object other) =>
      other is DrawingAnchor && other.time == time && other.price == price;
  @override
  int get hashCode => Object.hash(time, price);
}

@immutable
class DrawingStyle {
  const DrawingStyle(
      {this.color = const Color(0xFF4285F4),
      this.fillColor,
      this.width = 1.5,
      this.lineStyle = DrawingLineStyle.solid,
      this.extend = false,
      this.reverse = false,
      this.showPrice = true,
      this.fontSize = 12,
      this.bold = false,
      this.italic = false,
      this.textBackground});
  final Color color;
  final Color? fillColor;
  final double width;
  final DrawingLineStyle lineStyle;
  final bool extend, reverse, showPrice;

  /// 仅文本工具使用：字号、加粗、斜体。
  final double fontSize;
  final bool bold, italic;

  /// 仅文本工具使用：文字后的圆角底色；null 表示无底色。
  final Color? textBackground;
  DrawingStyle copyWith(
          {Color? color,
          Color? fillColor,
          bool clearFill = false,
          double? width,
          DrawingLineStyle? lineStyle,
          bool? extend,
          bool? reverse,
          bool? showPrice,
          double? fontSize,
          bool? bold,
          bool? italic,
          Color? textBackground,
          bool clearTextBackground = false}) =>
      DrawingStyle(
          color: color ?? this.color,
          fillColor: clearFill ? null : fillColor ?? this.fillColor,
          width: width ?? this.width,
          lineStyle: lineStyle ?? this.lineStyle,
          extend: extend ?? this.extend,
          reverse: reverse ?? this.reverse,
          showPrice: showPrice ?? this.showPrice,
          fontSize: fontSize ?? this.fontSize,
          bold: bold ?? this.bold,
          italic: italic ?? this.italic,
          textBackground: clearTextBackground
              ? null
              : textBackground ?? this.textBackground);
}

@immutable
class DrawingObject {
  DrawingObject(
      {required this.id,
      required this.tool,
      required Iterable<DrawingAnchor> anchors,
      this.style = const DrawingStyle(),
      this.locked = false,
      this.text})
      : anchors = List.unmodifiable(anchors);
  final String id;
  final DrawingTool tool;
  final List<DrawingAnchor> anchors;
  final DrawingStyle style;
  final bool locked;

  /// 仅 [DrawingTool.text] 使用；其他工具为 null。
  final String? text;
  static const fibonacciRatios = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];
  List<double> get fibonacciPrices => [
        for (final r in fibonacciRatios)
          style.reverse
              ? anchors[0].price + (anchors[1].price - anchors[0].price) * r
              : anchors[1].price + (anchors[0].price - anchors[1].price) * r
      ];
  bool get isValid {
    if (anchors.any((a) => !a.isValid) ||
        !style.width.isFinite ||
        style.width <= 0 ||
        !style.fontSize.isFinite ||
        style.fontSize <= 0) {
      return false;
    }
    final expected = tool.anchorCount;
    if (expected != null && anchors.length != expected) return false;
    if (tool.isFreehand) return anchors.length >= 2;
    if (tool == DrawingTool.text) {
      final value = text;
      return value != null && value.trim().isNotEmpty;
    }
    if (anchors.length < 2) return true;
    final first = anchors[0], second = anchors[1];
    if (tool == DrawingTool.rectangle) {
      return first.time != second.time && first.price != second.price;
    }
    if (tool == DrawingTool.measure) return first != second;
    if (tool == DrawingTool.fibonacci) return first.price != second.price;
    if ([
      DrawingTool.trendLine,
      DrawingTool.extendedLine,
      DrawingTool.ray,
      DrawingTool.parallelChannel
    ].contains(tool)) {
      return first != second;
    }
    return true;
  }

  DrawingObject copyWith(
          {Iterable<DrawingAnchor>? anchors,
          DrawingStyle? style,
          bool? locked,
          String? text}) =>
      DrawingObject(
          id: id,
          tool: tool,
          anchors: anchors ?? this.anchors,
          style: style ?? this.style,
          locked: locked ?? this.locked,
          text: text ?? this.text);
}

/// Typed, immutable persistence boundary. A host DTO can serialize every public
/// field; drafts, selection, viewport and session undo history are excluded.
@immutable
class DrawingDocument {
  DrawingDocument(
      {Iterable<DrawingObject> objects = const [], this.version = 1})
      : objects = List.unmodifiable(objects);
  final int version;
  final List<DrawingObject> objects;
}

@immutable
class DrawingHit {
  const DrawingHit(this.objectId,
      {this.anchorIndex,
      this.textCorner,
      this.boxHandle,
      this.channelEdge = false,
      this.distance = 0});
  final String objectId;
  final int? anchorIndex;

  /// Text selection corner, separate from the single persisted origin anchor.
  final int? textCorner;
  final DrawingBoxHandle? boxHandle;
  final bool channelEdge;
  final double distance;
}

/// Box handles derive from the two persisted diagonal anchors.
enum DrawingBoxHandle {
  firstTimeSecondPrice(0, 1),
  secondTimeFirstPrice(1, 0),
  firstTime(0, null),
  secondTime(1, null),
  firstPrice(null, 0),
  secondPrice(null, 1);

  const DrawingBoxHandle(this.timeIndex, this.priceIndex);
  final int? timeIndex, priceIndex;
}
