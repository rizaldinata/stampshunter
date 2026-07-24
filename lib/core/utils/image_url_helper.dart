import 'package:stampshunter/core/constants/api_constants.dart';

class ImageUrlHelper {
  /// Construct the full URL for an image path (works for local backend static URLs, absolute URLs, and Supabase public URLs).
  static String build(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }

    // If it's already a full URL (Supabase CDN, external images, etc.)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // If it's a backend local fallback static path
    if (path.startsWith('/static/')) {
      // Remove '/api/v1' from base URL to get the server root URL
      final host = ApiConstants.baseUrl.replaceAll('/api/v1', '');
      return '$host$path';
    }

    // If it's just a relative path without leading slash, assume it might be a static path
    if (path.startsWith('static/')) {
      final host = ApiConstants.baseUrl.replaceAll('/api/v1', '');
      return '$host/$path';
    }

    return path;
  }
}
