import 'package:flutter/material.dart';

@immutable
class CardData {
  const CardData({
    required this.id,
    required this.name,
    required this.color,
    required this.type,
    required this.rarity,
    this.feature,
    this.cost,
    this.ap,
    this.hp,
    this.attribute,
    this.illustrator,
    this.apCorrection,
    this.hpCorrection,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String color;
  final String type;
  final String rarity;
  final String? feature;
  final int? cost;
  final int? ap;
  final int? hp;
  final String? attribute;
  final String? illustrator;
  final String? apCorrection;
  final String? hpCorrection;
  final String imageUrl;

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      type: json['type'] as String,
      rarity: json['rarity'] as String,
      feature: json['feature'] as String?,
      cost: json['cost'] is num ? (json['cost'] as num).toInt() : null,
      ap: json['ap'] is num ? (json['ap'] as num).toInt() : null,
      hp: json['hp'] is num ? (json['hp'] as num).toInt() : null,
      attribute: json['attribute'] as String?,
      illustrator: json['illustrator'] as String?,
      apCorrection: json['ap_correction'] as String?,
      hpCorrection: json['hp_correction'] as String?,
      imageUrl: json['image_url'] as String,
    );
  }
}

extension CardExtension on CardData {
  Color getColor() {
    switch (color) {
      case "赤":
        return Colors.red;
      case "青":
        return Colors.blue;
      case "緑":
      default:
        return Colors.green;
    }
  }
}
