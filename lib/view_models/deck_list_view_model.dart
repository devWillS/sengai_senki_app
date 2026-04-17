import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/deck.dart';
import '../repositories/hive_deck_repository.dart';
import '../services/deck_sync_service.dart';

final deckListProvider =
    StateNotifierProvider<DeckListViewModel, AsyncValue<List<Deck>>>(
      (ref) => DeckListViewModel(ref),
    );

final filteredDeckListProvider = Provider<List<Deck>>((ref) {
  final decksAsync = ref.watch(deckListProvider);
  final searchQuery = ref.watch(deckSearchQueryProvider);

  return decksAsync.when(
    data: (decks) {
      if (searchQuery.isEmpty) return decks;

      return decks.where((deck) {
        return deck.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            deck.description.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final deckSearchQueryProvider = StateProvider<String>((ref) => '');

class DeckListViewModel extends StateNotifier<AsyncValue<List<Deck>>> {
  DeckListViewModel(this.ref) : super(const AsyncValue.loading()) {
    loadDecks();
  }

  final Ref ref;
  final _hiveRepository = HiveDeckRepository.instance;
  final _sync = DeckSyncService.instance;

  /// ログイン済みなら、一覧読み込み前にサーバーと同期する。
  /// 失敗してもローカルのデータは表示できるように catch で飲み込む。
  Future<void> loadDecks({bool refreshRemote = true}) async {
    try {
      state = const AsyncValue.loading();

      if (refreshRemote && await _sync.isLoggedIn) {
        try {
          await _sync.refreshFromRemote();
        } catch (_) {
          // オフライン等で失敗してもローカルデータで続行
        }
      }

      // Hiveから保存されたデッキを読み込み
      final userDecks = await _hiveRepository.getAllDecks();

      // 両方のデッキリストを結合
      final allDecks = [...userDecks.reversed];

      state = AsyncValue.data(allDecks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDeck(Deck deck) async {
    try {
      final model = _hiveRepository.convertFromDeck(deck);
      await _sync.saveDeck(model);
      await loadDecks(refreshRemote: false);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateDeck(int key, Deck deck) async {
    try {
      // 既存の Hive エントリを取得して、serverId などのサーバー同期情報を維持する
      final existing = await _hiveRepository.getDeck(key);
      final model = _hiveRepository.convertFromDeck(deck);
      if (existing != null) {
        model.serverId = existing.serverId;
        model.createdAt = existing.createdAt;
      }
      // 既存キーに対する put で上書き
      await _hiveRepository.updateDeck(key, model);
      // サーバー同期 (ログイン時のみ)
      if (await _sync.isLoggedIn) {
        await _sync.saveDeck(model);
      }
      await loadDecks(refreshRemote: false);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      if (deckId.startsWith('user_')) {
        final key = int.parse(deckId.replaceFirst('user_', ''));
        final existing = await _hiveRepository.getDeck(key);
        if (existing != null) {
          await _sync.deleteDeck(existing);
        } else {
          await _hiveRepository.deleteDeck(key);
        }
        await loadDecks(refreshRemote: false);
      } else {
        // プリセットデッキは削除できない
        throw Exception('プリセットデッキは削除できません');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Deck?> getDeck(String deckId) async {
    final decks = state.value;
    if (decks == null) return null;

    try {
      return decks.firstWhere((deck) => deck.id == deckId);
    } catch (e) {
      return null;
    }
  }

  void setSearchQuery(String query) {
    ref.read(deckSearchQueryProvider.notifier).state = query;
  }
}
