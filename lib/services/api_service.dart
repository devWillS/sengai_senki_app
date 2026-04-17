import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:will_id_sdk/will_id_sdk.dart';

import '../models/auth/auth_session.dart';
import '../utils/auth_storage.dart';

/// tcg_verse backend への HTTP クライアント。
///
/// senkai_sengi 0.3.0 で追加。Will ID ログイン + デッキ同期のため、
/// 以下の API を叩く:
///   - POST /api/auth/willid/callback (BackendAuthClient 経由)
///   - GET  /api/decks?game_slug=senkai-sengi
///   - POST /api/decks
///   - PUT  /api/decks/{id}
///   - DELETE /api/decks/{id}
///
/// tcg_verse の ApiService をシンプル化したもの。senkai デッキの CRUD
/// だけを担当する。
class ApiService {
  ApiService._() : _dio = Dio(BaseOptions(headers: {
          'Accept': 'application/json',
        })) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Bearer トークンを付与 (ログイン済みの場合のみ)
        final session = await AuthStorage.instance.read();
        if (session != null && session.token.isNotEmpty) {
          options.headers['Authorization'] = session.authHeader;
        }
        // tcg_verse backend は X-App-Version でクライアント識別をする
        if (_appVersion != null) {
          options.headers['X-App-Version'] = _appVersion;
        }
        options.headers['X-Platform'] = _detectPlatform();
        options.headers['X-Client'] = 'senkai_sengi';
        handler.next(options);
      },
    ));
  }

  static final ApiService instance = ApiService._();

  /// tcg_verse backend のベース URL。dart-define で注入される。
  /// デフォルトは本番の tcg-verse-app.com。
  static final String _authBaseUrl = _normalize(
    const String.fromEnvironment(
      'authApiBaseUrl',
      defaultValue: 'https://tcg-verse-app.com',
    ),
  );

  /// `https://.../api/` 形式の API エンドポイント接頭辞。
  static String get apiUrl => '$_authBaseUrl/api/';

  final Dio _dio;

  /// `package_info_plus` で取得したアプリバージョンを main から注入する。
  String? _appVersion;

  void setAppVersion(String version) {
    _appVersion = version;
  }

  /// main.dart から呼んで PackageInfo から自動設定するヘルパ。
  static Future<void> initAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    instance.setAppVersion('${info.version}+${info.buildNumber}');
  }

  static String _normalize(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  static String _detectPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'other';
  }

  // --------------------------------------------------------------
  // 認証
  // --------------------------------------------------------------

  /// Will ID WebView で取得した認可コードを使って tcg_verse backend にログインする。
  /// 成功時は AuthSession を返し、失敗時は null を返す。
  Future<AuthSession?> loginWithWillId(WillIdAuthResult result) async {
    final config = WillIdConfig.fromEnvironment();
    final client = BackendAuthClient(
      config: config,
      backendBaseUrl: _authBaseUrl,
      callbackPath: '/api/auth/willid/callback',
    );
    try {
      final appSession = await client.loginWithIdToken(result);
      final json = appSession.raw ??
          {
            'token': appSession.token,
            'token_type': appSession.tokenType,
            if (appSession.user != null) 'user': appSession.user,
          };
      final session = AuthSession.fromJson(Map<String, dynamic>.from(json));
      await AuthStorage.instance.save(session);
      return session;
    } on AuthException catch (e) {
      debugPrint('loginWithWillId failed: $e');
      return null;
    }
  }

  /// サーバー側のログアウト (任意)。クライアント側のトークン削除のみで
  /// 十分な場合は呼ばなくても良い。失敗しても例外は投げない。
  Future<void> logoutServer() async {
    try {
      await _dio.post('${apiUrl}logout');
    } catch (_) {
      // ネットワーク失敗は無視 (ローカルクリアは呼び出し側で実行)
    }
  }

  // --------------------------------------------------------------
  // Deck CRUD (senkai-sengi 専用)
  // --------------------------------------------------------------

  static const String _gameSlug = 'senkai-sengi';

  /// サーバーからこのユーザーの senkai デッキ一覧を取得する。
  /// 未ログインの場合は空配列を返す。
  Future<List<Map<String, dynamic>>> getDecks({int page = 1}) async {
    try {
      final response = await _dio.get(
        '${apiUrl}decks',
        queryParameters: {
          'game_slug': _gameSlug,
          'page': page,
        },
      );
      final data = response.data;
      if (data is Map) {
        final list = data['list'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getDecks failed: $e');
    }
    return [];
  }

  /// デッキを新規作成する。
  /// payload は `{ name, card_num_list, meta? }` 形式。
  /// 成功時はサーバーが生成した `id` (String) を含む Map を返す。
  Future<Map<String, dynamic>?> createDeck({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final body = {...payload, 'game_slug': _gameSlug};
      final response = await _dio.post('${apiUrl}decks', data: body);
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('createDeck failed: $e');
    }
    return null;
  }

  /// 既存デッキを更新する。
  Future<Map<String, dynamic>?> updateDeck({
    required String deckId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final body = {...payload, 'game_slug': _gameSlug};
      final response = await _dio.put('${apiUrl}decks/$deckId', data: body);
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('updateDeck failed: $e');
    }
    return null;
  }

  /// デッキを削除する。200 系で true、それ以外で false。
  Future<bool> deleteDeck({required String deckId}) async {
    try {
      final response = await _dio.delete(
        '${apiUrl}decks/$deckId',
        queryParameters: {'game_slug': _gameSlug},
      );
      final code = response.statusCode ?? 0;
      return code >= 200 && code < 300;
    } catch (e) {
      debugPrint('deleteDeck failed: $e');
      return false;
    }
  }
}
