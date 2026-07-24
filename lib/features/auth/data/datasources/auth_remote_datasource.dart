import 'package:dio/dio.dart';
import 'package:stampshunter/features/auth/domain/entities/user.dart';
import 'package:stampshunter/core/errors/exceptions.dart' show AppException, ErrorDetail;

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await dio.post('/api/v1/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
        if (displayName != null) 'display_name': displayName,
      });
      return AuthResult.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });
      return AuthResult.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Validasi access token ke server — dipanggil saat app restart untuk memastikan
  /// token yang tersimpan masih valid. Mengembalikan User jika valid.
  Future<User> getMe(String accessToken) async {
    try {
      final response = await dio.get(
        '/api/v1/users/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      // Response: { "success": true, "data": { ...user fields } }
      final data = response.data['data'] as Map<String, dynamic>;
      return User.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Tukar refresh token dengan access token baru (silent refresh).
  Future<({String accessToken, String refreshToken})> refreshToken(
    String refreshToken,
  ) async {
    try {
      final response = await dio.post('/api/v1/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return (
        accessToken: response.data['access_token'] as String,
        refreshToken: response.data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException e) {
    // Network errors (no response)
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

    // Structured error: {"detail": {"code": "...", "message": "..."}}
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

    // Pydantic validation error: {"detail": [{"loc": [...], "msg": "...", "type": "..."}]}
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

    // String error: {"detail": "error message"}
    return AppException(code: 'UNKNOWN', message: detail.toString());
  }
}
