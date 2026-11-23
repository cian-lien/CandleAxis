import 'package:freezed_annotation/freezed_annotation.dart';

part 'drawing_persistence_state.freezed.dart';

@freezed
sealed class DrawingPersistenceState with _$DrawingPersistenceState {
  const DrawingPersistenceState._();
  const factory DrawingPersistenceState.initial() = DrawingPersistenceInitial;
  const factory DrawingPersistenceState.loading() = DrawingPersistenceLoading;
  const factory DrawingPersistenceState.success() = DrawingPersistenceSuccess;
  const factory DrawingPersistenceState.failure({required String message}) =
      DrawingPersistenceFailure;

  bool get isSaving => this is DrawingPersistenceLoading;
  String? get errorMessage =>
      maybeWhen(failure: (message) => message, orElse: () => null);
}
