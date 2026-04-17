import 'package:flutter/foundation.dart';

import '../models/auth/auth_session.dart';
import '../models/deck_model.dart';
import '../models/deck_sort_type.dart';
import '../models/deck_type.dart';
import '../repositories/hive_deck_repository.dart';
import '../utils/auth_storage.dart';
import 'api_service.dart';

/// ローカル Hive のデッキと tcg_verse backend のデッキを双方向で橋渡しするサービス。
///
/// ログイン中のみサーバーと通信し、未ログイン時は従来通り Hive のみで完結する。
/// tcg_verse の `SenkaiDeckSyncService` と同等の責務を senkai_sengi 側でも担う。
///
/// **Source of Truth**: ログイン時はサーバー側。ログイン直後に初回同期で
/// サーバー側データを Hive に流し込み、以降はローカルの変更を upload する
/// (サーバー側優先だがマージ戦略は最小限)。
class DeckSyncService {
  DeckSyncService._();
  static final DeckSyncService instance = DeckSyncService._();

  final HiveDeckRepository _repository = HiveDeckRepository.instance;
  final ApiService _api = ApiService.instance;

  Future<bool> get isLoggedIn async {
    final session = await AuthStorage.instance.read();
    return session != null && session.token.isNotEmpty;
  }

  Future<AuthSession?> currentSession() async {
    return AuthStorage.instance.read();
  }

  /// ログイン直後に呼ぶ、全件同期処理。
  ///
  /// フロー:
  ///   1. サーバーのデッキ一覧を先に取得
  ///   2. ローカルの「未同期」デッキ (serverId 無し) を push する際、
  ///      サーバー側に同一内容 (name + mainDeckCards + magicDeckCards 一致)
  ///      の deck が既にある場合は **新規 POST せず、serverId を紐付けるだけ** にして重複を防ぐ
  ///   3. サーバー側データで Hive を再構築
  ///
  /// ログアウト→再ログインのたびにサーバー側に重複デッキが増えていくバグ対策。
  Future<void> syncOnLogin() async {
    if (!await isLoggedIn) return;

    // 1. まずサーバー側の状態を取得
    final remoteList = await _api.getDecks();
    final remoteByFingerprint = <String, Map<String, dynamic>>{};
    for (final r in remoteList) {
      final fp = _fingerprintRemote(r);
      // 同じ指紋が複数あれば最初の 1 件を採用 (以後は重複として扱う)
      remoteByFingerprint.putIfAbsent(fp, () => r);
    }

    // 2. 未同期ローカルデッキを push または紐付け
    final localDecks = await _repository.getList();
    for (final deck in localDecks.where((d) => d.serverId == null)) {
      final fp = _fingerprintLocal(deck);
      final remoteMatch = remoteByFingerprint[fp];
      if (remoteMatch != null) {
        // サーバー側に既に同内容のデッキあり → POST せず serverId だけ付与
        final id = remoteMatch['id']?.toString();
        if (id != null) {
          deck.serverId = id;
          deck.createdAt =
              _parseDate(remoteMatch['created_at']) ?? deck.createdAt;
          deck.updatedAt =
              _parseDate(remoteMatch['updated_at']) ?? deck.updatedAt;
          if (deck.isInBox) {
            await deck.save();
          }
        }
        continue;
      }

      // 新規デッキ → サーバーに POST
      final remote = await _uploadDeck(deck);
      if (remote != null) {
        deck.serverId = remote['id']?.toString();
        deck.createdAt = _parseDate(remote['created_at']) ?? deck.createdAt;
        deck.updatedAt = _parseDate(remote['updated_at']) ?? deck.updatedAt;
        if (deck.isInBox) {
          await deck.save();
        }
      }
    }

    // 3. サーバー側データで Hive を置き換え (既に取得済みの remoteList を再利用)
    await _applyRemote(remoteList);
  }

  /// デッキの「同一性」を判定するためのフィンガープリント。
  /// name + 正規化された main / magic カードリストから生成する。
  String _fingerprintLocal(DeckModel deck) {
    return _fingerprint(
      name: deck.name,
      main: deck.mainDeckCards,
      magic: deck.magicDeckCards,
    );
  }

  String _fingerprintRemote(Map<String, dynamic> remote) {
    final deckJson = remote['deck'] is Map
        ? Map<String, dynamic>.from(remote['deck'] as Map)
        : remote;
    final name = (deckJson['name'] as String?) ?? '';
    final rawCards = deckJson['cards'] ?? deckJson['card_num_list'];
    final main = rawCards is List ? rawCards.map((e) => e.toString()).toList() : <String>[];
    final meta = deckJson['meta'] ?? remote['meta'];
    final rawMagic = meta is Map ? meta['magic_deck'] : null;
    final magic = rawMagic is List
        ? rawMagic.map((e) => e.toString()).toList()
        : <String>[];
    return _fingerprint(name: name, main: main, magic: magic);
  }

  String _fingerprint({
    required String name,
    required List<String> main,
    required List<String> magic,
  }) {
    final m = [...main]..sort();
    final g = [...magic]..sort();
    return [name, m.join(','), g.join(',')].join('|');
  }

  /// サーバー側のデッキ一覧で Hive を置き換える。
  /// ログアウト時やプル同期で使う。未ログイン時は何もしない。
  Future<void> refreshFromRemote() async {
    if (!await isLoggedIn) return;
    final remoteList = await _api.getDecks();
    await _applyRemote(remoteList);
  }

  /// `remoteList` を Hive に適用する。syncOnLogin / refreshFromRemote 共通処理。
  Future<void> _applyRemote(List<Map<String, dynamic>> remoteList) async {
    if (remoteList.isEmpty) {
      // サーバー側にデッキが無い場合、Hive を空にしてしまうと
      // ローカル専用デッキ (serverId==null) を誤削除するリスクがあるため、
      // serverId 付きのもののみ消してローカル専用を温存する。
      final local = await _repository.getList();
      for (final d in local) {
        if (d.serverId != null) {
          await d.delete();
        }
      }
      return;
    }

    // サーバー側にある serverId セット
    final remoteIds = <String>{};
    for (final item in remoteList) {
      final id = item['id']?.toString();
      if (id != null) remoteIds.add(id);
    }

    // ローカルから「サーバーから消えたもの」を削除 (serverId 付きのみ対象)
    final local = await _repository.getList();
    for (final d in local) {
      final sid = d.serverId;
      if (sid != null && !remoteIds.contains(sid)) {
        await d.delete();
      }
    }

    // サーバー側データで upsert
    for (final item in remoteList) {
      await _upsertFromRemote(item);
    }
  }

  /// 新規作成 / 既存更新どちらもこのメソッドで扱う。
  /// ログイン時はサーバーを優先 (POST or PUT)、未ログイン時は Hive のみ。
  /// 成功したら渡された deck が更新された状態で返る (serverId 付与等)。
  Future<bool> saveDeck(DeckModel deck) async {
    deck.updatedAt = DateTime.now();
    deck.createdAt ??= deck.updatedAt;

    if (await isLoggedIn) {
      final remote = await _uploadDeck(deck);
      if (remote == null) return false;
      deck.serverId = remote['id']?.toString() ?? deck.serverId;
      deck.createdAt = _parseDate(remote['created_at']) ?? deck.createdAt;
      deck.updatedAt = _parseDate(remote['updated_at']) ?? deck.updatedAt;
    }

    if (deck.isInBox) {
      await deck.save();
    } else {
      await _repository.addDeck(deck);
    }
    return true;
  }

  /// 削除。ログイン中はサーバー側も消す。
  Future<bool> deleteDeck(DeckModel deck) async {
    if (await isLoggedIn && deck.serverId != null) {
      final ok = await _api.deleteDeck(deckId: deck.serverId!);
      if (!ok) return false;
    }
    final key = deck.key;
    if (key is int) {
      await _repository.deleteDeck(key);
    } else if (deck.isInBox) {
      await deck.delete();
    }
    return true;
  }

  // --------------------------------------------------------------
  // private helpers
  // --------------------------------------------------------------

  Future<Map<String, dynamic>?> _uploadDeck(DeckModel deck) async {
    final payload = _toPayload(deck);
    if (deck.serverId != null) {
      return _api.updateDeck(deckId: deck.serverId!, payload: payload);
    } else {
      return _api.createDeck(payload: payload);
    }
  }

  Map<String, dynamic> _toPayload(DeckModel deck) {
    // tcg_verse backend の DeckController::prepareDeckData / DeckModelServer に合わせる。
    // - name: デッキ名
    // - cards: メインデッキ (List<String>)  ※ フィールド名は `cards` (card_num_list ではない)
    // - meta.magic_deck: マジックデッキ (tcg_verse 側と同じ運用)
    return {
      'name': deck.name,
      'description': deck.description,
      'cards': deck.mainDeckCards,
      'meta': {
        'magic_deck': deck.magicDeckCards,
      },
    };
  }

  Future<void> _upsertFromRemote(Map<String, dynamic> remote) async {
    final id = remote['id']?.toString();
    if (id == null) return;

    final local = await _repository.getList();
    final existing = local.where((d) => d.serverId == id).firstOrNull;

    // Laravel Deck モデルは flat な JSON を返す (`{id, name, cards, meta, ...}`)。
    // 念のため `deck` キーネスト形式にもフォールバック対応。
    final deckJson = remote['deck'] is Map
        ? Map<String, dynamic>.from(remote['deck'] as Map)
        : remote;

    final name = (deckJson['name'] as String?) ?? '';
    List<String> mainCards = [];
    final rawCards = deckJson['cards'] ?? deckJson['card_num_list'];
    if (rawCards is List) {
      mainCards = rawCards.map((e) => e.toString()).toList();
    }

    List<String> magicCards = [];
    final meta = deckJson['meta'] ?? remote['meta'];
    if (meta is Map) {
      final magic = meta['magic_deck'];
      if (magic is List) {
        magicCards = magic.map((e) => e.toString()).toList();
      }
    }

    final createdAt = _parseDate(remote['created_at']);
    final updatedAt = _parseDate(remote['updated_at']);

    if (existing != null) {
      existing.name = name;
      existing.mainDeckCards = mainCards;
      existing.magicDeckCards = magicCards;
      existing.updatedAt = updatedAt ?? existing.updatedAt;
      existing.createdAt = createdAt ?? existing.createdAt;
      await existing.save();
    } else {
      final model = DeckModel(
        name: name,
        description: '',
        mainDeckCards: mainCards,
        magicDeckCards: magicCards,
        sortType: DeckSortType.costDesc,
        groupCardColor: false,
        deckType: DeckType.normal,
        updatedAt: updatedAt ?? DateTime.now(),
        createdAt: createdAt,
        serverId: id,
      );
      await _repository.addDeck(model);
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    try {
      return first;
    } on StateError {
      // `first` は empty のとき StateError を投げる
      return null;
    } catch (_) {
      debugPrint('firstOrNull: unexpected error');
      return null;
    }
  }
}
