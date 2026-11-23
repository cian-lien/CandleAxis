import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/l10n.dart';
import '../../../../themes/colors.dart';
import '../../../../utils/toast.dart';
import '../../../../shared/presentation/widgets/sheet/cut_corner_sheet.dart';

/// Captures the fullscreen visual, including its header and period bars.
class KlineShareCapture extends StatefulWidget {
  const KlineShareCapture({super.key, required this.builder});

  final WidgetBuilder builder;

  static Future<void> share(BuildContext context) =>
      context.findAncestorStateOfType<_KlineShareCaptureState>()!._share();

  @override
  State<KlineShareCapture> createState() => _KlineShareCaptureState();
}

class _KlineShareCaptureState extends State<KlineShareCapture> {
  final _boundary = GlobalKey();
  bool _sharing = false;
  bool _saving = false;

  Future<void> _share() async {
    if (_sharing) return;
    _sharing = true;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!mounted || data == null) return;
      final bytes = data.buffer.asUint8List();
      await showCutCornerSheet<void>(
        context,
        builder: (context) => CutCornerSheet(
          title: S.of(context).chartShareKline,
          titlePadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          bodyPadding: const EdgeInsets.all(16),
          body: Image.memory(bytes, fit: BoxFit.contain),
          footerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text('保存到相册'),
                onPressed: () => _saveToGallery(context, bytes),
              ),
              Builder(
                builder: (buttonContext) => FilledButton.icon(
                  icon: const Icon(Icons.ios_share),
                  label: Text(S.of(context).chartShareKline),
                  onPressed: () async {
                    final box = buttonContext.findRenderObject()! as RenderBox;
                    try {
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile.fromData(bytes, mimeType: 'image/png')],
                          fileNameOverrides: const ['candlex-kline.png'],
                          sharePositionOrigin:
                              box.localToGlobal(Offset.zero) & box.size,
                        ),
                      );
                    } on Exception {
                      if (buttonContext.mounted) {
                        ToastUtils.showCenterToast(
                          buttonContext,
                          S.of(buttonContext).chartShareFailed,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } on Exception {
      if (mounted) {
        ToastUtils.showCenterToast(context, S.of(context).chartShareFailed);
      }
    } finally {
      _sharing = false;
    }
  }

  Future<void> _saveToGallery(
    BuildContext sheetContext,
    Uint8List bytes,
  ) async {
    if (_saving) return;
    _saving = true;
    try {
      await Gal.putImageBytes(
        bytes,
        name: 'candlex-kline-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted || !sheetContext.mounted) return;
      Navigator.of(sheetContext).pop();
      ToastUtils.showCenterToast(context, 'K线图片已保存到相册');
    } on Exception {
      if (!sheetContext.mounted) return;
      await showDialog<void>(
        context: sheetContext,
        builder: (context) => AlertDialog(
          content: const Text('保存图片失败，请检查相册权限后重试。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).commonOk),
            ),
          ],
        ),
      );
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _boundary,
    child: ColoredBox(
      color: AppColors.background(context),
      child: Builder(builder: widget.builder),
    ),
  );
}
