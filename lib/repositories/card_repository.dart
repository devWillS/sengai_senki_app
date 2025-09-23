import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/card_data.dart';

class CardRepository {
  const CardRepository();

  Future<List<CardData>> loadCards() async {
    final rawJson = await rootBundle.loadString('assets/json/cards.json');
    final List<dynamic> decoded = json.decode(rawJson) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CardData.fromJson)
        .toList();
  }
}
