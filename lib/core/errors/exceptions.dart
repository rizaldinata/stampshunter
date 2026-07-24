class AppException implements Exception {
  final String code;
  final String message;
  final List<ErrorDetail> details;

  AppException({
    required this.code,
    required this.message,
    this.details = const [],
  });

  String get userMessage {
    switch (code) {
      case 'AUTH_ERROR':
      case 'TOKEN_EXPIRED':
        return 'Sesi kamu sudah habis. Silakan login kembali.';
      case 'INVALID_CREDENTIALS':
        return 'Email atau password yang kamu masukkan salah. Periksa kembali data kamu.';
      case 'FORBIDDEN':
        return 'Kamu tidak punya akses untuk melakukan ini.';
      case 'VALIDATION_ERROR':
        if (details.isNotEmpty) {
          return details.map((d) => d.message).join('\n');
        }
        return 'Data yang dimasukkan tidak valid. Periksa kembali form kamu.';
      case 'CONFLICT':
        return message.isNotEmpty ? message : 'Data yang kamu masukkan sudah ada.';
      case 'NOT_FOUND':
        return 'Data tidak ditemukan.';
      case 'RATE_LIMITED':
        return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
      case 'NETWORK_ERROR':
        return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
      case 'TIMEOUT':
        return 'Koneksi timeout. Coba lagi dalam beberapa saat.';
      default:
        return message.isNotEmpty ? message : 'Terjadi kesalahan. Coba lagi.';
    }
  }

  @override
  String toString() => 'AppException($code: $message)';
}

class ErrorDetail {
  final String field;
  final String message;

  ErrorDetail({required this.field, required this.message});
}
