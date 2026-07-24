import 'package:dio/dio.dart';
import 'package:stampshunter/core/errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;

    if (data != null && data is Map<String, dynamic> && data['error'] != null) {
      final error = data['error'];
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: AppException(
          code: error['code'] ?? 'UNKNOWN',
          message: error['message'] ?? 'An error occurred',
        ),
      ));
      return;
    }

    handler.next(err);
  }
}
