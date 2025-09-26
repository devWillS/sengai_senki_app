import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/deck.dart';

class DeckRepository {
  DeckRepository._();

  static final DeckRepository instance = DeckRepository._();

  List<Deck>? _cache;

  Future<List<Deck>> loadDecks({bool forceReload = false}) async {
    if (_cache != null && !forceReload) {
      return _cloneDecks(_cache!);
    }

    final rawJson = await rootBundle.loadString('assets/json/decks.json');
    final List<dynamic> decoded = json.decode(rawJson) as List<dynamic>;
    _cache = decoded
        .whereType<Map<String, dynamic>>()
        .map(Deck.fromJson)
        .toList();
    return _cloneDecks(_cache!);
  }

  Future<void> saveDeck(Deck deck) async {
    final decks = _cache ?? await loadDecks();
    final index = decks.indexWhere((element) => element.id == deck.id);
    if (index >= 0) {
      decks[index] = deck;
    } else {
      decks.add(deck);
    }
    _cache = decks;
  }

  Future<void> deleteDeck(String deckId) async {
    if (_cache == null) {
      await loadDecks();
    }
    _cache?.removeWhere((deck) => deck.id == deckId);
  }

  List<Deck> _cloneDecks(List<Deck> source) {
    return source
        .map(
          (deck) => deck.copyWith(
            mainDeck: [
              for (final entry in deck.mainDeck) entry.copyWith(),
            ],
            magicDeck: [
              for (final entry in deck.magicDeck) entry.copyWith(),
            ],
          ),
        )
        .toList();
  }
}
