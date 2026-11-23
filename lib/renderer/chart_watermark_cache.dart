import 'dart:ui' as ui;

import '../chart_types.dart';

/// Chart-owned raster masks at the physical display resolution. Two entries
/// cover an outgoing and incoming configuration during a transition.
class ChartWatermarkCache {
  final _images = <Object, ui.Image>{};

  ui.Image resolve(ChartWatermarkPicture source, double pixelRatio) {
    final key = (source.picture, source.size, source.height, pixelRatio);
    var image = _images.remove(key);
    if (image == null) {
      final scale = source.height / source.size.height * pixelRatio;
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
        ..scale(scale)
        ..drawPicture(source.picture);
      final picture = recorder.endRecording();
      image = picture.toImageSync((source.size.width * scale).ceil(),
          (source.size.height * scale).ceil());
      picture.dispose();
    }
    _images[key] = image;
    if (_images.length > 2) _images.remove(_images.keys.first)!.dispose();
    return image;
  }

  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }
}
