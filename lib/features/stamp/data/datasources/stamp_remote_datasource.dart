import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:stampshunter/core/services/upload_service.dart';
import 'package:stampshunter/core/errors/exceptions.dart' show AppException, ErrorDetail;
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp_style.dart';

class StampRemoteDataSource {
  final Dio dio;
  final UploadService uploadService;

  StampRemoteDataSource({
    required this.dio,
    required this.uploadService,
  });

  /// Buat stamp baru di backend
  Future<Stamp> createStamp({
    required File file,
    String? title,
    String? description,
    List<String>? tags,
    required bool isPublic,
    required StampStyle style,
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'stamp_style': jsonEncode(style.toJson()),
        'is_public': isPublic,
      };

      if (title != null) formDataMap['title'] = title;
      if (description != null) formDataMap['description'] = description;
      if (tags != null && tags.isNotEmpty) {
        formDataMap['tags'] = jsonEncode(tags);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await dio.post(
        '/api/v1/stamps',
        data: formData,
      );

      final responseData = response.data;
      if (responseData['success'] == true) {
        return Stamp.fromJson(responseData['data']);
      } else {
        throw AppException(
          code: 'UNKNOWN',
          message: responseData['message'] ?? 'Gagal membuat stamp',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload stamp image. Attempts direct Supabase upload first, falling back to server-side upload on failure.
  Future<String> uploadStampImage(File file) async {
    try {
      // Primary: Direct upload to Supabase Storage
      return await uploadService.uploadToSupabase(
        file: file,
        bucket: 'stamps',
      );
    } catch (supabaseError) {
      // Fallback: Upload to backend FastAPI
      try {
        final result = await uploadService.uploadToBackend(
          file: file,
          bucket: 'stamps',
        );
        return result['url'] as String;
      } on DioException catch (dioError) {
        throw _handleError(dioError);
      } catch (e) {
        throw AppException(
          code: 'UPLOAD_ERROR',
          message: 'Gagal mengunggah gambar stamp: $e',
        );
      }
    }
  }

  Future<Stamp> getStamp(String stampId) async {
    try {
      final response = await dio.get('/api/v1/stamps/$stampId');
      return Stamp.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AppException(code: 'TIMEOUT', message: 'Koneksi timeout');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return AppException(code: 'NETWORK_ERROR', message: 'Tidak bisa terhubung ke server');
    }

    final data = e.response?.data;
    if (data == null || data is! Map<String, dynamic>) {
      return AppException(code: 'NETWORK_ERROR', message: 'Gagal terhubung ke server');
    }

    final detail = data['detail'];
    if (detail == null) {
      return AppException(code: 'UNKNOWN', message: 'Terjadi kesalahan yang tidak diketahui');
    }

    if (detail is Map<String, dynamic>) {
      final code = detail['code'] ?? 'UNKNOWN';
      final message = detail['message'] ?? 'Terjadi kesalahan';
      final details = (detail['details'] as List?)
          ?.map((d) => ErrorDetail(
                field: d['field'] ?? '',
                message: d['message'] ?? '',
              ))
          .toList() ?? [];
      return AppException(code: code, message: message, details: details);
    }

    return AppException(code: 'UNKNOWN', message: detail.toString());
  }
}
