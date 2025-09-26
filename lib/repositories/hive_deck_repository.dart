import 'package:shared_preferences/shared_preferences.dart';

import '../models/deck.dart';
import '../models/deck_model.dart';
import '../models/deck_sort_type.dart';
import '../models/deck_type.dart';
import 'base_repository.dart';
import 'deck_repository.dart';

class HiveDeckRepository extends BaseRepository<DeckModel> {
  HiveDeckRepository() : super('deck');

  static final HiveDeckRepository instance = HiveDeckRepository();
  
  static const String _firstLaunchKey = 'first_launch_completed';
  
  /// 初回起動時にプリセットデッキをインポート
  Future<void> importPresetDecksOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunchCompleted = prefs.getBool(_firstLaunchKey) ?? false;
    
    if (!isFirstLaunchCompleted) {
      // プリセットデッキを読み込み
      final presetDecks = await DeckRepository.instance.loadDecks();
      
      // 各プリセットデッキをHiveDBに保存
      for (final deck in presetDecks) {
        final model = convertFromDeck(deck);
        await addDeck(model);
      }
      
      // 初回起動完了フラグを設定
      await prefs.setBool(_firstLaunchKey, true);
    }
  }

  Future<List<DeckModel>> getList() async {
    final box = await super.box();
    final list = box.values.cast<DeckModel>().toList();
    return list;
  }

  Future<int> addDeck(DeckModel model) async {
    model.updatedAt = DateTime.now();
    return await save(model);
  }

  Future<void> updateDeck(int key, DeckModel model) async {
    final box = await super.box();
    model.updatedAt = DateTime.now();
    await box.put(key, model);
  }

  Future<void> deleteDeck(int key) async {
    await delete(key);
  }

  Future<DeckModel?> getDeck(int key) async {
    return await get(key);
  }

  DeckModel convertFromDeck(Deck deck) {
    final mainCards = <String>[];
    for (final entry in deck.mainDeck) {
      for (int i = 0; i < entry.count; i++) {
        mainCards.add(entry.cardId);
      }
    }

    final magicCards = <String>[];
    for (final entry in deck.magicDeck) {
      for (int i = 0; i < entry.count; i++) {
        magicCards.add(entry.cardId);
      }
    }

    return DeckModel(
      name: deck.name,
      description: deck.description,
      mainDeckCards: mainCards,
      magicDeckCards: magicCards,
      sortType: DeckSortType.costDesc,
      groupCardColor: false,
      deckType: DeckType.normal,
      updatedAt: deck.updatedAt,
    );
  }

  Deck convertToDeck(DeckModel model, int key) {
    final mainCounts = model.getCardCounts(model.mainDeckCards);
    final magicCounts = model.getCardCounts(model.magicDeckCards);

    return Deck(
      id: 'user_$key',
      name: model.name,
      description: model.description,
      mainDeck: mainCounts.entries
          .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
          .toList(),
      magicDeck: magicCounts.entries
          .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
          .toList(),
      updatedAt: model.updatedAt,
    );
  }

  Future<List<Deck>> getAllDecks() async {
    final models = await getList();
    final keys = await this.keys();
    
    final decks = <Deck>[];
    for (int i = 0; i < models.length; i++) {
      decks.add(convertToDeck(models[i], keys[i] as int));
    }
    
    return decks;
  }
}