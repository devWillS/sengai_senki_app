import 'package:hive_flutter/hive_flutter.dart';

part 'deck_sort_type.g.dart';

@HiveType(typeId: 1)
enum DeckSortType {
  @HiveField(0)
  cardNumAsc,
  @HiveField(1)
  cardNumDesc,
  @HiveField(2)
  cardIdAsc,
  @HiveField(3)
  cardIdDesc,
  @HiveField(4)
  costAsc,
  @HiveField(5)
  costDesc,
  @HiveField(6)
  apAsc,
  @HiveField(7)
  apDesc,
  @HiveField(8)
  hpAsc,
  @HiveField(9)
  hpDesc;

  String get title {
    switch (this) {
      case DeckSortType.cardNumAsc:
        return "カード番号 昇順";
      case DeckSortType.cardNumDesc:
        return "カード番号 降順";
      case DeckSortType.cardIdAsc:
        return "カードID 昇順";
      case DeckSortType.cardIdDesc:
        return "カードID 降順";
      case DeckSortType.costAsc:
        return "コスト 昇順";
      case DeckSortType.costDesc:
        return "コスト 降順";
      case DeckSortType.apAsc:
        return "AP 昇順";
      case DeckSortType.apDesc:
        return "AP 降順";
      case DeckSortType.hpAsc:
        return "HP 昇順";
      case DeckSortType.hpDesc:
        return "HP 降順";
    }
  }
}

extension DeckSortTypeExtension on DeckSortType {
  static DeckSortType fromString(String value) {
    return DeckSortType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeckSortType.costDesc,
    );
  }
}