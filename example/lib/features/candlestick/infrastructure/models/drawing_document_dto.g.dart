// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_document_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawingDocumentDto _$DrawingDocumentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DrawingDocumentDto', json, ($checkedConvert) {
      final val = DrawingDocumentDto(
        version: $checkedConvert('version', (v) => _strictInteger(v)),
        objects: $checkedConvert(
          'objects',
          (v) => (v as List<dynamic>)
              .map((e) => DrawingObjectDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DrawingDocumentDtoToJson(DrawingDocumentDto instance) =>
    <String, dynamic>{
      'version': instance.version,
      'objects': instance.objects.map((e) => e.toJson()).toList(),
    };

DrawingObjectDto _$DrawingObjectDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DrawingObjectDto', json, ($checkedConvert) {
      final val = DrawingObjectDto(
        id: $checkedConvert('id', (v) => v as String),
        tool: $checkedConvert(
          'tool',
          (v) => $enumDecode(_$DrawingToolEnumMap, v),
        ),
        anchors: $checkedConvert(
          'anchors',
          (v) => (v as List<dynamic>)
              .map((e) => DrawingAnchorDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        style: $checkedConvert(
          'style',
          (v) => DrawingStyleDto.fromJson(v as Map<String, dynamic>),
        ),
        locked: $checkedConvert('locked', (v) => v as bool),
        text: $checkedConvert('text', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$DrawingObjectDtoToJson(DrawingObjectDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tool': _$DrawingToolEnumMap[instance.tool]!,
      'anchors': instance.anchors.map((e) => e.toJson()).toList(),
      'style': instance.style.toJson(),
      'locked': instance.locked,
      'text': instance.text,
    };

const _$DrawingToolEnumMap = {
  DrawingTool.trendLine: 'trendLine',
  DrawingTool.extendedLine: 'extendedLine',
  DrawingTool.ray: 'ray',
  DrawingTool.horizontalLine: 'horizontalLine',
  DrawingTool.verticalLine: 'verticalLine',
  DrawingTool.parallelChannel: 'parallelChannel',
  DrawingTool.priceLine: 'priceLine',
  DrawingTool.rectangle: 'rectangle',
  DrawingTool.measure: 'measure',
  DrawingTool.fibonacci: 'fibonacci',
  DrawingTool.threeWave: 'threeWave',
  DrawingTool.fiveWave: 'fiveWave',
  DrawingTool.brush: 'brush',
  DrawingTool.text: 'text',
};

DrawingAnchorDto _$DrawingAnchorDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DrawingAnchorDto', json, ($checkedConvert) {
      final val = DrawingAnchorDto(
        time: $checkedConvert('time', (v) => _strictInteger(v)),
        price: $checkedConvert('price', (v) => (v as num).toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$DrawingAnchorDtoToJson(DrawingAnchorDto instance) =>
    <String, dynamic>{'time': instance.time, 'price': instance.price};

DrawingStyleDto _$DrawingStyleDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DrawingStyleDto', json, ($checkedConvert) {
      final val = DrawingStyleDto(
        color: $checkedConvert('color', (v) => _strictInteger(v)),
        fillColor: $checkedConvert(
          'fillColor',
          (v) => _nullableStrictInteger(v),
        ),
        width: $checkedConvert('width', (v) => (v as num).toDouble()),
        lineStyle: $checkedConvert(
          'lineStyle',
          (v) => $enumDecode(_$DrawingLineStyleEnumMap, v),
        ),
        extend: $checkedConvert('extend', (v) => v as bool),
        reverse: $checkedConvert('reverse', (v) => v as bool),
        showPrice: $checkedConvert('showPrice', (v) => v as bool),
        fontSize: $checkedConvert(
          'fontSize',
          (v) => (v as num?)?.toDouble() ?? 12.0,
        ),
        bold: $checkedConvert('bold', (v) => v as bool? ?? false),
        italic: $checkedConvert('italic', (v) => v as bool? ?? false),
        textBackground: $checkedConvert(
          'textBackground',
          (v) => _nullableStrictInteger(v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DrawingStyleDtoToJson(DrawingStyleDto instance) =>
    <String, dynamic>{
      'color': instance.color,
      'fillColor': instance.fillColor,
      'width': instance.width,
      'lineStyle': _$DrawingLineStyleEnumMap[instance.lineStyle]!,
      'extend': instance.extend,
      'reverse': instance.reverse,
      'showPrice': instance.showPrice,
      'fontSize': instance.fontSize,
      'bold': instance.bold,
      'italic': instance.italic,
      'textBackground': instance.textBackground,
    };

const _$DrawingLineStyleEnumMap = {
  DrawingLineStyle.solid: 'solid',
  DrawingLineStyle.dashed: 'dashed',
  DrawingLineStyle.dotted: 'dotted',
};
