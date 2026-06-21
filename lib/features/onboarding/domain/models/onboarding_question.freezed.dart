// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingQuestion {

 String get id; String get textKey; List<OnboardingAnswer> get answers;
/// Create a copy of OnboardingQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingQuestionCopyWith<OnboardingQuestion> get copyWith => _$OnboardingQuestionCopyWithImpl<OnboardingQuestion>(this as OnboardingQuestion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.textKey, textKey) || other.textKey == textKey)&&const DeepCollectionEquality().equals(other.answers, answers));
}


@override
int get hashCode => Object.hash(runtimeType,id,textKey,const DeepCollectionEquality().hash(answers));

@override
String toString() {
  return 'OnboardingQuestion(id: $id, textKey: $textKey, answers: $answers)';
}


}

/// @nodoc
abstract mixin class $OnboardingQuestionCopyWith<$Res>  {
  factory $OnboardingQuestionCopyWith(OnboardingQuestion value, $Res Function(OnboardingQuestion) _then) = _$OnboardingQuestionCopyWithImpl;
@useResult
$Res call({
 String id, String textKey, List<OnboardingAnswer> answers
});




}
/// @nodoc
class _$OnboardingQuestionCopyWithImpl<$Res>
    implements $OnboardingQuestionCopyWith<$Res> {
  _$OnboardingQuestionCopyWithImpl(this._self, this._then);

  final OnboardingQuestion _self;
  final $Res Function(OnboardingQuestion) _then;

/// Create a copy of OnboardingQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? textKey = null,Object? answers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textKey: null == textKey ? _self.textKey : textKey // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<OnboardingAnswer>,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingQuestion].
extension OnboardingQuestionPatterns on OnboardingQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingQuestion value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String textKey,  List<OnboardingAnswer> answers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingQuestion() when $default != null:
return $default(_that.id,_that.textKey,_that.answers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String textKey,  List<OnboardingAnswer> answers)  $default,) {final _that = this;
switch (_that) {
case _OnboardingQuestion():
return $default(_that.id,_that.textKey,_that.answers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String textKey,  List<OnboardingAnswer> answers)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingQuestion() when $default != null:
return $default(_that.id,_that.textKey,_that.answers);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingQuestion implements OnboardingQuestion {
  const _OnboardingQuestion({required this.id, required this.textKey, required final  List<OnboardingAnswer> answers}): _answers = answers;
  

@override final  String id;
@override final  String textKey;
 final  List<OnboardingAnswer> _answers;
@override List<OnboardingAnswer> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}


/// Create a copy of OnboardingQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingQuestionCopyWith<_OnboardingQuestion> get copyWith => __$OnboardingQuestionCopyWithImpl<_OnboardingQuestion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.textKey, textKey) || other.textKey == textKey)&&const DeepCollectionEquality().equals(other._answers, _answers));
}


@override
int get hashCode => Object.hash(runtimeType,id,textKey,const DeepCollectionEquality().hash(_answers));

@override
String toString() {
  return 'OnboardingQuestion(id: $id, textKey: $textKey, answers: $answers)';
}


}

/// @nodoc
abstract mixin class _$OnboardingQuestionCopyWith<$Res> implements $OnboardingQuestionCopyWith<$Res> {
  factory _$OnboardingQuestionCopyWith(_OnboardingQuestion value, $Res Function(_OnboardingQuestion) _then) = __$OnboardingQuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String textKey, List<OnboardingAnswer> answers
});




}
/// @nodoc
class __$OnboardingQuestionCopyWithImpl<$Res>
    implements _$OnboardingQuestionCopyWith<$Res> {
  __$OnboardingQuestionCopyWithImpl(this._self, this._then);

  final _OnboardingQuestion _self;
  final $Res Function(_OnboardingQuestion) _then;

/// Create a copy of OnboardingQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? textKey = null,Object? answers = null,}) {
  return _then(_OnboardingQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textKey: null == textKey ? _self.textKey : textKey // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<OnboardingAnswer>,
  ));
}


}

// dart format on
