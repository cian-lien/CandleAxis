import 'dart:async';

import 'package:candlestick/candlestick_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/enums/candle_source.dart';
import '../../../../../core/enums/timeframe.dart';
import '../../../../../shared/domain/value_object/network.dart';
import '../../../domain/repositories/candlestick_bars_repository.dart';
import '../../../infrastructure/datasource/candlestick_settings_storage.dart';
import 'selection_params_state.dart';

class SelectionParamsCubit extends Cubit<SelectionParamsState> {
  SelectionParamsCubit([this._settingsStorage, this._barsRepository])
    : super(_initialState(_settingsStorage));

  final CandlestickSettingsStorage? _settingsStorage;
  final CandlestickBarsRepository? _barsRepository;

  Future<void> loadTimeframes() async {
    final repository = _barsRepository;
    if (repository == null ||
        state.timeframesLoading ||
        state.availableTimeframes != null) {
      return;
    }
    emit(state.copyWith(timeframesLoading: true, timeframesFailed: false));
    final result = await repository.getBars();
    if (isClosed) return;
    final bars = result.value;
    if (bars == null || bars.isEmpty) {
      emit(state.copyWith(timeframesLoading: false, timeframesFailed: true));
      return;
    }
    _emitSelection(
      _normalizeTimeframe(
        state.copyWith(
          availableTimeframes: bars,
          timeframesLoading: false,
          timeframesFailed: false,
        ),
      ),
    );
  }

  SelectionParamsState _normalizeTimeframe(SelectionParamsState next) {
    final available = next.availableTimeframes
        ?.where(
          (t) =>
              next.source != CandleSource.cmc.name ||
              t.duration >= const Duration(minutes: 15),
        )
        .toList();
    if (available == null || available.isEmpty) return next;
    final selected =
        available.where((t) => t == next.selectedTimeframe).firstOrNull ??
        available.where((t) => t == Timeframe.m5).firstOrNull ??
        available.first;
    return next.copyWith(
      selectedTimeframe: selected,
      bar: selected.duration.inSeconds.toString(),
    );
  }

  static SelectionParamsState _initialState(
    CandlestickSettingsStorage? settingsStorage,
  ) {
    final settings = settingsStorage?.selectionSettings;
    if (settings == null) return const SelectionParamsState();
    return SelectionParamsState(
      bar: settings.selectedTimeframe.duration.inSeconds.toString(),
      selectedTimeframe: settings.selectedTimeframe,
      mainStates: settings.mainStates,
      secondaryStates: settings.secondaryStates,
      volHidden: settings.volHidden,
      secondaryOrder: settings.secondaryOrder,
    );
  }

  void updateToken({required String network, required String address}) {
    emit(
      state.copyWith(
        network: ChainNetwork(network),
        tokenContractAddress: address,
      ),
    );
  }

  void updateSource(CandleSource source) {
    var nextState = state.copyWith(source: source.name);
    if (nextState.availableTimeframes != null) {
      nextState = _normalizeTimeframe(nextState);
    } else if (source == CandleSource.cmc &&
        state.selectedTimeframe.duration < const Duration(minutes: 15)) {
      nextState = nextState.copyWith(
        selectedTimeframe: Timeframe.m15,
        bar: '900',
      );
    }
    _emitSelection(
      nextState,
      persist: nextState.selectedTimeframe != state.selectedTimeframe,
    );
  }

  void updateNetwork(ChainNetwork network) =>
      emit(state.copyWith(network: network));

  void updateTokenContractAddress(String tokenContractAddress) =>
      emit(state.copyWith(tokenContractAddress: tokenContractAddress));

  void updateBar(String? bar) => emit(state.copyWith(bar: bar));

  void updateTimeframe(Timeframe timeframe) {
    final available = state.availableTimeframes;
    if (available != null && !available.contains(timeframe)) return;
    if (state.source == CandleSource.cmc.name &&
        timeframe.duration < const Duration(minutes: 15)) {
      return;
    }
    final selected =
        available?.where((t) => t == timeframe).firstOrNull ?? timeframe;
    final barInSeconds = selected.duration.inSeconds.toString();
    _emitSelection(
      state.copyWith(selectedTimeframe: selected, bar: barInSeconds),
    );
  }

  /// Updates the selected timeframe for display only, without changing bar parameter.
  /// Use this when source constraints require UI update but data is already correct
  /// (e.g., CMC returns same data for m5/m15).
  void updateSelectedTimeframeOnly(Timeframe timeframe) {
    emit(state.copyWith(selectedTimeframe: timeframe));
  }

  void updateLimit(String? limit) => emit(state.copyWith(limit: limit));

  void updateFrom(String? from) => emit(state.copyWith(from: from));

  void updateTo(String? to) => emit(state.copyWith(to: to));

  void updateMainStates(Set<MainState> mainStates) =>
      _emitSelection(state.copyWith(mainStates: mainStates));

  void updateSecondaryStates(Set<SecondaryState> secondaryStates) =>
      _emitSelection(state.copyWith(secondaryStates: secondaryStates));

  void updateIndicators({
    required Set<MainState> mainStates,
    required Set<SecondaryState> secondaryStates,
    required bool volHidden,
    List<String>? secondaryOrder,
  }) {
    _emitSelection(
      state.copyWith(
        mainStates: mainStates,
        secondaryStates: secondaryStates,
        volHidden: volHidden,
        secondaryOrder: secondaryOrder ?? state.secondaryOrder,
      ),
    );
  }

  void addMainState(MainState mainState) => _emitSelection(
    state.copyWith(mainStates: {...state.mainStates, mainState}),
  );

  void addSecondaryState(SecondaryState secondaryState) => _emitSelection(
    state.copyWith(secondaryStates: {...state.secondaryStates, secondaryState}),
  );

  void removeMainState(MainState mainState) => _emitSelection(
    state.copyWith(
      mainStates: state.mainStates.where((state) => state != mainState).toSet(),
    ),
  );

  void removeSecondaryState(SecondaryState secondaryState) => _emitSelection(
    state.copyWith(
      secondaryStates: state.secondaryStates
          .where((state) => state != secondaryState)
          .toSet(),
    ),
  );

  void toggleVolHidden() =>
      _emitSelection(state.copyWith(volHidden: !state.volHidden));

  void toggleMainState(MainState mainState) {
    if (state.mainStates.contains(mainState)) {
      removeMainState(mainState);
    } else {
      addMainState(mainState);
    }
  }

  void toggleSecondaryState(SecondaryState secondaryState) {
    if (state.secondaryStates.contains(secondaryState)) {
      removeSecondaryState(secondaryState);
    } else {
      addSecondaryState(secondaryState);
    }
  }

  void reset() {
    emit(
      _normalizeTimeframe(
        _initialState(_settingsStorage).copyWith(
          availableTimeframes: state.availableTimeframes,
          timeframesLoading: state.timeframesLoading,
          timeframesFailed: state.timeframesFailed,
        ),
      ),
    );
  }

  /// 主图最多 4 个、副图最多 6 个；超出时替换最后一项，保留前面的选择。
  void _emitSelection(SelectionParamsState nextState, {bool persist = true}) {
    final selected = CandlestickSelectionSettings.normalizeSecondary(
      states: nextState.secondaryStates,
      volHidden: nextState.volHidden,
      order: nextState.secondaryOrder,
    );
    final normalized = nextState.copyWith(
      mainStates: CandlestickSelectionSettings.limitIndicators(
        nextState.mainStates,
        CandlestickSelectionSettings.maxMainIndicators,
      ),
      secondaryStates: selected.states,
      volHidden: selected.volHidden,
      secondaryOrder: selected.order,
    );
    emit(normalized);
    if (persist) _persistSelection(normalized);
  }

  void _persistSelection(SelectionParamsState snapshot) {
    final settingsStorage = _settingsStorage;
    if (settingsStorage == null) return;
    unawaited(
      settingsStorage.saveSelectionSettings(
        CandlestickSelectionSettings(
          selectedTimeframe: snapshot.selectedTimeframe,
          customTimeframes: settingsStorage.selectionSettings.customTimeframes,
          mainStates: snapshot.mainStates,
          secondaryStates: snapshot.secondaryStates,
          volHidden: snapshot.volHidden,
          secondaryOrder: snapshot.secondaryOrder,
        ),
      ),
    );
  }
}
