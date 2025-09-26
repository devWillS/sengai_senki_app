import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:senkai_sengi/repositories/card_repository.dart';
import 'package:senkai_sengi/utils/master.dart';

import '../models/card_data.dart';
import '../models/deck.dart';
import '../models/deck_sort_type.dart';
import '../models/deck_type.dart';
import '../repositories/hive_deck_repository.dart';

// Providers for deck cards
final mainDeckCardsProvider = StateProvider<List<CardData>>((ref) => []);
final magicDeckCardsProvider = StateProvider<List<CardData>>((ref) => []);

class DeckDetailViewModel {
  DeckDetailViewModel(this.ref, Deck? initialDeck) : _initialDeck = initialDeck {
    nameController = TextEditingController(text: initialDeck?.name ?? '新しいデッキ');
    descriptionController = TextEditingController(
      text: initialDeck?.description ?? '',
    );
  }

  final Deck? _initialDeck;
  Deck? _currentDeck;
  Deck? get deck => _currentDeck ?? _initialDeck;
  final WidgetRef ref;
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  final _repository = HiveDeckRepository.instance;
  final CardRepository cardRepository = const CardRepository();

  final List<CardData> masterCardList = Master().cardList;

  DeckType deckType = DeckType.normal;
  DeckSortType sortType = DeckSortType.costDesc;
  bool groupByColor = false;

  void initFromDeck(Deck deck) {
    final mainCards = <CardData>[];
    final magicCards = <CardData>[];

    for (final entry in deck.mainDeck) {
      for (int i = 0; i < entry.count; i++) {
        final card = masterCardList.firstWhereOrNull(
          (c) => c.id == entry.cardId,
        );
        if (card == null) {
          continue;
        }
        mainCards.add(card);
      }
    }

    for (final entry in deck.magicDeck) {
      for (int i = 0; i < entry.count; i++) {
        final card = masterCardList.firstWhereOrNull(
          (c) => c.id == entry.cardId,
        );
        if (card == null) {
          continue;
        }
        magicCards.add(card);
      }
    }

    ref.read(mainDeckCardsProvider.notifier).state = mainCards;
    ref.read(magicDeckCardsProvider.notifier).state = magicCards;
  }

  bool canAddCard(CardData card) {
    final isMainDeck = card.type != "魔力";
    final targetIdList = ref.read(
      isMainDeck ? mainDeckCardsProvider : magicDeckCardsProvider,
    );
    final maxCards = isMainDeck ? deckType.mainDeckMax : deckType.magicDeckMax;

    if (targetIdList.length >= maxCards) {
      return false;
    }

    final targetList = <CardData>[];
    for (var target in targetIdList) {
      final card = masterCardList.firstWhereOrNull((c) => c.id == target.id);
      if (card != null) {
        targetList.add(card);
      }
    }

    if (isMainDeck) {
      final currentCount = targetList
          .where((target) => target.name == card.name)
          .length;
      return currentCount < deckType.maxCopiesPerCard;
    }
    // 《覚醒魔力》の判定
    if (card.feature?.contains("《覚醒魔力》") != true) {
      return true;
    }
    final awakeningMagicPowerCount = targetList
        .where((target) => target.feature?.contains("《覚醒魔力》") ?? false)
        .length;
    return awakeningMagicPowerCount < 2;
  }

  void addCard(CardData card) {
    if (!canAddCard(card)) return;

    if (card.type != "魔力") {
      final currentCards = [...ref.read(mainDeckCardsProvider)];
      currentCards.add(card);
      ref.read(mainDeckCardsProvider.notifier).state = currentCards;
    } else {
      final currentCards = [...ref.read(magicDeckCardsProvider)];
      currentCards.add(card);
      ref.read(magicDeckCardsProvider.notifier).state = currentCards;
    }
  }

  void removeCard(int index, bool isMainDeck) {
    if (isMainDeck) {
      final currentCards = [...ref.read(mainDeckCardsProvider)];
      if (index < currentCards.length) {
        currentCards.removeAt(index);
        ref.read(mainDeckCardsProvider.notifier).state = currentCards;
      }
    } else {
      final currentCards = [...ref.read(magicDeckCardsProvider)];
      if (index < currentCards.length) {
        currentCards.removeAt(index);
        ref.read(magicDeckCardsProvider.notifier).state = currentCards;
      }
    }
  }

  List<CardData> getSortedCards(
    List<String> cardIds,
    Map<String, CardData> cardLookup,
  ) {
    final cards = cardIds
        .map((id) => cardLookup[id])
        .where((card) => card != null)
        .cast<CardData>()
        .toList();

    if (groupByColor) {
      cards.sort((a, b) {
        final colorCompare = a.color.compareTo(b.color);
        if (colorCompare != 0) return colorCompare;
        return _compareCards(a, b, sortType);
      });
    } else {
      cards.sort((a, b) => _compareCards(a, b, sortType));
    }

    return cards;
  }

  int _compareCards(CardData a, CardData b, DeckSortType sortType) {
    switch (sortType) {
      case DeckSortType.cardNumAsc:
        return a.id.compareTo(b.id);
      case DeckSortType.cardNumDesc:
        return b.id.compareTo(a.id);
      case DeckSortType.cardIdAsc:
        return a.id.compareTo(b.id);
      case DeckSortType.cardIdDesc:
        return b.id.compareTo(a.id);
      case DeckSortType.costAsc:
        return (a.cost ?? 0).compareTo(b.cost ?? 0);
      case DeckSortType.costDesc:
        return (b.cost ?? 0).compareTo(a.cost ?? 0);
      case DeckSortType.apAsc:
        return (a.ap ?? 0).compareTo(b.ap ?? 0);
      case DeckSortType.apDesc:
        return (b.ap ?? 0).compareTo(a.ap ?? 0);
      case DeckSortType.hpAsc:
        return (a.hp ?? 0).compareTo(b.hp ?? 0);
      case DeckSortType.hpDesc:
        return (b.hp ?? 0).compareTo(a.hp ?? 0);
    }
  }

  Future<bool> saveDeck() async {
    try {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        throw Exception('デッキ名を入力してください');
      }

      final mainCounts = <String, int>{};
      for (final card in ref.read(mainDeckCardsProvider)) {
        mainCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
      }

      final magicCounts = <String, int>{};
      for (final card in ref.read(magicDeckCardsProvider)) {
        magicCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
      }

      final newDeck = Deck(
        id: _initialDeck?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: descriptionController.text.trim(),
        mainDeck: mainCounts.entries
            .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
            .toList(),
        magicDeck: magicCounts.entries
            .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
            .toList(),
        updatedAt: DateTime.now(),
      );

      if (_initialDeck != null && _initialDeck!.id.startsWith('user_')) {
        final key = int.parse(_initialDeck!.id.replaceFirst('user_', ''));
        final model = _repository.convertFromDeck(newDeck);
        await _repository.updateDeck(key, model);
      } else {
        final model = _repository.convertFromDeck(newDeck);
        final savedKey = await _repository.addDeck(model);
        // Update the deck with the new ID from database
        _currentDeck = newDeck.copyWith(
          id: 'user_$savedKey',
        );
      }

      // Update current deck for existing decks too
      if (_currentDeck == null) {
        _currentDeck = newDeck;
      }

      return true;
    } catch (e) {
      print('デッキ保存エラー: $e');
      return false;
    }
  }

  bool hasChanges() {
    if (_initialDeck == null) {
      return ref.read(mainDeckCardsProvider).isNotEmpty ||
          ref.read(magicDeckCardsProvider).isNotEmpty ||
          nameController.text != '新しいデッキ' ||
          descriptionController.text.isNotEmpty;
    }

    if (nameController.text != _initialDeck!.name ||
        descriptionController.text != _initialDeck!.description) {
      return true;
    }

    final currentMainCount = <String, int>{};
    for (final card in ref.read(mainDeckCardsProvider)) {
      currentMainCount.update(card.id, (value) => value + 1, ifAbsent: () => 1);
    }

    final originalMainCount = <String, int>{};
    for (final entry in _initialDeck!.mainDeck) {
      originalMainCount[entry.cardId] = entry.count;
    }

    if (currentMainCount.length != originalMainCount.length) return true;

    for (final entry in currentMainCount.entries) {
      if (originalMainCount[entry.key] != entry.value) return true;
    }

    final currentMagicCount = <String, int>{};
    for (final card in ref.read(magicDeckCardsProvider)) {
      currentMagicCount.update(
        card.id,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final originalMagicCount = <String, int>{};
    for (final entry in _initialDeck!.magicDeck) {
      originalMagicCount[entry.cardId] = entry.count;
    }

    if (currentMagicCount.length != originalMagicCount.length) return true;

    for (final entry in currentMagicCount.entries) {
      if (originalMagicCount[entry.key] != entry.value) return true;
    }

    return false;
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
  }
}
