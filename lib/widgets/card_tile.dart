import 'dart:math';

import 'package:flutter/material.dart';
import 'package:senkai_sengi/utils/network_image_builder.dart';

import '../models/card_data.dart';

class CardTile extends StatelessWidget {
  const CardTile({super.key, required this.card});

  final CardData card;

  @override
  Widget build(BuildContext context) {
    return Center(
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
  }
}
