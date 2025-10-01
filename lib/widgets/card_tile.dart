import 'dart:math';

import 'package:flutter/material.dart';
import 'package:senkai_sengi/utils/network_image_builder.dart';

import '../models/card_data.dart';

class CardTile extends StatelessWidget {
  const CardTile({super.key, required this.card, this.heroTag});

  final CardData card;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Center(
      child: LayoutBuilder(
        builder: (context, constrains) {
          double long = max<double>(constrains.maxHeight, constrains.maxWidth);
          return ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(long / 950 * 23)),
            child: AspectRatio(
              aspectRatio: 670 / 950,
              child: NetworkImageBuilder(card.imageUrl),
            ),
          );
        },
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: cardWidget,
      );
    }
    
    return cardWidget;
  }
}
