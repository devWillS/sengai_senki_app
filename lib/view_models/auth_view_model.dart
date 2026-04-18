import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:will_id_sdk/will_id_sdk.dart';

import '../models/auth/auth_session.dart';
import '../services/api_service.dart';
import '../services/deck_sync_service.dart';
import '../utils/auth_storage.dart';

/// 認証状態。UI はこの provider を watch することで現在のログインユーザーを把握する。
final authSessionProvider =
    StateNotifierProvider<AuthViewModel, AuthSession?>((ref) {
  return AuthViewModel();
});

class AuthViewModel extends StateNotifier<AuthSession?> {
  AuthViewModel() : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await AuthStorage.instance.read();
  }

  /// Will ID WebView の結果でログイン。成功時に state を更新し、
  /// tcg_verse 側のデッキと同期する。
  /// 戻り値は結果オブジェクト。失敗時は errorMessage に原因が入る。
  Future<LoginResult> loginWithWillIdResult(WillIdAuthResult result) async {
    try {
      final session = await ApiService.instance.loginWithWillId(result);
      state = session;
    } catch (e) {
      debugPrint('loginWithWillIdResult failed: $e');
      return LoginResult.failure(e.toString());
    }
    // ログイン直後のバルク同期 (ローカル既存デッキをアップロード + サーバーから取り込み)
    try {
      await DeckSyncService.instance.syncOnLogin();
    } catch (e) {
      debugPrint('syncOnLogin failed: $e');
    }
    return LoginResult.success();
  }

  /// サインアウト。サーバー側の /logout は best-effort で呼び、
  /// 失敗してもローカルのトークンは必ず消す。ログアウト後もローカル Hive の
  /// デッキはそのまま残す (ローカル専用デッキとして扱われ続ける)。
  Future<void> logout() async {
    await ApiService.instance.logoutServer();
    await AuthStorage.instance.clear();
    state = null;
  }

  bool get isLoggedIn => state != null && state!.token.isNotEmpty;

  /// コンパイル時に dart-define で `willIdClientId` / `willIdRedirectUri` が
  /// 注入されているかを判定する。tcg_verse 側と同じガード。
  /// これらが空のビルド (例: `flutter run` に --dart-define 指定なし) では
  /// Will ID ログインを無効化し、UI 側で案内を出す。
  static bool get isWillIdAvailable {
    const clientId = String.fromEnvironment('willIdClientId');
    const redirectUri = String.fromEnvironment('willIdRedirectUri');
    return clientId.isNotEmpty && redirectUri.isNotEmpty;
  }
}

/// ログイン結果。UI 側の SnackBar / ダイアログに原因を渡すために使う。
class LoginResult {
  const LoginResult._({required this.success, this.errorMessage});

  final bool success;
  final String? errorMessage;

  factory LoginResult.success() => const LoginResult._(success: true);
  factory LoginResult.failure(String message) =>
      LoginResult._(success: false, errorMessage: message);
}
