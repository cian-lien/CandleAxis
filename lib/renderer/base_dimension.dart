import '../candlestick_widget.dart';

class BaseDimension {
  BaseDimension({
    required double mBaseHeight,
    required bool volHidden,
    required Set<SecondaryState> secondaryStateLi,
    required Set<MainState> mainStateLi,
  }) {
    _mBaseHeight = mBaseHeight;
    _mVolumeHeight = volHidden != true ? _mBaseHeight * 0.2 : 0;
    _mSecondaryHeight = _mBaseHeight * 0.2;
    _totalSecondaryHeight = _mSecondaryHeight * secondaryStateLi.length;
    // 主图指标（MA/BOLL/SAR）标签悬浮绘制在主图内部，不占用布局高度。
    _mDisplayHeight = _mBaseHeight + _mVolumeHeight + _totalSecondaryHeight;
  }

  double _mBaseHeight = 380;

  double _mVolumeHeight = 0;

  double _mSecondaryHeight = 0;
  double _totalSecondaryHeight = 0;

  double _mDisplayHeight = 0;

  double get mVolumeHeight => _mVolumeHeight;

  double get mSecondaryHeight => _mSecondaryHeight;
  double get totalSecondaryHeight => _totalSecondaryHeight;

  double get mDisplayHeight => _mDisplayHeight;
}
