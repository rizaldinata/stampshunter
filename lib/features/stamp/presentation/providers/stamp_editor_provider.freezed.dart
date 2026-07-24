// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stamp_editor_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$StampEditorState {
  String? get imagePath => throw _privateConstructorUsedError;
  StampStyle get style => throw _privateConstructorUsedError;
  bool get isProcessing => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  List<StampStyle> get history => throw _privateConstructorUsedError;
  int get historyIndex => throw _privateConstructorUsedError;

  /// Create a copy of StampEditorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StampEditorStateCopyWith<StampEditorState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StampEditorStateCopyWith<$Res> {
  factory $StampEditorStateCopyWith(
    StampEditorState value,
    $Res Function(StampEditorState) then,
  ) = _$StampEditorStateCopyWithImpl<$Res, StampEditorState>;
  @useResult
  $Res call({
    String? imagePath,
    StampStyle style,
    bool isProcessing,
    String? errorMessage,
    List<StampStyle> history,
    int historyIndex,
  });
}

/// @nodoc
class _$StampEditorStateCopyWithImpl<$Res, $Val extends StampEditorState>
    implements $StampEditorStateCopyWith<$Res> {
  _$StampEditorStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StampEditorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imagePath = freezed,
    Object? style = null,
    Object? isProcessing = null,
    Object? errorMessage = freezed,
    Object? history = null,
    Object? historyIndex = null,
  }) {
    return _then(
      _value.copyWith(
            imagePath: freezed == imagePath
                ? _value.imagePath
                : imagePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            style: null == style
                ? _value.style
                : style // ignore: cast_nullable_to_non_nullable
                      as StampStyle,
            isProcessing: null == isProcessing
                ? _value.isProcessing
                : isProcessing // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            history: null == history
                ? _value.history
                : history // ignore: cast_nullable_to_non_nullable
                      as List<StampStyle>,
            historyIndex: null == historyIndex
                ? _value.historyIndex
                : historyIndex // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StampEditorStateImplCopyWith<$Res>
    implements $StampEditorStateCopyWith<$Res> {
  factory _$$StampEditorStateImplCopyWith(
    _$StampEditorStateImpl value,
    $Res Function(_$StampEditorStateImpl) then,
  ) = __$$StampEditorStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? imagePath,
    StampStyle style,
    bool isProcessing,
    String? errorMessage,
    List<StampStyle> history,
    int historyIndex,
  });
}

/// @nodoc
class __$$StampEditorStateImplCopyWithImpl<$Res>
    extends _$StampEditorStateCopyWithImpl<$Res, _$StampEditorStateImpl>
    implements _$$StampEditorStateImplCopyWith<$Res> {
  __$$StampEditorStateImplCopyWithImpl(
    _$StampEditorStateImpl _value,
    $Res Function(_$StampEditorStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StampEditorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imagePath = freezed,
    Object? style = null,
    Object? isProcessing = null,
    Object? errorMessage = freezed,
    Object? history = null,
    Object? historyIndex = null,
  }) {
    return _then(
      _$StampEditorStateImpl(
        imagePath: freezed == imagePath
            ? _value.imagePath
            : imagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        style: null == style
            ? _value.style
            : style // ignore: cast_nullable_to_non_nullable
                  as StampStyle,
        isProcessing: null == isProcessing
            ? _value.isProcessing
            : isProcessing // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<StampStyle>,
        historyIndex: null == historyIndex
            ? _value.historyIndex
            : historyIndex // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$StampEditorStateImpl implements _StampEditorState {
  const _$StampEditorStateImpl({
    this.imagePath,
    required this.style,
    this.isProcessing = false,
    this.errorMessage,
    final List<StampStyle> history = const [],
    this.historyIndex = 0,
  }) : _history = history;

  @override
  final String? imagePath;
  @override
  final StampStyle style;
  @override
  @JsonKey()
  final bool isProcessing;
  @override
  final String? errorMessage;
  final List<StampStyle> _history;
  @override
  @JsonKey()
  List<StampStyle> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  @JsonKey()
  final int historyIndex;

  @override
  String toString() {
    return 'StampEditorState(imagePath: $imagePath, style: $style, isProcessing: $isProcessing, errorMessage: $errorMessage, history: $history, historyIndex: $historyIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StampEditorStateImpl &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            (identical(other.historyIndex, historyIndex) ||
                other.historyIndex == historyIndex));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    imagePath,
    style,
    isProcessing,
    errorMessage,
    const DeepCollectionEquality().hash(_history),
    historyIndex,
  );

  /// Create a copy of StampEditorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StampEditorStateImplCopyWith<_$StampEditorStateImpl> get copyWith =>
      __$$StampEditorStateImplCopyWithImpl<_$StampEditorStateImpl>(
        this,
        _$identity,
      );
}

abstract class _StampEditorState implements StampEditorState {
  const factory _StampEditorState({
    final String? imagePath,
    required final StampStyle style,
    final bool isProcessing,
    final String? errorMessage,
    final List<StampStyle> history,
    final int historyIndex,
  }) = _$StampEditorStateImpl;

  @override
  String? get imagePath;
  @override
  StampStyle get style;
  @override
  bool get isProcessing;
  @override
  String? get errorMessage;
  @override
  List<StampStyle> get history;
  @override
  int get historyIndex;

  /// Create a copy of StampEditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StampEditorStateImplCopyWith<_$StampEditorStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
