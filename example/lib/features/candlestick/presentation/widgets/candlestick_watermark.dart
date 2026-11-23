import 'package:candlestick/candlestick.dart' show ChartWatermarkPicture;
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

final ValueNotifier<ChartWatermarkPicture?> _watermark = ValueNotifier(null);
Future<void>? _loading;

/// K 线品牌水印（logo-text.svg）。首次访问时解析一次并在进程内缓存；
/// 详情页、竖屏全屏与横屏共用同一个 Picture，因此不随单个图表 dispose。
ValueListenable<ChartWatermarkPicture?> candlestickWatermark() {
  _loading ??= _load();
  return _watermark;
}

Future<void> _load() async {
  try {
    final info = await vg.loadPicture(
      SvgAssetLoader('assets/images/logo/logo-text.svg'),
      null,
    );
    _watermark.value = ChartWatermarkPicture(
      picture: info.picture,
      size: info.size,
    );
  } on Object catch (error, stack) {
    // 解析失败只影响水印（图表照常显示），清空以便下次访问重试。
    _loading = null;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'candlestick',
      ),
    );
  }
}
