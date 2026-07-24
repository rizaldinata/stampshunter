import 'package:dio/dio.dart';
import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/domain/entities/feed_comment.dart';
import 'package:stampshunter/core/errors/exceptions.dart' show AppException, ErrorDetail;

class FeedRemoteDataSource {
  final Dio dio;

  FeedRemoteDataSource({required this.dio});

  Future<List<StampCard>> getPublicFeed({
    int page = 1,
    int limit = 20,
    required String sort,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/feed/public',
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': sort,
        },
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((item) => StampCard.fromJson(item)).toList();
      } else {
        throw AppException(
          code: 'UNKNOWN',
          message: responseData['message'] ?? 'Gagal memuat feed',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<StampCard>> getFollowingFeed({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/feed/following',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((item) => StampCard.fromJson(item)).toList();
      } else {
        throw AppException(
          code: 'UNKNOWN',
          message: responseData['message'] ?? 'Gagal memuat feed following',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> toggleLike(String stampId) async {
    try {
      final response = await dio.post('/api/v1/stamps/$stampId/like');
      final responseData = response.data;
      if (responseData['success'] == true) {
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw AppException(
          code: 'UNKNOWN',
          message: responseData['message'] ?? 'Gagal menyukai stamp',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<FeedComment>> getComments(
    String stampId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/stamps/$stampId/comments',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((item) => FeedComment.fromJson(item)).toList();
      } else {
        throw AppException(
          code: 'UNKNOWN',
          message: responseData['message'] ?? 'Gagal memuat komentar',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FeedComment> addComment(
    String stampId, {
    required String content,
    String? parentId,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/stamps/$stampId/comments',
        data: {
          'content': content,
          'parent_id': parentId,
        },
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        return FeedComment.fromJson(responseData['data']);
      } else {
        throw AppException(
          code: 'UNKNOWN',
          message: responseData['message'] ?? 'Gagal mengirim komentar',
        );
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
