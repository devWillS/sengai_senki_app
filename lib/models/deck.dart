import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:senkai_sengi/utils/master.dart';

import 'card_data.dart';

@immutable
class Deck {
  const Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.mainDeck,
    required this.magicDeck,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final List<DeckCardEntry> mainDeck;
  final List<DeckCardEntry> magicDeck;
  final DateTime? updatedAt;

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    List<DeckCardEntry>? mainDeck,
    List<DeckCardEntry>? magicDeck,
    DateTime? updatedAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mainDeck: mainDeck ?? this.mainDeck,
      magicDeck: magicDeck ?? this.magicDeck,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get totalMainCards =>
      mainDeck.fold<int>(0, (sum, entry) => sum + entry.count);
  int get totalMagicCards =>
      magicDeck.fold<int>(0, (sum, entry) => sum + entry.count);
  int get totalCards => totalMainCards + totalMagicCards;

  Map<String, int> colorDistribution(Map<String, CardData> cardLookup) {
    final result = <String, int>{};
    for (final entry in mainDeck) {
      final card = cardLookup[entry.cardId];
      if (card == null) continue;
      result.update(
        card.color,
        (value) => value + entry.count,
        ifAbsent: () => entry.count,
      );
    }
    return result;
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    final mainJson = json['main_deck'] as List<dynamic>? ?? [];
    final magicJson = json['magic_deck'] as List<dynamic>? ?? [];
    return Deck(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?)?.trim() ?? '',
      mainDeck: mainJson
          .map((e) => DeckCardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      magicDeck: magicJson
          .map((e) => DeckCardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'updated_at': updatedAt?.toIso8601String(),
      'main_deck': mainDeck.map((e) => e.toJson()).toList(),
      'magic_deck': magicDeck.map((e) => e.toJson()).toList(),
    };
  }

  int typeCount(String type) {
    int result = 0;
    final masterCardList = Master().cardList;
    for (final entry in mainDeck) {
      final card = masterCardList.firstWhereOrNull(
        (target) => target.id == entry.cardId,
      );
      if (card != null && card.type == type) {
        result += entry.count;
      }
    }
    for (final entry in magicDeck) {
      final card = masterCardList.firstWhereOrNull(
        (target) => target.id == entry.cardId,
      );
      if (card != null && card.type == type) {
        result += entry.count;
      }
    }
    return result;
  }
}

@immutable
class DeckCardEntry {
  const DeckCardEntry({required this.cardId, required this.count});

  final String cardId;
  final int count;

  DeckCardEntry copyWith({String? cardId, int? count}) {
    return DeckCardEntry(
      cardId: cardId ?? this.cardId,
      count: count ?? this.count,
    );
  }

  factory DeckCardEntry.fromJson(Map<String, dynamic> json) {
    return DeckCardEntry(
      cardId: json['card_id'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'card_id': cardId, 'count': count};
  }
}
