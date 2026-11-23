// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chart_display_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChartDisplayState {

 CandlestickDisplaySettings get settings;
/// Create a copy of ChartDisplayState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartDisplayStateCopyWith<ChartDisplayState> get copyWith => _$ChartDisplayStateCopyWithImpl<ChartDisplayState>(this as ChartDisplayState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartDisplayState&&(identical(other.settings, settings) || other.settings == settings));
}


@override
int get hashCode => Object.hash(runtimeType,settings);

@override
String toString() {
  return 'ChartDisplayState(settings: $settings)';
}


}

/// @nodoc
abstract mixin class $ChartDisplayStateCopyWith<$Res>  {
  factory $ChartDisplayStateCopyWith(ChartDisplayState value, $Res Function(ChartDisplayState) _then) = _$ChartDisplayStateCopyWithImpl;
@useResult
$Res call({
 CandlestickDisplaySettings settings
});




}
/// @nodoc
class _$ChartDisplayStateCopyWithImpl<$Res>
    implements $ChartDisplayStateCopyWith<$Res> {
  _$ChartDisplayStateCopyWithImpl(this._self, this._then);

  final ChartDisplayState _self;
  final $Res Function(ChartDisplayState) _then;

/// Create a copy of ChartDisplayState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? settings = null,}) {
  return _then(_self.copyWith(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CandlestickDisplaySettings,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartDisplayState].
extension ChartDisplayStatePatterns on ChartDisplayState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartDisplayState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartDisplayState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartDisplayState value)  $default,){
final _that = this;
switch (_that) {
case _ChartDisplayState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartDisplayState value)?  $default,){
final _that = this;
switch (_that) {
case _ChartDisplayState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CandlestickDisplaySettings settings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartDisplayState() when $default != null:
return $default(_that.settings);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CandlestickDisplaySettings settings)  $default,) {final _that = this;
switch (_that) {
case _ChartDisplayState():
return $default(_that.settings);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CandlestickDisplaySettings settings)?  $default,) {final _that = this;
switch (_that) {
case _ChartDisplayState() when $default != null:
return $default(_that.settings);case _:
  return null;

}
}

}

/// @nodoc


class _ChartDisplayState implements ChartDisplayState {
  const _ChartDisplayState({required this.settings});


@override final  CandlestickDisplaySettings settings;

/// Create a copy of ChartDisplayState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartDisplayStateCopyWith<_ChartDisplayState> get copyWith => __$ChartDisplayStateCopyWithImpl<_ChartDisplayState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartDisplayState&&(identical(other.settings, settings) || other.settings == settings));
}


@override
int get hashCode => Object.hash(runtimeType,settings);

@override
String toString() {
  return 'ChartDisplayState(settings: $settings)';
}


}

/// @nodoc
abstract mixin class _$ChartDisplayStateCopyWith<$Res> implements $ChartDisplayStateCopyWith<$Res> {
  factory _$ChartDisplayStateCopyWith(_ChartDisplayState value, $Res Function(_ChartDisplayState) _then) = __$ChartDisplayStateCopyWithImpl;
@override @useResult
$Res call({
 CandlestickDisplaySettings settings
});




}
/// @nodoc
class __$ChartDisplayStateCopyWithImpl<$Res>
    implements _$ChartDisplayStateCopyWith<$Res> {
  __$ChartDisplayStateCopyWithImpl(this._self, this._then);

  final _ChartDisplayState _self;
  final $Res Function(_ChartDisplayState) _then;

/// Create a copy of ChartDisplayState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? settings = null,}) {
  return _then(_ChartDisplayState(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CandlestickDisplaySettings,
  ));
}


}

// dart format on
