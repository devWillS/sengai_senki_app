import 'package:flutter/material.dart';

import 'card_data.dart';

enum CardSortOption {
  idAscending,
  idDescending,
  nameAscending,
  nameDescending,
  costAscending,
  costDescending,
  apDescending,
  hpDescending,
}

extension CardSortOptionLabel on CardSortOption {
  String get label {
    switch (this) {
      case CardSortOption.idAscending:
        return 'カードID 昇順';
      case CardSortOption.idDescending:
        return 'カードID 降順';
      case CardSortOption.nameAscending:
        return 'カード名 昇順';
      case CardSortOption.nameDescending:
        return 'カード名 降順';
      case CardSortOption.costAscending:
        return 'コスト 昇順';
      case CardSortOption.costDescending:
        return 'コスト 降順';
      case CardSortOption.apDescending:
        return 'AP 降順';
      case CardSortOption.hpDescending:
        return 'HP 降順';
    }
  }

  IconData get icon {
    switch (this) {
      case CardSortOption.idAscending:
        return Icons.sort_by_alpha;
      case CardSortOption.idDescending:
        return Icons.sort_by_alpha;
      case CardSortOption.nameAscending:
        return Icons.sort_by_alpha;
      case CardSortOption.nameDescending:
        return Icons.sort_by_alpha;
      case CardSortOption.costAscending:
        return Icons.trending_up;
      case CardSortOption.costDescending:
        return Icons.trending_down;
      case CardSortOption.apDescending:
        return Icons.flash_on;
      case CardSortOption.hpDescending:
        return Icons.health_and_safety;
    }
  }

  int compare(CardData a, CardData b) {
    switch (this) {
      case CardSortOption.idAscending:
        return _compareCardId(a.id, b.id);
      case CardSortOption.idDescending:
        return _compareCardId(b.id, a.id);
      case CardSortOption.nameAscending:
        return a.name.compareTo(b.name);
      case CardSortOption.nameDescending:
        return b.name.compareTo(a.name);
      case CardSortOption.costAscending:
        return _compareNullableInt(a.cost, b.cost);
      case CardSortOption.costDescending:
        return _compareNullableInt(b.cost, a.cost);
      case CardSortOption.apDescending:
        return _compareNullableInt(b.ap, a.ap);
      case CardSortOption.hpDescending:
        return _compareNullableInt(b.hp, a.hp);
    }
  }

  int _compareNullableInt(int? a, int? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return a.compareTo(b);
  }

  int _compareCardId(String a, String b) {
    return _normalizeCardId(a).compareTo(_normalizeCardId(b));
  }

  String _normalizeCardId(String id) {
    return id.replaceAllMapped(
      RegExp(r'\d+'),
      (match) => match.group(0)!.padLeft(6, '0'),
    );
  }
}
