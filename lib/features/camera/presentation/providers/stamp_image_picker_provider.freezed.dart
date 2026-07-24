// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stamp_image_picker_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$StampImagePickerState {
  String? get selectedImagePath => throw _privateConstructorUsedError;
  String? get croppedImagePath => throw _privateConstructorUsedError;
  bool get isProcessing => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of StampImagePickerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StampImagePickerStateCopyWith<StampImagePickerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StampImagePickerStateCopyWith<$Res> {
  factory $StampImagePickerStateCopyWith(
    StampImagePickerState value,
    $Res Function(StampImagePickerState) then,
  ) = _$StampImagePickerStateCopyWithImpl<$Res, StampImagePickerState>;
  @useResult
  $Res call({
    String? selectedImagePath,
    String? croppedImagePath,
    bool isProcessing,
    String? errorMessage,
  });
}

/// @nodoc
class _$StampImagePickerStateCopyWithImpl<
  $Res,
  $Val extends StampImagePickerState
>
    implements $StampImagePickerStateCopyWith<$Res> {
  _$StampImagePickerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StampImagePickerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedImagePath = freezed,
    Object? croppedImagePath = freezed,
    Object? isProcessing = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            selectedImagePath: freezed == selectedImagePath
                ? _value.selectedImagePath
                : selectedImagePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            croppedImagePath: freezed == croppedImagePath
                ? _value.croppedImagePath
                : croppedImagePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            isProcessing: null == isProcessing
                ? _value.isProcessing
                : isProcessing // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StampImagePickerStateImplCopyWith<$Res>
    implements $StampImagePickerStateCopyWith<$Res> {
  factory _$$StampImagePickerStateImplCopyWith(
    _$StampImagePickerStateImpl value,
    $Res Function(_$StampImagePickerStateImpl) then,
  ) = __$$StampImagePickerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? selectedImagePath,
    String? croppedImagePath,
    bool isProcessing,
    String? errorMessage,
  });
}

/// @nodoc
class __$$StampImagePickerStateImplCopyWithImpl<$Res>
    extends
        _$StampImagePickerStateCopyWithImpl<$Res, _$StampImagePickerStateImpl>
    implements _$$StampImagePickerStateImplCopyWith<$Res> {
  __$$StampImagePickerStateImplCopyWithImpl(
    _$StampImagePickerStateImpl _value,
    $Res Function(_$StampImagePickerStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StampImagePickerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedImagePath = freezed,
    Object? croppedImagePath = freezed,
    Object? isProcessing = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$StampImagePickerStateImpl(
        selectedImagePath: freezed == selectedImagePath
            ? _value.selectedImagePath
            : selectedImagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        croppedImagePath: freezed == croppedImagePath
            ? _value.croppedImagePath
            : croppedImagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        isProcessing: null == isProcessing
            ? _value.isProcessing
            : isProcessing // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$StampImagePickerStateImpl implements _StampImagePickerState {
  const _$StampImagePickerStateImpl({
    this.selectedImagePath,
    this.croppedImagePath,
    this.isProcessing = false,
    this.errorMessage,
  });

  @override
  final String? selectedImagePath;
  @override
  final String? croppedImagePath;
  @override
  @JsonKey()
  final bool isProcessing;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'StampImagePickerState(selectedImagePath: $selectedImagePath, croppedImagePath: $croppedImagePath, isProcessing: $isProcessing, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StampImagePickerStateImpl &&
            (identical(other.selectedImagePath, selectedImagePath) ||
                other.selectedImagePath == selectedImagePath) &&
            (identical(other.croppedImagePath, croppedImagePath) ||
                other.croppedImagePath == croppedImagePath) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    selectedImagePath,
    croppedImagePath,
    isProcessing,
    errorMessage,
  );

  /// Create a copy of StampImagePickerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StampImagePickerStateImplCopyWith<_$StampImagePickerStateImpl>
  get copyWith =>
      __$$StampImagePickerStateImplCopyWithImpl<_$StampImagePickerStateImpl>(
        this,
        _$identity,
      );
}

abstract class _StampImagePickerState implements StampImagePickerState {
  const factory _StampImagePickerState({
    final String? selectedImagePath,
    final String? croppedImagePath,
    final bool isProcessing,
    final String? errorMessage,
  }) = _$StampImagePickerStateImpl;

  @override
  String? get selectedImagePath;
  @override
  String? get croppedImagePath;
  @override
  bool get isProcessing;
  @override
  String? get errorMessage;

  /// Create a copy of StampImagePickerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StampImagePickerStateImplCopyWith<_$StampImagePickerStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
