// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_persistence_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DrawingPersistenceState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingPersistenceState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DrawingPersistenceState()';
}


}

/// @nodoc
class $DrawingPersistenceStateCopyWith<$Res>  {
$DrawingPersistenceStateCopyWith(DrawingPersistenceState _, $Res Function(DrawingPersistenceState) __);
}


/// Adds pattern-matching-related methods to [DrawingPersistenceState].
extension DrawingPersistenceStatePatterns on DrawingPersistenceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DrawingPersistenceInitial value)?  initial,TResult Function( DrawingPersistenceLoading value)?  loading,TResult Function( DrawingPersistenceSuccess value)?  success,TResult Function( DrawingPersistenceFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DrawingPersistenceInitial() when initial != null:
return initial(_that);case DrawingPersistenceLoading() when loading != null:
return loading(_that);case DrawingPersistenceSuccess() when success != null:
return success(_that);case DrawingPersistenceFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DrawingPersistenceInitial value)  initial,required TResult Function( DrawingPersistenceLoading value)  loading,required TResult Function( DrawingPersistenceSuccess value)  success,required TResult Function( DrawingPersistenceFailure value)  failure,}){
final _that = this;
switch (_that) {
case DrawingPersistenceInitial():
return initial(_that);case DrawingPersistenceLoading():
return loading(_that);case DrawingPersistenceSuccess():
return success(_that);case DrawingPersistenceFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DrawingPersistenceInitial value)?  initial,TResult? Function( DrawingPersistenceLoading value)?  loading,TResult? Function( DrawingPersistenceSuccess value)?  success,TResult? Function( DrawingPersistenceFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DrawingPersistenceInitial() when initial != null:
return initial(_that);case DrawingPersistenceLoading() when loading != null:
return loading(_that);case DrawingPersistenceSuccess() when success != null:
return success(_that);case DrawingPersistenceFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  success,TResult Function( String message)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DrawingPersistenceInitial() when initial != null:
return initial();case DrawingPersistenceLoading() when loading != null:
return loading();case DrawingPersistenceSuccess() when success != null:
return success();case DrawingPersistenceFailure() when failure != null:
return failure(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  success,required TResult Function( String message)  failure,}) {final _that = this;
switch (_that) {
case DrawingPersistenceInitial():
return initial();case DrawingPersistenceLoading():
return loading();case DrawingPersistenceSuccess():
return success();case DrawingPersistenceFailure():
return failure(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  success,TResult? Function( String message)?  failure,}) {final _that = this;
switch (_that) {
case DrawingPersistenceInitial() when initial != null:
return initial();case DrawingPersistenceLoading() when loading != null:
return loading();case DrawingPersistenceSuccess() when success != null:
return success();case DrawingPersistenceFailure() when failure != null:
return failure(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class DrawingPersistenceInitial extends DrawingPersistenceState {
  const DrawingPersistenceInitial(): super._();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingPersistenceInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DrawingPersistenceState.initial()';
}


}




/// @nodoc


class DrawingPersistenceLoading extends DrawingPersistenceState {
  const DrawingPersistenceLoading(): super._();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingPersistenceLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DrawingPersistenceState.loading()';
}


}




/// @nodoc


class DrawingPersistenceSuccess extends DrawingPersistenceState {
  const DrawingPersistenceSuccess(): super._();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingPersistenceSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DrawingPersistenceState.success()';
}


}




/// @nodoc


class DrawingPersistenceFailure extends DrawingPersistenceState {
  const DrawingPersistenceFailure({required this.message}): super._();


 final  String message;

/// Create a copy of DrawingPersistenceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingPersistenceFailureCopyWith<DrawingPersistenceFailure> get copyWith => _$DrawingPersistenceFailureCopyWithImpl<DrawingPersistenceFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingPersistenceFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DrawingPersistenceState.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $DrawingPersistenceFailureCopyWith<$Res> implements $DrawingPersistenceStateCopyWith<$Res> {
  factory $DrawingPersistenceFailureCopyWith(DrawingPersistenceFailure value, $Res Function(DrawingPersistenceFailure) _then) = _$DrawingPersistenceFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$DrawingPersistenceFailureCopyWithImpl<$Res>
    implements $DrawingPersistenceFailureCopyWith<$Res> {
  _$DrawingPersistenceFailureCopyWithImpl(this._self, this._then);

  final DrawingPersistenceFailure _self;
  final $Res Function(DrawingPersistenceFailure) _then;

/// Create a copy of DrawingPersistenceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(DrawingPersistenceFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
