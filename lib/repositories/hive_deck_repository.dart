import '../models/deck.dart';
import '../models/deck_model.dart';
import '../models/deck_sort_type.dart';
import '../models/deck_type.dart';
import 'base_repository.dart';

class HiveDeckRepository extends BaseRepository<DeckModel> {
  HiveDeckRepository() : super('deck');

  static final HiveDeckRepository instance = HiveDeckRepository();

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