import 'package:stampshunter/features/auth/domain/entities/user.dart';
import 'package:stampshunter/features/auth/domain/repositories/auth_repository.dart';
import 'package:stampshunter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:stampshunter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:stampshunter/core/errors/exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDatasource localDatasource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatasource,
  });

  @override
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    return remoteDataSource.register(
      username: username,
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return remoteDataSource.login(email: email, password: password);
  }

  /// Restore sesi dari storage lokal dengan validasi ke server.
  ///
  /// Alur:
  /// 1. Baca access token dari SharedPreferences
  /// 2. Jika tidak ada → return null (belum pernah login)
  /// 3. Coba GET /users/me dengan access token
  /// 4. Jika sukses → return AuthRestoreResult
  /// 5. Jika 401 (access token expired) → coba refresh dengan refresh token
  /// 6. Jika refresh sukses → simpan token baru, return AuthRestoreResult
  /// 7. Jika refresh gagal → clear storage, return null (paksa login ulang)
  @override
  Future<AuthRestoreResult?> getCurrentUser() async {
    final accessToken = localDatasource.getAccessToken();
    if (accessToken == null) return null;

    // Coba dengan access token yang ada
    try {
      final user = await remoteDataSource.getMe(accessToken);
      final refreshToken = localDatasource.getRefreshToken()!;
      return AuthRestoreResult(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on AppException catch (e) {
      // Jika 401 (AUTH_ERROR / TOKEN_EXPIRED) → coba silent refresh
      if (e.code != 'AUTH_ERROR' && e.code != 'TOKEN_EXPIRED') {
        // Error lain (network, server error) → jangan hapus sesi, biarkan app
        // berjalan dengan data lokal dan retry nanti
        final cachedUser = localDatasource.getUser();
        final refreshToken = localDatasource.getRefreshToken();
        if (cachedUser != null && refreshToken != null) {
          return AuthRestoreResult(
            user: cachedUser,
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        }
        return null;
      }

      // Token expired → silent refresh
      return _tryRefresh();
    } catch (_) {
      // Network tidak tersedia → gunakan data lokal jika ada
      final cachedUser = localDatasource.getUser();
      final refreshToken = localDatasource.getRefreshToken();
      if (cachedUser != null && refreshToken != null) {
        return AuthRestoreResult(
          user: cachedUser,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      return null;
    }
  }

  /// Coba silent refresh menggunakan refresh token.
  Future<AuthRestoreResult?> _tryRefresh() async {
    final storedRefreshToken = localDatasource.getRefreshToken();
    if (storedRefreshToken == null) {
      await localDatasource.clearAll();
      return null;
    }

    try {
      final newTokens = await remoteDataSource.refreshToken(storedRefreshToken);
      // Ambil user data dengan access token baru
      final user = await remoteDataSource.getMe(newTokens.accessToken);
      // Simpan token baru ke storage
      await localDatasource.saveSession(
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
        user: user,
      );
      return AuthRestoreResult(
        user: user,
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
      );
    } catch (_) {
      // Refresh token juga sudah expired → paksa login ulang
      await localDatasource.clearAll();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await localDatasource.clearAll();
  }
}
