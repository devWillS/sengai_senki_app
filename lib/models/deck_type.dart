import 'package:hive_flutter/hive_flutter.dart';

part 'deck_type.g.dart';

@HiveType(typeId: 9)
enum DeckType {
  @HiveField(0)
  normal,
  @HiveField(1)
  draft;

  String get text {
    switch (this) {
      case DeckType.normal:
        return "通常";
      case DeckType.draft:
        return "ドラフト";
    }
  }

  int get mainDeckMax {
    switch (this) {
      case DeckType.normal:
        return 20;
      case DeckType.draft:
        return 15;
    }
  }

  int get magicDeckMax {
    switch (this) {
      case DeckType.normal:
        return 10;
      case DeckType.draft:
        return 5;
    }
  }

  int get maxCopiesPerCard {
    switch (this) {
      case DeckType.normal:
        return 2;
      case DeckType.draft:
        return mainDeckMax;
    }
  }
}

extension DeckTypeExtension on DeckType {
  static DeckType fromString(String value) {
    return DeckType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeckType.normal,
    );
  }
}
