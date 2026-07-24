import 'package:dio/dio.dart';
import 'package:stampshunter/features/profile/domain/entities/user_profile.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/core/errors/exceptions.dart' show AppException, ErrorDetail;

class ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSource({required this.dio});

  Future<UserProfile> getMe(String token) async {
    try {
      final response = await dio.get(
        '/api/v1/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        return UserProfile.fromJson(responseData['data']);
      } else {
        throw AppException(code: 'UNKNOWN', message: responseData['message'] ?? 'Gagal memuat profil');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final response = await dio.get('/api/v1/users/$userId');
      final responseData = response.data;
      if (responseData['success'] == true) {
        return UserProfile.fromJson(responseData['data']);
      } else {
        throw AppException(code: 'UNKNOWN', message: responseData['message'] ?? 'Gagal memuat profil');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> updateUserProfile({
    required String token,
    String? displayName,
    String? bio,
    List<int>? avatarBytes,
    String? avatarFilename,
  }) async {
    try {
      final formDataMap = <String, dynamic>{};
      if (displayName != null) formDataMap['display_name'] = displayName;
      if (bio != null) formDataMap['bio'] = bio;

      if (avatarBytes != null && avatarFilename != null) {
        formDataMap['avatar'] = MultipartFile.fromBytes(
          avatarBytes,
          filename: avatarFilename,
        );
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await dio.put(
        '/api/v1/users/me',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        return UserProfile.fromJson(responseData['data']);
      } else {
        throw AppException(code: 'UNKNOWN', message: responseData['message'] ?? 'Gagal memperbarui profil');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Stamp>> getUserStamps({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/users/$userId/stamps',
        queryParameters: {'page': page, 'limit': limit},
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((item) => Stamp.fromJson(item)).toList();
      } else {
        throw AppException(code: 'UNKNOWN', message: responseData['message'] ?? 'Gagal memuat stamp');
      }
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

    if (detail is List) {
      final details = detail.map((d) {
        final loc = (d['loc'] as List?)?.join('.') ?? '';
        final msg = d['msg'] ?? 'Field tidak valid';
        return ErrorDetail(field: loc, message: msg);
      }).toList();
      return AppException(
        code: 'VALIDATION_ERROR',
        message: 'Data yang dimasukkan tidak valid',
        details: details,
      );
    }

    return AppException(code: 'UNKNOWN', message: detail.toString());
  }
}
