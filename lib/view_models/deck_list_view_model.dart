import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/deck.dart';
import '../repositories/deck_repository.dart';
import '../repositories/hive_deck_repository.dart';

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
  final _presetRepository = DeckRepository.instance;

  Future<void> loadDecks() async {
    try {
      state = const AsyncValue.loading();

      // Hiveから保存されたデッキを読み込み
      final userDecks = await _hiveRepository.getAllDecks();

      // プリセットデッキを読み込み
      final presetDecks = await _presetRepository.loadDecks();

      // 両方のデッキリストを結合
      final allDecks = [...userDecks, ...presetDecks];

      state = AsyncValue.data(allDecks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDeck(Deck deck) async {
    try {
      final model = _hiveRepository.convertFromDeck(deck);
      await _hiveRepository.addDeck(model);
      await loadDecks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateDeck(int key, Deck deck) async {
    try {
      final model = _hiveRepository.convertFromDeck(deck);
      await _hiveRepository.updateDeck(key, model);
      await loadDecks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      if (deckId.startsWith('user_')) {
        final key = int.parse(deckId.replaceFirst('user_', ''));
        await _hiveRepository.deleteDeck(key);
        await loadDecks();
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
