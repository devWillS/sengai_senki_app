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
  /// 戻り値は成功可否。UI 側で SnackBar 等に使える。
  Future<bool> loginWithWillIdResult(WillIdAuthResult result) async {
    final session = await ApiService.instance.loginWithWillId(result);
    if (session == null) {
      return false;
    }
    state = session;
    // ログイン直後のバルク同期 (ローカル既存デッキをアップロード + サーバーから取り込み)
    try {
      await DeckSyncService.instance.syncOnLogin();
    } catch (e) {
      debugPrint('syncOnLogin failed: $e');
    }
    return true;
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
}
