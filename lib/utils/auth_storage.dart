import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth/auth_session.dart';

/// tcg_verse backend の認証セッション (Bearer トークン + ユーザー情報) を
/// SharedPreferences に永続化するヘルパ。tcg_verse 側の SharedPreferenceManager
/// の簡易版で、トークン単独保存 + ログアウト時クリアに特化している。
class AuthStorage {
  AuthStorage._();
  static final AuthStorage instance = AuthStorage._();

  static const _tokenKey = 'auth_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _userKey = 'auth_user';

  /// アプリ起動時の同期 API 用に SharedPreferences インスタンスをキャッシュする。
  SharedPreferences? _cached;

  Future<SharedPreferences> _prefs() async {
    return _cached ??= await SharedPreferences.getInstance();
  }

  Future<void> save(AuthSession? session) async {
    final prefs = await _prefs();
    if (session == null) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenTypeKey);
      await prefs.remove(_userKey);
      return;
    }
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_tokenTypeKey, session.tokenType);
    await prefs.setString(_userKey, jsonEncode(session.user.toJson()));
  }

  Future<AuthSession?> read() async {
    final prefs = await _prefs();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    final tokenType = prefs.getString(_tokenTypeKey) ?? 'Bearer';
    final userJson = prefs.getString(_userKey);
    Map<String, dynamic> userMap = {};
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson);
        if (decoded is Map) {
          userMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        userMap = {};
      }
    }
    return AuthSession.fromJson({
      'token': token,
      'token_type': tokenType,
      'user': userMap,
    });
  }

  Future<void> clear() => save(null);
}
