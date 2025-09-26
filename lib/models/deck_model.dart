import 'package:hive_flutter/hive_flutter.dart';
import 'deck_sort_type.dart';
import 'deck_type.dart';

part 'deck_model.g.dart';

@HiveType(typeId: 0)
class DeckModel extends HiveObject {
  DeckModel({
    required this.name,
    required this.description,
    required this.mainDeckCards,
    required this.magicDeckCards,
    required this.sortType,
    required this.groupCardColor,
    required this.deckType,
    this.updatedAt,
  });

  @HiveField(0)
  String name;

  @HiveField(1)
  String description;

  @HiveField(2)
  List<String> mainDeckCards;

  @HiveField(3)
  List<String> magicDeckCards;

  @HiveField(4, defaultValue: DeckSortType.costDesc)
  DeckSortType sortType;

  @HiveField(5, defaultValue: false)
  bool groupCardColor;

  @HiveField(6, defaultValue: DeckType.normal)
  DeckType deckType;

  @HiveField(7)
  DateTime? updatedAt;

  int get totalMainCards => mainDeckCards.length;
  int get totalMagicCards => magicDeckCards.length;
  int get totalCards => totalMainCards + totalMagicCards;

  bool isValidDeck() {
    return totalMainCards == deckType.mainDeckMax &&
        totalMagicCards == deckType.magicDeckMax;
  }

  Map<String, int> getCardCounts(List<String> cards) {
    final counts = <String, int>{};
    for (final cardId in cards) {
      counts.update(cardId, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  String toString() {
    return '''
    DeckModel{
      name: $name,
      description: $description,
      mainDeckCards: ${mainDeckCards.length} cards,
      magicDeckCards: ${magicDeckCards.length} cards,
      sortType: $sortType,
      groupCardColor: $groupCardColor,
      deckType: $deckType,
      updatedAt: $updatedAt,
    }
    ''';
  }
}