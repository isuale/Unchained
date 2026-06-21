// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_answer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingAnswer {

 String get id; String get textKey; int get points;
/// Create a copy of OnboardingAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingAnswerCopyWith<OnboardingAnswer> get copyWith => _$OnboardingAnswerCopyWithImpl<OnboardingAnswer>(this as OnboardingAnswer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingAnswer&&(identical(other.id, id) || other.id == id)&&(identical(other.textKey, textKey) || other.textKey == textKey)&&(identical(other.points, points) || other.points == points));
}


@override
int get hashCode => Object.hash(runtimeType,id,textKey,points);

@override
String toString() {
  return 'OnboardingAnswer(id: $id, textKey: $textKey, points: $points)';
}


}

/// @nodoc
abstract mixin class $OnboardingAnswerCopyWith<$Res>  {
  factory $OnboardingAnswerCopyWith(OnboardingAnswer value, $Res Function(OnboardingAnswer) _then) = _$OnboardingAnswerCopyWithImpl;
@useResult
$Res call({
 String id, String textKey, int points
});




}
/// @nodoc
class _$OnboardingAnswerCopyWithImpl<$Res>
    implements $OnboardingAnswerCopyWith<$Res> {
  _$OnboardingAnswerCopyWithImpl(this._self, this._then);

  final OnboardingAnswer _self;
  final $Res Function(OnboardingAnswer) _then;

/// Create a copy of OnboardingAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? textKey = null,Object? points = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textKey: null == textKey ? _self.textKey : textKey // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingAnswer].
extension OnboardingAnswerPatterns on OnboardingAnswer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingAnswer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingAnswer value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingAnswer():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingAnswer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String textKey,  int points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingAnswer() when $default != null:
return $default(_that.id,_that.textKey,_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String textKey,  int points)  $default,) {final _that = this;
switch (_that) {
case _OnboardingAnswer():
return $default(_that.id,_that.textKey,_that.points);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String textKey,  int points)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingAnswer() when $default != null:
return $default(_that.id,_that.textKey,_that.points);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingAnswer implements OnboardingAnswer {
  const _OnboardingAnswer({required this.id, required this.textKey, required this.points});
  

@override final  String id;
@override final  String textKey;
@override final  int points;

/// Create a copy of OnboardingAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingAnswerCopyWith<_OnboardingAnswer> get copyWith => __$OnboardingAnswerCopyWithImpl<_OnboardingAnswer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingAnswer&&(identical(other.id, id) || other.id == id)&&(identical(other.textKey, textKey) || other.textKey == textKey)&&(identical(other.points, points) || other.points == points));
}


@override
int get hashCode => Object.hash(runtimeType,id,textKey,points);

@override
String toString() {
  return 'OnboardingAnswer(id: $id, textKey: $textKey, points: $points)';
}


}

/// @nodoc
abstract mixin class _$OnboardingAnswerCopyWith<$Res> implements $OnboardingAnswerCopyWith<$Res> {
  factory _$OnboardingAnswerCopyWith(_OnboardingAnswer value, $Res Function(_OnboardingAnswer) _then) = __$OnboardingAnswerCopyWithImpl;
@override @useResult
$Res call({
 String id, String textKey, int points
});




}
/// @nodoc
class __$OnboardingAnswerCopyWithImpl<$Res>
    implements _$OnboardingAnswerCopyWith<$Res> {
  __$OnboardingAnswerCopyWithImpl(this._self, this._then);

  final _OnboardingAnswer _self;
  final $Res Function(_OnboardingAnswer) _then;

/// Create a copy of OnboardingAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? textKey = null,Object? points = null,}) {
  return _then(_OnboardingAnswer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textKey: null == textKey ? _self.textKey : textKey // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
