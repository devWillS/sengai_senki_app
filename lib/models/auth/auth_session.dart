import 'auth_user.dart';

/// tcg_verse backend から取得した Sanctum Bearer トークンとユーザー情報の組。
/// SharedPreferences に JSON でシリアライズして保存する。
class AuthSession {
  const AuthSession({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  final String tokenType;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userPayload = json['user'];
    final userMap = switch (userPayload) {
      Map<String, dynamic> map => map,
      Map map => Map<String, dynamic>.from(map),
      _ => <String, dynamic>{},
    };
    return AuthSession(
      token: json['token'] as String? ?? '',
      tokenType: (json['token_type'] as String?) ?? 'Bearer',
      user: AuthUser.fromJson(userMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }

  /// Authorization ヘッダに渡す文字列。例: "Bearer abc123..."
  String get authHeader => '$tokenType $token';
}
