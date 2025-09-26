import 'package:senkai_sengi/models/card_data.dart';

class Master {
  late List<CardData> cardList;
  late List<String> colorList;
  late List<String> typeList;
  late List<String> rarityList;
  late List<int> costList;
  late List<String> abilityList;

  static final Master _instance = Master._internal();

  factory Master() {
    return _instance;
  }

  Master._internal() {
    cardList = [];
    colorList = [];
    typeList = [];
    rarityList = [];
    costList = [];
    abilityList = [];
  }
}
