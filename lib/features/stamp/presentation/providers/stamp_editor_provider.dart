import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stampshunter/core/network/api_client.dart';
import 'package:stampshunter/core/services/upload_service.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/stamp/data/datasources/stamp_remote_datasource.dart';
import 'package:stampshunter/features/stamp/data/repositories/stamp_repository_impl.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp_style.dart';
import 'package:stampshunter/features/stamp/domain/repositories/stamp_repository.dart';

part 'stamp_editor_provider.freezed.dart';
part 'stamp_editor_provider.g.dart';

// ── Dependency Injection Providers ───────────────────────────────────────────

final uploadServiceProvider = Provider<UploadService>((ref) {
  final local = ref.watch(authLocalDatasourceProvider);
  final token = local.getAccessToken();
  final apiClient = ApiClient();
  if (token != null) {
    apiClient.setToken(token);
  }
  return UploadService(apiClient: apiClient);
});

final stampRemoteDataSourceProvider = Provider<StampRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final uploadService = ref.watch(uploadServiceProvider);
  return StampRemoteDataSource(dio: dio, uploadService: uploadService);
});

final stampRepositoryProvider = Provider<StampRepository>((ref) {
  final remoteDataSource = ref.watch(stampRemoteDataSourceProvider);
  return StampRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ── State Class ──────────────────────────────────────────────────────────────

@freezed
class StampEditorState with _$StampEditorState {
  const factory StampEditorState({
    String? imagePath,
    required StampStyle style,
    @Default(false) bool isProcessing,
    String? errorMessage,
    @Default([]) List<StampStyle> history,
    @Default(0) int historyIndex,
  }) = _StampEditorState;
}

// ── Notifier Provider ────────────────────────────────────────────────────────

@riverpod
class StampEditor extends _$StampEditor {
  @override
  StampEditorState build() {
    const initialStyle = StampStyle();
    return const StampEditorState(
      style: initialStyle,
      history: [initialStyle],
      historyIndex: 0,
    );
  }

  /// Menetapkan path gambar asli
  void setImagePath(String path) {
    state = state.copyWith(imagePath: path);
  }

  void _updateStyle(StampStyle newStyle) {
    final newHistory = state.history.sublist(0, state.historyIndex + 1);
    state = state.copyWith(
      style: newStyle,
      history: [...newHistory, newStyle],
      historyIndex: newHistory.length,
    );
  }

  // ── Border Modifiers ───────────────────────────────────────────────────────

  void setBorderEnabled(bool enabled) {
    _updateStyle(state.style.copyWith(
      border: state.style.border.copyWith(enabled: enabled),
    ));
  }

  void setToothSize(int size) {
    _updateStyle(state.style.copyWith(
      border: state.style.border.copyWith(toothSize: size),
    ));
  }

  void setToothSpacing(int spacing) {
    _updateStyle(state.style.copyWith(
      border: state.style.border.copyWith(toothSpacing: spacing),
    ));
  }

  void setBorderWidth(int width) {
    _updateStyle(state.style.copyWith(
      border: state.style.border.copyWith(borderWidth: width),
    ));
  }

  void setBorderColor(Color color) {
    _updateStyle(state.style.copyWith(
      border: state.style.border.copyWith(borderColor: color),
    ));
  }

  // ── Filter Modifiers ───────────────────────────────────────────────────────

  void setFilterEnabled(bool enabled) {
    _updateStyle(state.style.copyWith(
      filter: state.style.filter.copyWith(enabled: enabled),
    ));
  }

  void setFilterIntensity(double intensity) {
    _updateStyle(state.style.copyWith(
      filter: state.style.filter.copyWith(intensity: intensity),
    ));
  }

  void setFilterWarmth(double warmth) {
    _updateStyle(state.style.copyWith(
      filter: state.style.filter.copyWith(warmth: warmth),
    ));
  }

  void setFilterGrain(double grain) {
    _updateStyle(state.style.copyWith(
      filter: state.style.filter.copyWith(grain: grain),
    ));
  }

  void setFilterVignette(double vignette) {
    _updateStyle(state.style.copyWith(
      filter: state.style.filter.copyWith(vignette: vignette),
    ));
  }

  void setFilterSepia(double sepia) {
    _updateStyle(state.style.copyWith(
      filter: state.style.filter.copyWith(sepia: sepia),
    ));
  }

  // ── Template Modifiers ─────────────────────────────────────────────────────

  void setTemplateEnabled(bool enabled) {
    _updateStyle(state.style.copyWith(
      template: state.style.template.copyWith(enabled: enabled),
    ));
  }

  void setTemplate(TemplateConfig template) {
    _updateStyle(state.style.copyWith(
      template: template,
    ));
  }

  // ── Text Modifiers ─────────────────────────────────────────────────────────

  void setTextEnabled(bool enabled) {
    _updateStyle(state.style.copyWith(
      textEnabled: enabled,
    ));
  }

  void addTextOverlay(TextOverlayConfig text) {
    _updateStyle(state.style.copyWith(
      textOverlays: [...state.style.textOverlays, text],
    ));
  }

  void updateTextOverlay(int index, TextOverlayConfig text) {
    if (index >= 0 && index < state.style.textOverlays.length) {
      final list = List<TextOverlayConfig>.from(state.style.textOverlays);
      list[index] = text;
      _updateStyle(state.style.copyWith(
        textOverlays: list,
      ));
    }
  }

  void removeTextOverlay(int index) {
    if (index >= 0 && index < state.style.textOverlays.length) {
      final list = List<TextOverlayConfig>.from(state.style.textOverlays);
      list.removeAt(index);
      _updateStyle(state.style.copyWith(
        textOverlays: list,
      ));
    }
  }

  // ── History Controls ───────────────────────────────────────────────────────

  void undo() {
    if (state.historyIndex > 0) {
      final newIndex = state.historyIndex - 1;
      state = state.copyWith(
        style: state.history[newIndex],
        historyIndex: newIndex,
      );
    }
  }

  void redo() {
    if (state.historyIndex < state.history.length - 1) {
      final newIndex = state.historyIndex + 1;
      state = state.copyWith(
        style: state.history[newIndex],
        historyIndex: newIndex,
      );
    }
  }

  void reset() {
    const defaultStyle = StampStyle();
    _updateStyle(defaultStyle);
  }

  // ── Save Action ────────────────────────────────────────────────────────────

  Future<Stamp?> save({
    required String title,
    String? description,
    List<String>? tags,
    required bool isPublic,
  }) async {
    final imagePath = state.imagePath;
    if (imagePath == null) {
      state = state.copyWith(errorMessage: 'Tidak ada gambar yang terpilih');
      return null;
    }

    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final repository = ref.read(stampRepositoryProvider);
      final stamp = await repository.createStamp(
        file: File(imagePath),
        title: title,
        description: description,
        tags: tags,
        isPublic: isPublic,
        style: state.style,
      );

      state = state.copyWith(isProcessing: false);
      return stamp;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal menyimpan stamp: $e',
      );
      return null;
    }
  }
}
