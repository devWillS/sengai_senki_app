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
  DeckDetailViewModel(this.ref, Deck? initialDeck)
    : _initialDeck = initialDeck {
    nameController = TextEditingController(text: initialDeck?.name);
    descriptionController = TextEditingController(
      text: initialDeck?.description ?? '',
    );
  }

  Deck? _initialDeck;
  Deck? _currentDeck;

  Deck? get deck {
    // 保存済みのデッキがある場合はそれを返す
    if (_currentDeck != null) return _currentDeck;
    if (_initialDeck != null) return _initialDeck;

    // 新規作成の場合は現在の編集状態からDeckを生成
    final mainCards = ref.read(mainDeckCardsProvider);
    final magicCards = ref.read(magicDeckCardsProvider);

    if (mainCards.isEmpty && magicCards.isEmpty) return null;

    final mainCounts = <String, int>{};
    for (final card in mainCards) {
      mainCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
    }

    final magicCounts = <String, int>{};
    for (final card in magicCards) {
      magicCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
    }

    return Deck(
      id: '',
      name: nameController.text.trim().isEmpty
          ? '新しいデッキ'
          : nameController.text.trim(),
      description: descriptionController.text.trim(),
      mainDeck: mainCounts.entries
          .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
          .toList(),
      magicDeck: magicCounts.entries
          .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
          .toList(),
      updatedAt: DateTime.now(),
    );
  }

  final WidgetRef ref;
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  final _repository = HiveDeckRepository.instance;
  final CardRepository cardRepository = const CardRepository();

  final List<CardData> masterCardList = Master().cardList;

  DeckType deckType = DeckType.normal;
  DeckSortType sortType = DeckSortType.costDesc;
  bool groupByColor = false;

  bool get isSavedInDatabase =>
      _initialDeck != null && _initialDeck!.id.startsWith('user_');

  void initFromDeck(Deck? deck) {
    if (deck == null) {
      // 新規作成の場合は状態をクリア
      ref.read(mainDeckCardsProvider.notifier).state = [];
      ref.read(magicDeckCardsProvider.notifier).state = [];
      return;
    }
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
      // コストの降順→IDの昇順でソート
      currentCards.sort((a, b) {
        final costCompare = (b.cost ?? 0).compareTo(a.cost ?? 0);
        if (costCompare != 0) return costCompare;
        return a.id.compareTo(b.id);
      });
      ref.read(mainDeckCardsProvider.notifier).state = currentCards;
    } else {
      final currentCards = [...ref.read(magicDeckCardsProvider)];
      currentCards.add(card);
      // コストの降順→IDの昇順でソート
      currentCards.sort((a, b) {
        final costCompare = (b.cost ?? 0).compareTo(a.cost ?? 0);
        if (costCompare != 0) return costCompare;
        return a.id.compareTo(b.id);
      });
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

      final mainCounts = <String, int>{};
      for (final card in ref.read(mainDeckCardsProvider)) {
        mainCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
      }

      final magicCounts = <String, int>{};
      for (final card in ref.read(magicDeckCardsProvider)) {
        magicCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
      }

      final newDeck = Deck(
        id:
            _initialDeck?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
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
        _currentDeck = newDeck;
      } else {
        final model = _repository.convertFromDeck(newDeck);
        final savedKey = await _repository.addDeck(model);
        // Update the deck with the new ID from database
        final savedDeck = newDeck.copyWith(id: 'user_$savedKey');
        _currentDeck = savedDeck;
        // Update _initialDeck so that isSavedInDatabase returns true
        _initialDeck = savedDeck;
      }

      return true;
    } catch (e) {
      debugPrint('デッキ保存エラー: $e');
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

  Future<bool> deleteDeck() async {
    try {
      if (_initialDeck != null && _initialDeck!.id.startsWith('user_')) {
        final key = int.parse(_initialDeck!.id.replaceFirst('user_', ''));
        await _repository.deleteDeck(key);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('デッキ削除エラー: $e');
      return false;
    }
  }

  Future<Deck?> copyDeck() async {
    try {
      final mainCounts = <String, int>{};
      for (final card in ref.read(mainDeckCardsProvider)) {
        mainCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
      }

      final magicCounts = <String, int>{};
      for (final card in ref.read(magicDeckCardsProvider)) {
        magicCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
      }

      final copiedDeck = Deck(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        mainDeck: mainCounts.entries
            .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
            .toList(),
        magicDeck: magicCounts.entries
            .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
            .toList(),
        updatedAt: DateTime.now(),
      );

      final model = _repository.convertFromDeck(copiedDeck);
      final savedKey = await _repository.addDeck(model);

      // Return the deck with the database ID
      return copiedDeck.copyWith(id: 'user_$savedKey');
    } catch (e) {
      debugPrint('デッキコピーエラー: $e');
      return null;
    }
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
  }
}
