part of 'candlestick.dart';

/// 画图菜单（分类工具、绘图工具、样式）统一用贴着触发按钮的小浮层：
/// 右栏按钮向左展开，其余按钮优先向上展开；点击浮层外任意位置即关闭。
Future<T?> _showDrawingMenu<T>(
  BuildContext context, {
  required String? title,
  required List<PopupMenuEntry<T>> items,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final button = context.findRenderObject() as RenderBox?;
  final anchor = button != null && button.hasSize
      ? button.localToGlobal(Offset.zero, ancestor: overlay) & button.size
      : Rect.fromCenter(
          center: overlay.size.center(Offset.zero),
          width: 0,
          height: 0,
        );
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (context, _, _) => CustomSingleChildLayout(
      delegate: _AnchoredMenuLayout(
        anchor: anchor,
        padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(8),
      ),
      child: _AnchoredMenu<T>(items: items),
    ),
  );
}

class _AnchoredMenuLayout extends SingleChildLayoutDelegate {
  _AnchoredMenuLayout({required this.anchor, required this.padding});

  final Rect anchor;
  final EdgeInsets padding;
  static const double _gap = 6;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(padding.deflateSize(constraints.biggest));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bounds = padding.deflateRect(Offset.zero & size);
    final double left, top;
    if (anchor.center.dx > size.width * 2 / 3) {
      // 右栏：浮层右缘贴按钮左侧，顶部与按钮对齐。
      left = anchor.left - _gap - childSize.width;
      top = anchor.top;
    } else {
      left = anchor.center.dx - childSize.width / 2;
      final above = anchor.top - _gap - childSize.height;
      top = above >= bounds.top ? above : anchor.bottom + _gap;
    }
    return Offset(
      left.clamp(
        bounds.left,
        math.max(bounds.left, bounds.right - childSize.width),
      ),
      top.clamp(
        bounds.top,
        math.max(bounds.top, bounds.bottom - childSize.height),
      ),
    );
  }

  @override
  bool shouldRelayout(_AnchoredMenuLayout oldDelegate) =>
      anchor != oldDelegate.anchor || padding != oldDelegate.padding;
}

class _AnchoredMenu<T> extends StatelessWidget {
  const _AnchoredMenu({required this.items});

  final List<PopupMenuEntry<T>> items;

  @override
  Widget build(BuildContext context) {
    final foreground = AppColors.textPrimary(context);
    return Material(
      key: const Key('drawing-anchored-menu'),
      color: AppColors.card(context),
      elevation: 6,
      shadowColor: AppColors.shadow(context),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground, size: 18),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground, fontSize: 14),
          child: ConstrainedBox(
            // 网格调色板固定 7 列，比普通文字菜单宽。
            constraints: BoxConstraints(
              minWidth: 112,
              maxWidth: items.any((item) => item is DrawingColorPaletteEntry)
                  ? DrawingColorPaletteEntry.gridWidth
                  : 220,
            ),
            child: IntrinsicWidth(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    for (final (index, item) in items.indexed)
                      if (item is PopupMenuItem<T>)
                        _item(context, index, item)
                      else if (item is DrawingColorPaletteEntry)
                        item,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, PopupMenuItem<T> item) {
    final checked = item is CheckedPopupMenuItem<T> && item.checked;
    return InkWell(
      key: Key('drawing-menu-item-$index'),
      onTap: item.enabled ? () => Navigator.of(context).pop(item.value) : null,
      child: Opacity(
        opacity: item.enabled ? 1 : .4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (item is CheckedPopupMenuItem<T>) ...[
                  Icon(
                    Icons.check,
                    color: checked ? AppColors.primary : AppColors.transparent,
                  ),
                  8.horizontalSpace,
                ],
                Flexible(child: item.child ?? const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 清空画图确认统一用应用的居中确认弹窗（竖屏、竖屏全屏与横屏一致）；
/// 点遮罩关闭返回 false，不会清空。
Future<bool?> _confirmDrawingClear(
  BuildContext context, {
  required String message,
  required String cancelLabel,
  required String confirmLabel,
}) async {
  return showCutCornerDialog<bool>(
    context,
    builder: (context) => CutCornerDialog(
      title: S.of(context).chartDrawingClear,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 40, 0),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 20),
      footerPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      body: Text(message),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}
