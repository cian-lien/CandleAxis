import 'package:candle_axis/drawing/drawing.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'drawing_document_dto.g.dart';

@JsonSerializable(checked: true, explicitToJson: true)
class DrawingDocumentDto {
  const DrawingDocumentDto({required this.version, required this.objects});
  factory DrawingDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$DrawingDocumentDtoFromJson(json);
  factory DrawingDocumentDto.fromDocument(DrawingDocument document) =>
      DrawingDocumentDto(
        version: document.version,
        objects: document.objects.map(DrawingObjectDto.fromObject).toList(),
      );

  @JsonKey(fromJson: _strictInteger)
  final int version;
  final List<DrawingObjectDto> objects;
  Map<String, dynamic> toJson() => _$DrawingDocumentDtoToJson(this);

  DrawingDocument toDocument() {
    if (version != 1) {
      throw const FormatException('Unsupported drawing version');
    }
    final mapped = objects.map((object) => object.toObject()).toList();
    final ids = mapped.map((object) => object.id).toSet();
    if (ids.length != mapped.length ||
        mapped.any((object) => object.id.isEmpty || !object.isValid)) {
      throw const FormatException('Invalid drawing document');
    }
    return DrawingDocument(version: version, objects: mapped);
  }
}

@JsonSerializable(checked: true, explicitToJson: true)
class DrawingObjectDto {
  const DrawingObjectDto({
    required this.id,
    required this.tool,
    required this.anchors,
    required this.style,
    required this.locked,
    this.text,
  });
  factory DrawingObjectDto.fromJson(Map<String, dynamic> json) =>
      _$DrawingObjectDtoFromJson(json);
  factory DrawingObjectDto.fromObject(DrawingObject object) => DrawingObjectDto(
    id: object.id,
    tool: object.tool,
    anchors: object.anchors.map(DrawingAnchorDto.fromAnchor).toList(),
    style: DrawingStyleDto.fromStyle(object.style),
    locked: object.locked,
    text: object.text,
  );

  final String id;
  final DrawingTool tool;
  final List<DrawingAnchorDto> anchors;
  final DrawingStyleDto style;
  final bool locked;

  /// 仅文本工具使用；旧存档没有该字段，读作 null。
  final String? text;
  Map<String, dynamic> toJson() => _$DrawingObjectDtoToJson(this);
  DrawingObject toObject() => DrawingObject(
    id: id,
    tool: tool,
    anchors: anchors.map((anchor) => anchor.toAnchor()),
    style: style.toStyle(),
    locked: locked,
    text: text,
  );
}

@JsonSerializable(checked: true)
class DrawingAnchorDto {
  const DrawingAnchorDto({required this.time, required this.price});
  factory DrawingAnchorDto.fromJson(Map<String, dynamic> json) =>
      _$DrawingAnchorDtoFromJson(json);
  factory DrawingAnchorDto.fromAnchor(DrawingAnchor anchor) =>
      DrawingAnchorDto(time: anchor.time, price: anchor.price);

  @JsonKey(fromJson: _strictInteger)
  final int time;
  final double price;
  Map<String, dynamic> toJson() => _$DrawingAnchorDtoToJson(this);
  DrawingAnchor toAnchor() => DrawingAnchor(time: time, price: price);
}

@JsonSerializable(checked: true)
class DrawingStyleDto {
  const DrawingStyleDto({
    required this.color,
    required this.fillColor,
    required this.width,
    required this.lineStyle,
    required this.extend,
    required this.reverse,
    required this.showPrice,
    required this.fontSize,
    required this.bold,
    required this.italic,
    this.textBackground,
  });
  factory DrawingStyleDto.fromJson(Map<String, dynamic> json) =>
      _$DrawingStyleDtoFromJson(json);
  factory DrawingStyleDto.fromStyle(DrawingStyle style) => DrawingStyleDto(
    color: style.color.toARGB32(),
    fillColor: style.fillColor?.toARGB32(),
    width: style.width,
    lineStyle: style.lineStyle,
    extend: style.extend,
    reverse: style.reverse,
    showPrice: style.showPrice,
    fontSize: style.fontSize,
    bold: style.bold,
    italic: style.italic,
    textBackground: style.textBackground?.toARGB32(),
  );

  @JsonKey(fromJson: _strictInteger)
  final int color;
  @JsonKey(fromJson: _nullableStrictInteger)
  final int? fillColor;
  final double width;
  final DrawingLineStyle lineStyle;
  final bool extend;
  final bool reverse;
  final bool showPrice;

  /// 文本样式；旧存档没有这些字段，读取时回落到默认值。
  @JsonKey(defaultValue: 12.0)
  final double fontSize;
  @JsonKey(defaultValue: false)
  final bool bold;
  @JsonKey(defaultValue: false)
  final bool italic;

  /// 文本底色（ARGB）；旧存档没有该字段，读作 null（无底色）。
  @JsonKey(fromJson: _nullableStrictInteger)
  final int? textBackground;
  Map<String, dynamic> toJson() => _$DrawingStyleDtoToJson(this);
  DrawingStyle toStyle() {
    if (color < 0 ||
        color > 0xffffffff ||
        !_isArgb(fillColor) ||
        !_isArgb(textBackground)) {
      throw const FormatException('Invalid drawing color');
    }
    return DrawingStyle(
      color: Color(color),
      fillColor: fillColor == null ? null : Color(fillColor!),
      width: width,
      lineStyle: lineStyle,
      extend: extend,
      reverse: reverse,
      showPrice: showPrice,
      fontSize: fontSize,
      bold: bold,
      italic: italic,
      textBackground: textBackground == null ? null : Color(textBackground!),
    );
  }
}

bool _isArgb(int? value) =>
    value == null || (value >= 0 && value <= 0xffffffff);

int _strictInteger(Object? value) {
  if (value is! int) {
    throw const FormatException('Expected integer drawing field');
  }
  return value;
}

int? _nullableStrictInteger(Object? value) =>
    value == null ? null : _strictInteger(value);
