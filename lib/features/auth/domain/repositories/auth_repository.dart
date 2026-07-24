import 'package:stampshunter/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  });

  Future<AuthResult> login({
    required String email,
    required String password,
  });

  /// Restore session dari storage lokal. Melakukan validasi ke server.
  /// Returns null jika tidak ada sesi tersimpan atau token sudah tidak valid
  /// dan refresh token juga sudah expired.
  Future<AuthRestoreResult?> getCurrentUser();

  Future<void> logout();
}

/// Result dari getCurrentUser — membawa user dan token terbaru
/// (mungkin sudah di-refresh secara silent).
class AuthRestoreResult {
  final User user;
  final String accessToken;
  final String refreshToken;

  const AuthRestoreResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}
