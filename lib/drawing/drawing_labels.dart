import 'drawing_models.dart';

/// Host supplied strings keep the package independent from app localization.
class DrawingLabels {
  const DrawingLabels(
      {this.toolNames = const {},
      this.categoryNames = const {
        DrawingToolCategory.line: 'Lines',
        DrawingToolCategory.wave: 'Waves',
        DrawingToolCategory.shape: 'Shapes',
        DrawingToolCategory.fibonacci: 'Fibonacci',
        DrawingToolCategory.brush: 'Brush',
        DrawingToolCategory.text: 'Text',
      },
      this.erase = 'Erase drawings',
      this.exitDrawing = 'Exit drawing mode',
      this.back = 'Back',
      this.tools = 'Drawing tools',
      this.snap = 'Snap',
      this.continuous = 'Continuous drawing',
      this.hide = 'Hide drawings',
      this.show = 'Show drawings',
      this.undo = 'Undo',
      this.redo = 'Redo',
      this.clear = 'Clear all',
      this.clearConfirmation = 'Clear all drawings?',
      this.confirm = 'Clear',
      this.completed = 'Completed',
      this.invalidGeometry = 'Adjust the last point',
      this.statistics = 'Statistics',
      this.exitStatistics = 'Close',
      this.lock = 'Lock',
      this.unlock = 'Unlock',
      this.delete = 'Delete',
      this.color = 'Color',
      this.fill = 'Fill',
      this.noFill = 'No fill',
      this.width = 'Width',
      this.lineStyle = 'Line style',
      this.extend = 'Extend',
      this.reverse = 'Reverse',
      this.showPrice = 'Price label',
      this.cancel = 'Cancel',
      this.price = 'Price',
      this.marketCap = 'Market cap',
      this.time = 'Time',
      this.count = 'Periods',
      this.start = 'Start',
      this.end = 'End',
      this.high = 'High',
      this.low = 'Low',
      this.change = 'Change',
      this.volume = 'Volume',
      this.amount = 'Amount',
      this.includesUnclosed = 'Includes unclosed candle',
      this.drag = 'Move toolbar',
      this.selected = 'selected',
      this.placePoints = _placePoints,
      this.measureDuration = _measureDuration,
      this.freehandHint = 'Drag on the chart to draw',
      this.textHint = 'Tap the chart where the text should go',
      this.fontSize = 'Font size',
      this.bold = 'Bold',
      this.italic = 'Italic',
      this.textBackground = 'Background',
      this.noBackground = 'None',
      this.eraseNotice = 'Eraser on',
      this.eraseOffNotice = 'Eraser off',
      this.hiddenNotice = 'Hide drawings',
      this.shownNotice = 'Show drawings',
      this.statisticsNotice = 'Entered range statistics mode',
      this.snapOnNotice = 'Snap on',
      this.snapOffNotice = 'Snap off',
      this.continuousOnNotice = 'Continuous drawing on',
      this.continuousOffNotice = 'Continuous drawing off',
      this.lineNames = const {
        DrawingLineStyle.solid: 'Solid',
        DrawingLineStyle.dashed: 'Dashed',
        DrawingLineStyle.dotted: 'Dotted'
      }});
  final Map<DrawingTool, String> toolNames;
  final Map<DrawingToolCategory, String> categoryNames;
  final String erase, exitDrawing, back;
  final Map<DrawingLineStyle, String> lineNames;
  final String tools,
      snap,
      continuous,
      hide,
      show,
      undo,
      redo,
      clear,
      clearConfirmation,
      confirm;
  final String completed,
      invalidGeometry,
      statistics,
      exitStatistics,
      lock,
      unlock,
      delete,
      color,
      fill,
      noFill,
      width,
      lineStyle,
      extend,
      reverse,
      showPrice,
      cancel,
      price,
      marketCap,
      time,
      count,
      start,
      end,
      high,
      low,
      change,
      volume,
      amount,
      includesUnclosed,
      drag;

  /// 画图提示横幅：「<工具> 已选」与落点说明（参数为需要的锚点数）。
  final String selected, freehandHint;

  /// 文本工具：落点说明，以及编辑工具条的字号/加粗/斜体。
  final String textHint, fontSize, bold, italic;

  /// 文本底色工具的提示，以及调色板中清除底色的「无」选项。
  final String textBackground, noBackground;

  /// 切换模式类工具（橡皮擦、显隐、区间统计、吸附、连续绘制）时的短暂提示。
  final String eraseNotice,
      eraseOffNotice,
      hiddenNotice,
      shownNotice,
      statisticsNotice,
      snapOnNotice,
      snapOffNotice,
      continuousOnNotice,
      continuousOffNotice;
  final String Function(int count) placePoints;
  final String Function(int seconds) measureDuration;
  static String _measureDuration(int seconds) => formatMeasureDuration(seconds);

  /// Largest two nonzero units; smaller units are truncated, never rounded.
  static String formatMeasureDuration(int seconds,
      {String languageCode = 'en'}) {
    final zh = languageCode == 'zh';
    final units = zh ? ['天', '小时', '分', '秒'] : ['d', 'h', 'm', 's'];
    const sizes = [86400, 3600, 60, 1];
    var remaining = seconds.abs();
    final parts = <String>[];
    for (var i = 0; i < sizes.length && parts.length < 2; i++) {
      final value = remaining ~/ sizes[i];
      remaining %= sizes[i];
      if (value > 0) parts.add('$value${units[i]}');
    }
    return parts.isEmpty ? '0${units.last}' : parts.join(zh ? '' : ' ');
  }

  static String _placePoints(int count) => 'Place $count points to finish';
  String forTool(DrawingTool tool) => toolNames[tool] ?? tool.name;
  String forCategory(DrawingToolCategory category) =>
      categoryNames[category] ?? category.name;
}
