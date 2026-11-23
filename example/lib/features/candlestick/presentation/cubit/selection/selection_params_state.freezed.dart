// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'selection_params_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SelectionParamsState {

 ChainNetwork? get network; String? get tokenContractAddress; String? get bar;// 默认与 Timeframe.m5 (5分钟=300秒) 匹配
 String? get limit; String? get from; String? get to; Timeframe get selectedTimeframe; Set<MainState> get mainStates; Set<SecondaryState> get secondaryStates; bool get volHidden; List<String> get secondaryOrder; String get source; List<Timeframe>? get availableTimeframes; bool get timeframesLoading; bool get timeframesFailed;
/// Create a copy of SelectionParamsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectionParamsStateCopyWith<SelectionParamsState> get copyWith => _$SelectionParamsStateCopyWithImpl<SelectionParamsState>(this as SelectionParamsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectionParamsState&&(identical(other.network, network) || other.network == network)&&(identical(other.tokenContractAddress, tokenContractAddress) || other.tokenContractAddress == tokenContractAddress)&&(identical(other.bar, bar) || other.bar == bar)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.selectedTimeframe, selectedTimeframe) || other.selectedTimeframe == selectedTimeframe)&&const DeepCollectionEquality().equals(other.mainStates, mainStates)&&const DeepCollectionEquality().equals(other.secondaryStates, secondaryStates)&&(identical(other.volHidden, volHidden) || other.volHidden == volHidden)&&const DeepCollectionEquality().equals(other.secondaryOrder, secondaryOrder)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.availableTimeframes, availableTimeframes)&&(identical(other.timeframesLoading, timeframesLoading) || other.timeframesLoading == timeframesLoading)&&(identical(other.timeframesFailed, timeframesFailed) || other.timeframesFailed == timeframesFailed));
}


@override
int get hashCode => Object.hash(runtimeType,network,tokenContractAddress,bar,limit,from,to,selectedTimeframe,const DeepCollectionEquality().hash(mainStates),const DeepCollectionEquality().hash(secondaryStates),volHidden,const DeepCollectionEquality().hash(secondaryOrder),source,const DeepCollectionEquality().hash(availableTimeframes),timeframesLoading,timeframesFailed);

@override
String toString() {
  return 'SelectionParamsState(network: $network, tokenContractAddress: $tokenContractAddress, bar: $bar, limit: $limit, from: $from, to: $to, selectedTimeframe: $selectedTimeframe, mainStates: $mainStates, secondaryStates: $secondaryStates, volHidden: $volHidden, secondaryOrder: $secondaryOrder, source: $source, availableTimeframes: $availableTimeframes, timeframesLoading: $timeframesLoading, timeframesFailed: $timeframesFailed)';
}


}

/// @nodoc
abstract mixin class $SelectionParamsStateCopyWith<$Res>  {
  factory $SelectionParamsStateCopyWith(SelectionParamsState value, $Res Function(SelectionParamsState) _then) = _$SelectionParamsStateCopyWithImpl;
@useResult
$Res call({
 ChainNetwork? network, String? tokenContractAddress, String? bar, String? limit, String? from, String? to, Timeframe selectedTimeframe, Set<MainState> mainStates, Set<SecondaryState> secondaryStates, bool volHidden, List<String> secondaryOrder, String source, List<Timeframe>? availableTimeframes, bool timeframesLoading, bool timeframesFailed
});




}
/// @nodoc
class _$SelectionParamsStateCopyWithImpl<$Res>
    implements $SelectionParamsStateCopyWith<$Res> {
  _$SelectionParamsStateCopyWithImpl(this._self, this._then);

  final SelectionParamsState _self;
  final $Res Function(SelectionParamsState) _then;

/// Create a copy of SelectionParamsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? network = freezed,Object? tokenContractAddress = freezed,Object? bar = freezed,Object? limit = freezed,Object? from = freezed,Object? to = freezed,Object? selectedTimeframe = null,Object? mainStates = null,Object? secondaryStates = null,Object? volHidden = null,Object? secondaryOrder = null,Object? source = null,Object? availableTimeframes = freezed,Object? timeframesLoading = null,Object? timeframesFailed = null,}) {
  return _then(_self.copyWith(
network: freezed == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as ChainNetwork?,tokenContractAddress: freezed == tokenContractAddress ? _self.tokenContractAddress : tokenContractAddress // ignore: cast_nullable_to_non_nullable
as String?,bar: freezed == bar ? _self.bar : bar // ignore: cast_nullable_to_non_nullable
as String?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as String?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,selectedTimeframe: null == selectedTimeframe ? _self.selectedTimeframe : selectedTimeframe // ignore: cast_nullable_to_non_nullable
as Timeframe,mainStates: null == mainStates ? _self.mainStates : mainStates // ignore: cast_nullable_to_non_nullable
as Set<MainState>,secondaryStates: null == secondaryStates ? _self.secondaryStates : secondaryStates // ignore: cast_nullable_to_non_nullable
as Set<SecondaryState>,volHidden: null == volHidden ? _self.volHidden : volHidden // ignore: cast_nullable_to_non_nullable
as bool,secondaryOrder: null == secondaryOrder ? _self.secondaryOrder : secondaryOrder // ignore: cast_nullable_to_non_nullable
as List<String>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,availableTimeframes: freezed == availableTimeframes ? _self.availableTimeframes : availableTimeframes // ignore: cast_nullable_to_non_nullable
as List<Timeframe>?,timeframesLoading: null == timeframesLoading ? _self.timeframesLoading : timeframesLoading // ignore: cast_nullable_to_non_nullable
as bool,timeframesFailed: null == timeframesFailed ? _self.timeframesFailed : timeframesFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SelectionParamsState].
extension SelectionParamsStatePatterns on SelectionParamsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SelectionParamsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelectionParamsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SelectionParamsState value)  $default,){
final _that = this;
switch (_that) {
case _SelectionParamsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SelectionParamsState value)?  $default,){
final _that = this;
switch (_that) {
case _SelectionParamsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChainNetwork? network,  String? tokenContractAddress,  String? bar,  String? limit,  String? from,  String? to,  Timeframe selectedTimeframe,  Set<MainState> mainStates,  Set<SecondaryState> secondaryStates,  bool volHidden,  List<String> secondaryOrder,  String source,  List<Timeframe>? availableTimeframes,  bool timeframesLoading,  bool timeframesFailed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelectionParamsState() when $default != null:
return $default(_that.network,_that.tokenContractAddress,_that.bar,_that.limit,_that.from,_that.to,_that.selectedTimeframe,_that.mainStates,_that.secondaryStates,_that.volHidden,_that.secondaryOrder,_that.source,_that.availableTimeframes,_that.timeframesLoading,_that.timeframesFailed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChainNetwork? network,  String? tokenContractAddress,  String? bar,  String? limit,  String? from,  String? to,  Timeframe selectedTimeframe,  Set<MainState> mainStates,  Set<SecondaryState> secondaryStates,  bool volHidden,  List<String> secondaryOrder,  String source,  List<Timeframe>? availableTimeframes,  bool timeframesLoading,  bool timeframesFailed)  $default,) {final _that = this;
switch (_that) {
case _SelectionParamsState():
return $default(_that.network,_that.tokenContractAddress,_that.bar,_that.limit,_that.from,_that.to,_that.selectedTimeframe,_that.mainStates,_that.secondaryStates,_that.volHidden,_that.secondaryOrder,_that.source,_that.availableTimeframes,_that.timeframesLoading,_that.timeframesFailed);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChainNetwork? network,  String? tokenContractAddress,  String? bar,  String? limit,  String? from,  String? to,  Timeframe selectedTimeframe,  Set<MainState> mainStates,  Set<SecondaryState> secondaryStates,  bool volHidden,  List<String> secondaryOrder,  String source,  List<Timeframe>? availableTimeframes,  bool timeframesLoading,  bool timeframesFailed)?  $default,) {final _that = this;
switch (_that) {
case _SelectionParamsState() when $default != null:
return $default(_that.network,_that.tokenContractAddress,_that.bar,_that.limit,_that.from,_that.to,_that.selectedTimeframe,_that.mainStates,_that.secondaryStates,_that.volHidden,_that.secondaryOrder,_that.source,_that.availableTimeframes,_that.timeframesLoading,_that.timeframesFailed);case _:
  return null;

}
}

}

/// @nodoc


class _SelectionParamsState extends SelectionParamsState {
  const _SelectionParamsState({this.network = null, this.tokenContractAddress = null, this.bar = '300', this.limit = null, this.from = null, this.to = null, this.selectedTimeframe = Timeframe.m5, final  Set<MainState> mainStates = const {}, final  Set<SecondaryState> secondaryStates = const {}, this.volHidden = false, final  List<String> secondaryOrder = const ['VOL'], this.source = 'okx', final  List<Timeframe>? availableTimeframes, this.timeframesLoading = false, this.timeframesFailed = false}): _mainStates = mainStates,_secondaryStates = secondaryStates,_secondaryOrder = secondaryOrder,_availableTimeframes = availableTimeframes,super._();


@override@JsonKey() final  ChainNetwork? network;
@override@JsonKey() final  String? tokenContractAddress;
@override@JsonKey() final  String? bar;
// 默认与 Timeframe.m5 (5分钟=300秒) 匹配
@override@JsonKey() final  String? limit;
@override@JsonKey() final  String? from;
@override@JsonKey() final  String? to;
@override@JsonKey() final  Timeframe selectedTimeframe;
 final  Set<MainState> _mainStates;
@override@JsonKey() Set<MainState> get mainStates {
  if (_mainStates is EqualUnmodifiableSetView) return _mainStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_mainStates);
}

 final  Set<SecondaryState> _secondaryStates;
@override@JsonKey() Set<SecondaryState> get secondaryStates {
  if (_secondaryStates is EqualUnmodifiableSetView) return _secondaryStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_secondaryStates);
}

@override@JsonKey() final  bool volHidden;
 final  List<String> _secondaryOrder;
@override@JsonKey() List<String> get secondaryOrder {
  if (_secondaryOrder is EqualUnmodifiableListView) return _secondaryOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryOrder);
}

@override@JsonKey() final  String source;
 final  List<Timeframe>? _availableTimeframes;
@override List<Timeframe>? get availableTimeframes {
  final value = _availableTimeframes;
  if (value == null) return null;
  if (_availableTimeframes is EqualUnmodifiableListView) return _availableTimeframes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  bool timeframesLoading;
@override@JsonKey() final  bool timeframesFailed;

/// Create a copy of SelectionParamsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectionParamsStateCopyWith<_SelectionParamsState> get copyWith => __$SelectionParamsStateCopyWithImpl<_SelectionParamsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectionParamsState&&(identical(other.network, network) || other.network == network)&&(identical(other.tokenContractAddress, tokenContractAddress) || other.tokenContractAddress == tokenContractAddress)&&(identical(other.bar, bar) || other.bar == bar)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.selectedTimeframe, selectedTimeframe) || other.selectedTimeframe == selectedTimeframe)&&const DeepCollectionEquality().equals(other._mainStates, _mainStates)&&const DeepCollectionEquality().equals(other._secondaryStates, _secondaryStates)&&(identical(other.volHidden, volHidden) || other.volHidden == volHidden)&&const DeepCollectionEquality().equals(other._secondaryOrder, _secondaryOrder)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._availableTimeframes, _availableTimeframes)&&(identical(other.timeframesLoading, timeframesLoading) || other.timeframesLoading == timeframesLoading)&&(identical(other.timeframesFailed, timeframesFailed) || other.timeframesFailed == timeframesFailed));
}


@override
int get hashCode => Object.hash(runtimeType,network,tokenContractAddress,bar,limit,from,to,selectedTimeframe,const DeepCollectionEquality().hash(_mainStates),const DeepCollectionEquality().hash(_secondaryStates),volHidden,const DeepCollectionEquality().hash(_secondaryOrder),source,const DeepCollectionEquality().hash(_availableTimeframes),timeframesLoading,timeframesFailed);

@override
String toString() {
  return 'SelectionParamsState(network: $network, tokenContractAddress: $tokenContractAddress, bar: $bar, limit: $limit, from: $from, to: $to, selectedTimeframe: $selectedTimeframe, mainStates: $mainStates, secondaryStates: $secondaryStates, volHidden: $volHidden, secondaryOrder: $secondaryOrder, source: $source, availableTimeframes: $availableTimeframes, timeframesLoading: $timeframesLoading, timeframesFailed: $timeframesFailed)';
}


}

/// @nodoc
abstract mixin class _$SelectionParamsStateCopyWith<$Res> implements $SelectionParamsStateCopyWith<$Res> {
  factory _$SelectionParamsStateCopyWith(_SelectionParamsState value, $Res Function(_SelectionParamsState) _then) = __$SelectionParamsStateCopyWithImpl;
@override @useResult
$Res call({
 ChainNetwork? network, String? tokenContractAddress, String? bar, String? limit, String? from, String? to, Timeframe selectedTimeframe, Set<MainState> mainStates, Set<SecondaryState> secondaryStates, bool volHidden, List<String> secondaryOrder, String source, List<Timeframe>? availableTimeframes, bool timeframesLoading, bool timeframesFailed
});




}
/// @nodoc
class __$SelectionParamsStateCopyWithImpl<$Res>
    implements _$SelectionParamsStateCopyWith<$Res> {
  __$SelectionParamsStateCopyWithImpl(this._self, this._then);

  final _SelectionParamsState _self;
  final $Res Function(_SelectionParamsState) _then;

/// Create a copy of SelectionParamsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? network = freezed,Object? tokenContractAddress = freezed,Object? bar = freezed,Object? limit = freezed,Object? from = freezed,Object? to = freezed,Object? selectedTimeframe = null,Object? mainStates = null,Object? secondaryStates = null,Object? volHidden = null,Object? secondaryOrder = null,Object? source = null,Object? availableTimeframes = freezed,Object? timeframesLoading = null,Object? timeframesFailed = null,}) {
  return _then(_SelectionParamsState(
network: freezed == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as ChainNetwork?,tokenContractAddress: freezed == tokenContractAddress ? _self.tokenContractAddress : tokenContractAddress // ignore: cast_nullable_to_non_nullable
as String?,bar: freezed == bar ? _self.bar : bar // ignore: cast_nullable_to_non_nullable
as String?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as String?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,selectedTimeframe: null == selectedTimeframe ? _self.selectedTimeframe : selectedTimeframe // ignore: cast_nullable_to_non_nullable
as Timeframe,mainStates: null == mainStates ? _self._mainStates : mainStates // ignore: cast_nullable_to_non_nullable
as Set<MainState>,secondaryStates: null == secondaryStates ? _self._secondaryStates : secondaryStates // ignore: cast_nullable_to_non_nullable
as Set<SecondaryState>,volHidden: null == volHidden ? _self.volHidden : volHidden // ignore: cast_nullable_to_non_nullable
as bool,secondaryOrder: null == secondaryOrder ? _self._secondaryOrder : secondaryOrder // ignore: cast_nullable_to_non_nullable
as List<String>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,availableTimeframes: freezed == availableTimeframes ? _self._availableTimeframes : availableTimeframes // ignore: cast_nullable_to_non_nullable
as List<Timeframe>?,timeframesLoading: null == timeframesLoading ? _self.timeframesLoading : timeframesLoading // ignore: cast_nullable_to_non_nullable
as bool,timeframesFailed: null == timeframesFailed ? _self.timeframesFailed : timeframesFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
