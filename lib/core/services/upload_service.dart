import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:stampshunter/core/network/api_client.dart';

class UploadService {
  final SupabaseClient _supabaseClient;
  final ApiClient _apiClient;

  UploadService({
    SupabaseClient? supabaseClient,
    ApiClient? apiClient,
  })  : _supabaseClient = supabaseClient ?? Supabase.instance.client,
        _apiClient = apiClient ?? ApiClient();

  /// Upload file directly to Supabase Storage (Client-side)
  Future<String> uploadToSupabase({
    required File file,
    required String bucket,
    String? customPath,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id ?? 'guest';
      final fileName = file.path.split('/').last;
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final filePath = customPath ?? '$userId/$uniqueName';

      // Perform upload
      await _supabaseClient.storage.from(bucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Return public URL
      final String publicUrl = _supabaseClient.storage.from(bucket).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Gagal mengunggah ke Supabase: $e');
    }
  }

  /// Upload file through the backend FastAPI upload endpoint (Server-side)
  Future<Map<String, dynamic>> uploadToBackend({
    required File file,
    required String bucket,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'bucket': bucket,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '/api/v1/upload/image',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw Exception(response.data?['detail']?['message'] ?? 'Gagal mengunggah file.');
    } catch (e) {
      throw Exception('Gagal mengunggah ke Backend: $e');
    }
  }
}
