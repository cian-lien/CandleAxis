// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_candlestick_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryCandlestickStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryCandlestickStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HistoryCandlestickStatus()';
}


}

/// @nodoc
class $HistoryCandlestickStatusCopyWith<$Res>  {
$HistoryCandlestickStatusCopyWith(HistoryCandlestickStatus _, $Res Function(HistoryCandlestickStatus) __);
}


/// Adds pattern-matching-related methods to [HistoryCandlestickStatus].
extension HistoryCandlestickStatusPatterns on HistoryCandlestickStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _HistoryCandlestickInitial value)?  initial,TResult Function( _HistoryCandlestickLoading value)?  loading,TResult Function( _HistoryCandlestickSuccess value)?  success,TResult Function( _HistoryCandlestickError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryCandlestickInitial() when initial != null:
return initial(_that);case _HistoryCandlestickLoading() when loading != null:
return loading(_that);case _HistoryCandlestickSuccess() when success != null:
return success(_that);case _HistoryCandlestickError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _HistoryCandlestickInitial value)  initial,required TResult Function( _HistoryCandlestickLoading value)  loading,required TResult Function( _HistoryCandlestickSuccess value)  success,required TResult Function( _HistoryCandlestickError value)  error,}){
final _that = this;
switch (_that) {
case _HistoryCandlestickInitial():
return initial(_that);case _HistoryCandlestickLoading():
return loading(_that);case _HistoryCandlestickSuccess():
return success(_that);case _HistoryCandlestickError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _HistoryCandlestickInitial value)?  initial,TResult? Function( _HistoryCandlestickLoading value)?  loading,TResult? Function( _HistoryCandlestickSuccess value)?  success,TResult? Function( _HistoryCandlestickError value)?  error,}){
final _that = this;
switch (_that) {
case _HistoryCandlestickInitial() when initial != null:
return initial(_that);case _HistoryCandlestickLoading() when loading != null:
return loading(_that);case _HistoryCandlestickSuccess() when success != null:
return success(_that);case _HistoryCandlestickError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<KLineEntity> candles)?  success,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryCandlestickInitial() when initial != null:
return initial();case _HistoryCandlestickLoading() when loading != null:
return loading();case _HistoryCandlestickSuccess() when success != null:
return success(_that.candles);case _HistoryCandlestickError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<KLineEntity> candles)  success,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _HistoryCandlestickInitial():
return initial();case _HistoryCandlestickLoading():
return loading();case _HistoryCandlestickSuccess():
return success(_that.candles);case _HistoryCandlestickError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<KLineEntity> candles)?  success,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _HistoryCandlestickInitial() when initial != null:
return initial();case _HistoryCandlestickLoading() when loading != null:
return loading();case _HistoryCandlestickSuccess() when success != null:
return success(_that.candles);case _HistoryCandlestickError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryCandlestickInitial implements HistoryCandlestickStatus {
  const _HistoryCandlestickInitial();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryCandlestickInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HistoryCandlestickStatus.initial()';
}


}




/// @nodoc


class _HistoryCandlestickLoading implements HistoryCandlestickStatus {
  const _HistoryCandlestickLoading();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryCandlestickLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HistoryCandlestickStatus.loading()';
}


}




/// @nodoc


class _HistoryCandlestickSuccess implements HistoryCandlestickStatus {
  const _HistoryCandlestickSuccess(final  List<KLineEntity> candles): _candles = candles;


 final  List<KLineEntity> _candles;
 List<KLineEntity> get candles {
  if (_candles is EqualUnmodifiableListView) return _candles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candles);
}


/// Create a copy of HistoryCandlestickStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryCandlestickSuccessCopyWith<_HistoryCandlestickSuccess> get copyWith => __$HistoryCandlestickSuccessCopyWithImpl<_HistoryCandlestickSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryCandlestickSuccess&&const DeepCollectionEquality().equals(other._candles, _candles));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_candles));

@override
String toString() {
  return 'HistoryCandlestickStatus.success(candles: $candles)';
}


}

/// @nodoc
abstract mixin class _$HistoryCandlestickSuccessCopyWith<$Res> implements $HistoryCandlestickStatusCopyWith<$Res> {
  factory _$HistoryCandlestickSuccessCopyWith(_HistoryCandlestickSuccess value, $Res Function(_HistoryCandlestickSuccess) _then) = __$HistoryCandlestickSuccessCopyWithImpl;
@useResult
$Res call({
 List<KLineEntity> candles
});




}
/// @nodoc
class __$HistoryCandlestickSuccessCopyWithImpl<$Res>
    implements _$HistoryCandlestickSuccessCopyWith<$Res> {
  __$HistoryCandlestickSuccessCopyWithImpl(this._self, this._then);

  final _HistoryCandlestickSuccess _self;
  final $Res Function(_HistoryCandlestickSuccess) _then;

/// Create a copy of HistoryCandlestickStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? candles = null,}) {
  return _then(_HistoryCandlestickSuccess(
null == candles ? _self._candles : candles // ignore: cast_nullable_to_non_nullable
as List<KLineEntity>,
  ));
}


}

/// @nodoc


class _HistoryCandlestickError implements HistoryCandlestickStatus {
  const _HistoryCandlestickError(this.message);


 final  String message;

/// Create a copy of HistoryCandlestickStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryCandlestickErrorCopyWith<_HistoryCandlestickError> get copyWith => __$HistoryCandlestickErrorCopyWithImpl<_HistoryCandlestickError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryCandlestickError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'HistoryCandlestickStatus.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$HistoryCandlestickErrorCopyWith<$Res> implements $HistoryCandlestickStatusCopyWith<$Res> {
  factory _$HistoryCandlestickErrorCopyWith(_HistoryCandlestickError value, $Res Function(_HistoryCandlestickError) _then) = __$HistoryCandlestickErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$HistoryCandlestickErrorCopyWithImpl<$Res>
    implements _$HistoryCandlestickErrorCopyWith<$Res> {
  __$HistoryCandlestickErrorCopyWithImpl(this._self, this._then);

  final _HistoryCandlestickError _self;
  final $Res Function(_HistoryCandlestickError) _then;

/// Create a copy of HistoryCandlestickStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_HistoryCandlestickError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
