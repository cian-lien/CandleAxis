part of 'candlestick.dart';

/// Preview coordinates repaint independently of header and toolbar state.
class _DrawingUiSignals {
  final header = ValueNotifier<(bool, int?, int?)>((false, null, null));
  final tools =
      ValueNotifier<(DrawingMode, DrawingTool?, bool, bool, bool, bool, bool)>((
        DrawingMode.browse,
        null,
        false,
        false,
        false,
        false,
        false,
      ));

  void sync(ChartDrawingController controller) {
    header.value = controller.mode == DrawingMode.statistics
        ? (true, controller.rangeStart, controller.rangeEnd)
        : (false, null, null);
    tools.value = (
      controller.mode,
      controller.tool,
      controller.snapping,
      controller.hidden,
      controller.canUndo,
      controller.canRedo,
      controller.completedObjects.isNotEmpty,
    );
  }

  void dispose() {
    header.dispose();
    tools.dispose();
  }
}

extension _AIGunDrawingSession on _AIGunCandlestickState {
  /// Both orientations attach a session on the same storage namespace.
  /// Portrait is display-only (its chart never edits), so it never writes and
  /// cannot overwrite what the landscape session saves.
  void _attachDrawingSession() {
    if (_drawingController != null) return;
    _drawingController = ChartDrawingController(
      drawingColor: Theme.of(context).colorScheme.primary,
    )..setHidden(_drawingsHidden.value);
    _drawingController!.addListener(_onDrawingChanged);
    final selection = context.read<SelectionParamsCubit>();
    _configureDrawingStorage(selection.state);
    _drawingSelectionSub = selection.stream.listen((next) {
      if (!mounted) return;
      if (_drawingTimeframe != next.bar) {
        _viewport.value = null;
        _drawingController?.browse();
        _drawingTimeframe = next.bar;
      }
      _configureDrawingStorage(next);
    });
  }

  /// 文本工具落点后由宿主弹出输入栏，提交或取消都回到浏览态。
  void _onDrawingChanged() {
    final controller = _drawingController;
    if (controller == null) return;
    _drawingUi.sync(controller);
    // 显隐状态在详情页与全屏会话之间共享。
    _drawingsHidden.value = controller.hidden;
    if (controller.toolSelectionSerial != _toolSelectionSerial) {
      _toolSelectionSerial = controller.toolSelectionSerial;
      if (controller.hidden) _onToolSelectedWhileHidden(controller);
    }
    final anchor = controller.pendingTextAnchor;
    if (anchor == null || _textPromptOpen) return;
    _textPromptOpen = true;
    unawaited(_promptDrawingText().whenComplete(() => _textPromptOpen = false));
  }

  /// 画图隐藏时新画的线看不见：先确认是否显示画图；已勾选「不再提示」则
  /// 直接显示并提示一下。
  void _onToolSelectedWhileHidden(ChartDrawingController controller) {
    if (_hiddenPromptOpen) return;
    if (_settingsStorage?.hiddenDrawingToolPromptSuppressed ?? false) {
      controller.setHidden(false);
      ToastUtils.showCenterToast(context, S.of(context).chartDrawingShownToast);
      return;
    }
    _hiddenPromptOpen = true;
    unawaited(
      _promptHiddenDrawings(
        controller,
      ).whenComplete(() => _hiddenPromptOpen = false),
    );
  }

  Future<void> _promptHiddenDrawings(ChartDrawingController controller) async {
    final result = await showHiddenDrawingPromptDialog(
      context,
      compact: widget.isLandscape,
    );
    if (!mounted) return;
    if (result == null) {
      controller.browse();
      return;
    }
    controller.setHidden(false);
    if (result.dontShowAgain) {
      unawaited(_settingsStorage?.saveHiddenDrawingToolPromptSuppressed(true));
    }
  }

  Future<void> _promptDrawingText() async {
    final controller = _drawingController;
    if (controller == null) return;
    // 不弹居中对话框：只在键盘正上方放一条输入栏，点外部即取消。
    final value = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.transparent,
      pageBuilder: (context, _, _) => _DrawingTextInput(
        hint: S.of(context).chartDrawingTextHint,
        confirmLabel: S.of(context).commonOk,
      ),
    );
    if (!mounted) return;
    controller.commitText(value);
  }

  void _configureDrawingStorage(SelectionParamsState selection) {
    _drawingTimeframe = selection.bar;
    final network = selection.network?.value;
    final address = selection.tokenContractAddress;
    if (network == null || address == null) return;
    final namespace = DrawingNamespace(
      chain: network,
      address: address,
      source: selection.source,
    );
    if (_drawingNamespace == namespace.storageKey) return;
    _drawingNamespace = namespace.storageKey;
    final oldPersistence = _drawingPersistence;
    final oldSub = _drawingPersistenceSub;
    _drawingPersistence = null;
    unawaited(oldSub?.cancel());
    if (oldPersistence != null) unawaited(oldPersistence.close());
    _drawingController!.restore(DrawingDocument());
    if (!getIt.isRegistered<DrawingStorage>()) return;
    final persistence = DrawingPersistenceCubit(
      storage: getIt<DrawingStorage>(),
      namespace: namespace,
      controller: _drawingController!,
    );
    _drawingPersistence = persistence;
    unawaited(persistence.initialize());
    _drawingPersistenceSub = persistence.stream.listen((_) {
      if (mounted) _updateView(() {});
    });
  }

  /// 保存失败才提示；损坏的存档在读取时已被丢弃，不再占用提示条。
  Widget _drawingStatus(BuildContext context) {
    final state = _drawingPersistence?.state;
    if (state?.errorMessage == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: Text(
            S.of(context).chartDrawingSaveFailed,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
            ),
            maxLines: 2,
          ),
        ),
        TextButton(
          onPressed: _drawingPersistence?.retry,
          child: Text(S.of(context).retry),
        ),
      ],
    );
  }
}

/// 文本工具输入栏，贴在键盘上方并避开安全区；取消或留空返回 null，
/// 由控制器放弃该次绘制。
class _DrawingTextInput extends StatefulWidget {
  const _DrawingTextInput({required this.hint, required this.confirmLabel});

  final String hint, confirmLabel;

  @override
  State<_DrawingTextInput> createState() => _DrawingTextInputState();
}

class _DrawingTextInputState extends State<_DrawingTextInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    // 键盘与安全区可能分帧更新，底部避让只取较大值，避免叠加后再回落。
    padding: EdgeInsets.only(
      bottom: math.max(
        MediaQuery.viewInsetsOf(context).bottom,
        MediaQuery.viewPaddingOf(context).bottom,
      ),
    ),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        key: const Key('drawing-text-input'),
        color: AppColors.card(context),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 40,
                    textInputAction: .done,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      counterText: '',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (value) => Navigator.of(context).pop(value),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  child: Text(widget.confirmLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
