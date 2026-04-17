/// tcg_verse backend が返す `user` オブジェクトの最小表現。
///
/// senkai_sengi アプリでは `id` と `name` / `identifier` くらいしか使わないが、
/// backend から返ってくる追加フィールドをそのまま保持しておくため構造は
/// tcg_verse 側に合わせている。
class AuthUser {
  const AuthUser({
    this.id,
    this.name,
    this.email,
    this.identifier,
    this.emailVerified,
    this.willIdLinked,
  });

  final int? id;
  final String? name;
  final String? email;
  final String? identifier;
  final bool? emailVerified;
  final bool? willIdLinked;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      identifier: json['identifier'] as String?,
      emailVerified: json['email_verified'] as bool?,
      willIdLinked: json['will_id_linked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'identifier': identifier,
      'email_verified': emailVerified,
      'will_id_linked': willIdLinked,
    };
  }

  /// 表示用の識別名。name > identifier > email の優先度で返す。
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (identifier != null && identifier!.isNotEmpty) return identifier!;
    if (email != null && email!.isNotEmpty) return email!;
    return 'ユーザー';
  }
}
