import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stamp_image_picker_provider.freezed.dart';
part 'stamp_image_picker_provider.g.dart';

@freezed
class StampImagePickerState with _$StampImagePickerState {
  const factory StampImagePickerState({
    String? selectedImagePath,
    String? croppedImagePath,
    @Default(false) bool isProcessing,
    String? errorMessage,
  }) = _StampImagePickerState;
}

@riverpod
class StampImagePicker extends _$StampImagePicker {
  @override
  StampImagePickerState build() {
    return const StampImagePickerState();
  }

  /// Memilih gambar dari galeri peranti
  Future<bool> pickFromGallery() async {
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      // Pada Android 13+ (API 33+), image_picker menggunakan system photo picker
      // yang tidak memerlukan izin runtime storage. Namun untuk keamanan multi-platform,
      // kita gunakan check permission default.
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        state = state.copyWith(
          selectedImagePath: image.path,
          isProcessing: false,
        );
        return true;
      }
      
      state = state.copyWith(isProcessing: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal memilih gambar dari galeri: $e',
      );
      return false;
    }
  }

  /// Mengambil izin kamera
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Memproses pemotongan gambar menggunakan image_cropper dengan tema Postal Noir
  Future<String?> cropImage(String sourcePath) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Sesuaikan Foto',
            // Estetika Postal Noir: Gelap dengan aksen Amber
            toolbarColor: const Color(0xFF0A0A0A),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFFFB300), // Amber
            backgroundColor: const Color(0xFF0A0A0A),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
          ),
          IOSUiSettings(
            title: 'Sesuaikan Foto',
            doneButtonTitle: 'Selesai',
            cancelButtonTitle: 'Batal',
            aspectRatioLockEnabled: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        state = state.copyWith(
          croppedImagePath: croppedFile.path,
          isProcessing: false,
        );
        return croppedFile.path;
      }

      state = state.copyWith(isProcessing: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal memotong gambar: $e',
      );
      return null;
    }
  }

  /// Reset state pilihan gambar
  void clear() {
    state = const StampImagePickerState();
  }
}
