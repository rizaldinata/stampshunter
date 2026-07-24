import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:stampshunter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:stampshunter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:stampshunter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stampshunter/features/auth/domain/entities/user.dart';
import 'package:stampshunter/core/errors/exceptions.dart';
import 'package:stampshunter/features/onboarding/presentation/providers/onboarding_provider.dart';

// ── Auth Callback Holder ──────────────────────────────────────────────────────
// Digunakan untuk memutus circular dependency antara AuthInterceptor ↔ authProvider.
// Interceptor (dibuat di dioProvider) tidak bisa langsung akses authProvider
// karena authProvider bergantung pada dioProvider. Callback ini ditetapkan
// oleh authProvider setelah notifier dibuat.

class _AuthCallbackHolder {
  static Future<bool> Function()? onRefreshNeeded;
  static Future<void> Function()? onLogoutRequired;
}

// ── Auth Interceptor ─────────────────────────────────────────────────────────

/// Interceptor Dio yang:
/// 1. Meng-inject header `Authorization: Bearer <token>` ke setiap request.
/// 2. Menangkap 401 → mencoba silent refresh → retry request.
/// 3. Jika refresh gagal → trigger logout callback.
class _AuthInterceptor extends Interceptor {
  final AuthLocalDatasource _local;
  final Dio _dio;

  _AuthInterceptor({required AuthLocalDatasource local, required Dio dio})
      : _local = local,
        _dio = dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _local.getAccessToken();
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // Hanya handle 401, dan hindari infinite loop (jangan retry request refresh itu sendiri)
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      final refreshed = await _AuthCallbackHolder.onRefreshNeeded?.call() ?? false;
      if (refreshed) {
        // Retry request asal dengan token baru
        try {
          final newToken = _local.getAccessToken();
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        } catch (_) {
          // Retry juga gagal — lanjut ke error handler
        }
      } else {
        // Refresh gagal → paksa logout
        _AuthCallbackHolder.onLogoutRequired?.call();
      }
    }
    handler.next(err);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthLocalDatasource(prefs);
});

final dioProvider = Provider<Dio>((ref) {
  final localDatasource = ref.read(authLocalDatasourceProvider);

  final dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // Pasang auth interceptor — inject token & handle 401 silently
  dio.interceptors.add(
    _AuthInterceptor(local: localDatasource, dio: dio),
  );

  return dio;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(dio: ref.read(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    localDatasource: ref.read(authLocalDatasourceProvider),
  );
});

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;

  /// True saat app baru start dan sedang restore session dari storage.
  /// Router menunggu flag ini false sebelum membuat keputusan redirect.
  final bool isInitializing;
  final String? error;

  const AuthState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.isInitializing = false,
    this.error,
  });

  bool get isAuthenticated =>
      user != null && accessToken != null && !isInitializing;

  AuthState copyWith({
    User? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    bool clearUser = false,
    bool clearTokens = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      accessToken: clearTokens ? null : (accessToken ?? this.accessToken),
      refreshToken: clearTokens ? null : (refreshToken ?? this.refreshToken),
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepositoryImpl _repository;
  final AuthLocalDatasource _localDatasource;

  AuthNotifier(this._repository, this._localDatasource)
      : super(const AuthState(isInitializing: true)) {
    _init();
  }

  /// Dipanggil satu kali saat app start.
  /// Mencoba restore session dari SharedPreferences.
  Future<void> _init() async {
    // Cek dulu apakah ada sesi tersimpan tanpa hit network
    if (!_localDatasource.hasSession) {
      state = const AuthState(isInitializing: false);
      return;
    }

    try {
      final result = await _repository.getCurrentUser();
      if (result != null) {
        state = AuthState(
          user: result.user,
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          isInitializing: false,
        );
      } else {
        state = const AuthState(isInitializing: false);
      }
    } catch (_) {
      // Jika ada error tak terduga, clear state tapi jangan paksa logout
      // biarkan user memutuskan
      state = const AuthState(isInitializing: false);
    }
  }

  /// Dipanggil oleh _AuthInterceptor via callback ketika ada 401 di tengah sesi.
  /// Returns true jika refresh berhasil, false jika gagal.
  Future<bool> silentRefresh() async {
    final storedRefreshToken = _localDatasource.getRefreshToken();
    if (storedRefreshToken == null) return false;

    try {
      final newTokens = await _repository.remoteDataSource.refreshToken(
        storedRefreshToken,
      );
      // Update storage dan state dengan token baru
      await _localDatasource.updateAccessToken(newTokens.accessToken);
      await _localDatasource.saveTokens(
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
      );
      state = state.copyWith(
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );
      // Simpan sesi ke storage agar persist setelah restart
      await _localDatasource.saveSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
      );
      state = AuthState(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Terjadi kesalahan. Coba lagi.');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.login(email: email, password: password);
      // Simpan sesi ke storage agar persist setelah restart
      await _localDatasource.saveSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
      );
      state = AuthState(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Terjadi kesalahan. Coba lagi.');
    }
  }

  Future<void> logout() async {
    await _repository.logout(); // clear SharedPreferences
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateUser(User user) {
    // Update state dan sync ke storage
    state = state.copyWith(user: user);
    _localDatasource.saveUser(user);
  }
}

// ── Provider Registration ─────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(authLocalDatasourceProvider),
  );

  // Daftarkan callbacks ke interceptor untuk memutus circular dependency
  _AuthCallbackHolder.onRefreshNeeded = () => notifier.silentRefresh();
  _AuthCallbackHolder.onLogoutRequired = () => notifier.logout();

  return notifier;
});
