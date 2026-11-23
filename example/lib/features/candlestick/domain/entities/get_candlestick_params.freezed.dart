// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'get_candlestick_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GetCandlestickParams {

 ChainNetwork? get network; String? get tokenContractAddress; String? get bar; String? get limit; String? get from; String? get to;
/// Create a copy of GetCandlestickParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GetCandlestickParamsCopyWith<GetCandlestickParams> get copyWith => _$GetCandlestickParamsCopyWithImpl<GetCandlestickParams>(this as GetCandlestickParams, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetCandlestickParams&&(identical(other.network, network) || other.network == network)&&(identical(other.tokenContractAddress, tokenContractAddress) || other.tokenContractAddress == tokenContractAddress)&&(identical(other.bar, bar) || other.bar == bar)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,network,tokenContractAddress,bar,limit,from,to);

@override
String toString() {
  return 'GetCandlestickParams(network: $network, tokenContractAddress: $tokenContractAddress, bar: $bar, limit: $limit, from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $GetCandlestickParamsCopyWith<$Res>  {
  factory $GetCandlestickParamsCopyWith(GetCandlestickParams value, $Res Function(GetCandlestickParams) _then) = _$GetCandlestickParamsCopyWithImpl;
@useResult
$Res call({
 ChainNetwork? network, String? tokenContractAddress, String? bar, String? limit, String? from, String? to
});




}
/// @nodoc
class _$GetCandlestickParamsCopyWithImpl<$Res>
    implements $GetCandlestickParamsCopyWith<$Res> {
  _$GetCandlestickParamsCopyWithImpl(this._self, this._then);

  final GetCandlestickParams _self;
  final $Res Function(GetCandlestickParams) _then;

/// Create a copy of GetCandlestickParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? network = freezed,Object? tokenContractAddress = freezed,Object? bar = freezed,Object? limit = freezed,Object? from = freezed,Object? to = freezed,}) {
  return _then(_self.copyWith(
network: freezed == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as ChainNetwork?,tokenContractAddress: freezed == tokenContractAddress ? _self.tokenContractAddress : tokenContractAddress // ignore: cast_nullable_to_non_nullable
as String?,bar: freezed == bar ? _self.bar : bar // ignore: cast_nullable_to_non_nullable
as String?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as String?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GetCandlestickParams].
extension GetCandlestickParamsPatterns on GetCandlestickParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GetCandlestickParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GetCandlestickParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GetCandlestickParams value)  $default,){
final _that = this;
switch (_that) {
case _GetCandlestickParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GetCandlestickParams value)?  $default,){
final _that = this;
switch (_that) {
case _GetCandlestickParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChainNetwork? network,  String? tokenContractAddress,  String? bar,  String? limit,  String? from,  String? to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GetCandlestickParams() when $default != null:
return $default(_that.network,_that.tokenContractAddress,_that.bar,_that.limit,_that.from,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChainNetwork? network,  String? tokenContractAddress,  String? bar,  String? limit,  String? from,  String? to)  $default,) {final _that = this;
switch (_that) {
case _GetCandlestickParams():
return $default(_that.network,_that.tokenContractAddress,_that.bar,_that.limit,_that.from,_that.to);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChainNetwork? network,  String? tokenContractAddress,  String? bar,  String? limit,  String? from,  String? to)?  $default,) {final _that = this;
switch (_that) {
case _GetCandlestickParams() when $default != null:
return $default(_that.network,_that.tokenContractAddress,_that.bar,_that.limit,_that.from,_that.to);case _:
  return null;

}
}

}

/// @nodoc


class _GetCandlestickParams implements GetCandlestickParams {
  const _GetCandlestickParams({required this.network, required this.tokenContractAddress, required this.bar, required this.limit, required this.from, required this.to});


@override final  ChainNetwork? network;
@override final  String? tokenContractAddress;
@override final  String? bar;
@override final  String? limit;
@override final  String? from;
@override final  String? to;

/// Create a copy of GetCandlestickParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GetCandlestickParamsCopyWith<_GetCandlestickParams> get copyWith => __$GetCandlestickParamsCopyWithImpl<_GetCandlestickParams>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GetCandlestickParams&&(identical(other.network, network) || other.network == network)&&(identical(other.tokenContractAddress, tokenContractAddress) || other.tokenContractAddress == tokenContractAddress)&&(identical(other.bar, bar) || other.bar == bar)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,network,tokenContractAddress,bar,limit,from,to);

@override
String toString() {
  return 'GetCandlestickParams(network: $network, tokenContractAddress: $tokenContractAddress, bar: $bar, limit: $limit, from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class _$GetCandlestickParamsCopyWith<$Res> implements $GetCandlestickParamsCopyWith<$Res> {
  factory _$GetCandlestickParamsCopyWith(_GetCandlestickParams value, $Res Function(_GetCandlestickParams) _then) = __$GetCandlestickParamsCopyWithImpl;
@override @useResult
$Res call({
 ChainNetwork? network, String? tokenContractAddress, String? bar, String? limit, String? from, String? to
});




}
/// @nodoc
class __$GetCandlestickParamsCopyWithImpl<$Res>
    implements _$GetCandlestickParamsCopyWith<$Res> {
  __$GetCandlestickParamsCopyWithImpl(this._self, this._then);

  final _GetCandlestickParams _self;
  final $Res Function(_GetCandlestickParams) _then;

/// Create a copy of GetCandlestickParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? network = freezed,Object? tokenContractAddress = freezed,Object? bar = freezed,Object? limit = freezed,Object? from = freezed,Object? to = freezed,}) {
  return _then(_GetCandlestickParams(
network: freezed == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as ChainNetwork?,tokenContractAddress: freezed == tokenContractAddress ? _self.tokenContractAddress : tokenContractAddress // ignore: cast_nullable_to_non_nullable
as String?,bar: freezed == bar ? _self.bar : bar // ignore: cast_nullable_to_non_nullable
as String?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as String?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
