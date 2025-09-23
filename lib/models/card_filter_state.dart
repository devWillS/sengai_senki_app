import 'package:collection/collection.dart';

import 'card_data.dart';

class CardFilterState {
  const CardFilterState({
    this.keyword = '',
    this.colors = const {},
    this.rarities = const {},
    this.types = const {},
    this.costs = const {},
  });

  final String keyword;
  final Set<String> colors;
  final Set<String> rarities;
  final Set<String> types;
  final Set<int> costs;

  static const empty = CardFilterState();

  bool get hasFilter =>
      keyword.trim().isNotEmpty ||
      colors.isNotEmpty ||
      rarities.isNotEmpty ||
      types.isNotEmpty ||
      costs.isNotEmpty;

  CardFilterState copyWith({
    String? keyword,
    Set<String>? colors,
    Set<String>? rarities,
    Set<String>? types,
    Set<int>? costs,
  }) {
    return CardFilterState(
      keyword: keyword ?? this.keyword,
      colors: colors ?? this.colors,
      rarities: rarities ?? this.rarities,
      types: types ?? this.types,
      costs: costs ?? this.costs,
    );
  }

  CardFilterState toggleColor(String value) => colors.contains(value)
      ? copyWith(colors: {...colors}..remove(value))
      : copyWith(colors: {...colors, value});

  CardFilterState toggleRarity(String value) => rarities.contains(value)
      ? copyWith(rarities: {...rarities}..remove(value))
      : copyWith(rarities: {...rarities, value});

  CardFilterState toggleType(String value) => types.contains(value)
      ? copyWith(types: {...types}..remove(value))
      : copyWith(types: {...types, value});

  CardFilterState toggleCost(int value) => costs.contains(value)
      ? copyWith(costs: {...costs}..remove(value))
      : copyWith(costs: {...costs, value});

  List<CardData> apply(List<CardData> source) {
    return source.where(matches).toList();
  }

  bool matches(CardData card) {
    final keywordLower = keyword.trim().toLowerCase();
    final matchesKeyword =
        keywordLower.isEmpty ||
        card.name.toLowerCase().contains(keywordLower) ||
        card.id.toLowerCase().contains(keywordLower) ||
        (card.feature?.toLowerCase().contains(keywordLower) ?? false) ||
        (card.attribute?.toLowerCase().contains(keywordLower) ?? false);

    final matchesColor = colors.isEmpty || colors.contains(card.color);
    final matchesRarity = rarities.isEmpty || rarities.contains(card.rarity);
    final matchesType = types.isEmpty || types.contains(card.type);
    final matchesCost =
        costs.isEmpty || (card.cost != null && costs.contains(card.cost));

    return matchesKeyword &&
        matchesColor &&
        matchesRarity &&
        matchesType &&
        matchesCost;
  }

  List<String> toChipLabels() {
    final chips = <String>[];
    if (keyword.trim().isNotEmpty) {
      chips.add('キーワード: $keyword');
    }
    chips.addAll(colors);
    chips.addAll(rarities);
    chips.addAll(types);
    chips.addAll(costs.map((e) => 'Cost $e'));
    return chips;
  }

  @override
  bool operator ==(Object other) {
    return other is CardFilterState &&
        other.keyword == keyword &&
        const SetEquality<String>().equals(other.colors, colors) &&
        const SetEquality<String>().equals(other.rarities, rarities) &&
        const SetEquality<String>().equals(other.types, types) &&
        const SetEquality<int>().equals(other.costs, costs);
  }

  @override
  int get hashCode => Object.hash(
    keyword,
    const SetEquality<String>().hash(colors),
    const SetEquality<String>().hash(rarities),
    const SetEquality<String>().hash(types),
    const SetEquality<int>().hash(costs),
  );
}
