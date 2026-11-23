import 'package:flutter/material.dart';

/// 工具栏按钮的水波纹/高亮统一为正圆；按钮格子不是正方形时也不会变成椭圆。
final ButtonStyle drawingCircleButtonStyle =
    IconButton.styleFrom(shape: const CircleBorder());

typedef DrawingMenuPresenter = Future<T?> Function<T>(
  BuildContext context, {
  required String? title,
  required List<PopupMenuEntry<T>> items,
});

typedef DrawingConfirmationPresenter = Future<bool?> Function(
  BuildContext context, {
  required String message,
  required String cancelLabel,
  required String confirmLabel,
});

/// The host can adapt drawing menus without coupling this package to app UI.
class DrawingPopupScope extends InheritedWidget {
  const DrawingPopupScope({
    super.key,
    required this.showMenu,
    required this.confirm,
    required super.child,
  });

  final DrawingMenuPresenter showMenu;
  final DrawingConfirmationPresenter confirm;

  static DrawingPopupScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DrawingPopupScope>();

  @override
  bool updateShouldNotify(DrawingPopupScope oldWidget) =>
      showMenu != oldWidget.showMenu || confirm != oldWidget.confirm;
}

class DrawingMenuButton<T> extends StatelessWidget {
  const DrawingMenuButton({
    super.key,
    this.tooltip,
    required this.icon,
    required this.onSelected,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(8),
    this.constraints,
    this.enabled = true,
    this.style,
  });

  final String? tooltip;
  final Widget icon;
  final ValueChanged<T> onSelected;
  final PopupMenuItemBuilder<T> itemBuilder;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final bool enabled;

  /// Falls back to the default menu style, or [drawingCircleButtonStyle] when
  /// a [DrawingPopupScope] presents the menu.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final presenter = DrawingPopupScope.of(context);
    if (presenter == null) {
      return PopupMenuButton<T>(
        tooltip: tooltip,
        icon: icon,
        padding: padding,
        constraints: constraints,
        enabled: enabled,
        style: style,
        onSelected: onSelected,
        itemBuilder: itemBuilder,
      );
    }
    return IconButton(
      tooltip: tooltip,
      icon: icon,
      style: style ?? drawingCircleButtonStyle,
      padding: padding,
      onPressed: !enabled
          ? null
          : () async {
              final result = await presenter.showMenu<T>(
                context,
                title: tooltip,
                items: itemBuilder(context),
              );
              if (context.mounted && result != null) onSelected(result);
            },
    );
  }
}
