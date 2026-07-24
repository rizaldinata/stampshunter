import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampshunter/features/auth/domain/entities/user.dart';

/// Bertanggung jawab atas persistensi credential auth di SharedPreferences.
/// Semua read bersifat sinkron (SharedPreferences sudah eager-init di main.dart).
/// Semua write bersifat async karena harus commit ke disk.
class AuthLocalDatasource {
  final SharedPreferences _prefs;

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUserJson = 'auth_user_json';

  AuthLocalDatasource(this._prefs);

  // ── Read (sinkron) ────────────────────────────────────────────────────────

  String? getAccessToken() => _prefs.getString(_keyAccessToken);

  String? getRefreshToken() => _prefs.getString(_keyRefreshToken);

  User? getUser() {
    final json = _prefs.getString(_keyUserJson);
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  bool get hasSession =>
      _prefs.getString(_keyAccessToken) != null &&
      _prefs.getString(_keyRefreshToken) != null;

  // ── Write (async) ─────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _prefs.setString(_keyAccessToken, accessToken),
      _prefs.setString(_keyRefreshToken, refreshToken),
    ]);
  }

  Future<void> saveUser(User user) async {
    await _prefs.setString(_keyUserJson, jsonEncode(user.toJson()));
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required User user,
  }) async {
    await Future.wait([
      _prefs.setString(_keyAccessToken, accessToken),
      _prefs.setString(_keyRefreshToken, refreshToken),
      _prefs.setString(_keyUserJson, jsonEncode(user.toJson())),
    ]);
  }

  Future<void> updateAccessToken(String newAccessToken) async {
    await _prefs.setString(_keyAccessToken, newAccessToken);
  }

  Future<void> clearAll() async {
    await Future.wait([
      _prefs.remove(_keyAccessToken),
      _prefs.remove(_keyRefreshToken),
      _prefs.remove(_keyUserJson),
    ]);
  }
}
