import 'dart:math';

import 'package:flutter/material.dart';

import '../models/card_data.dart';

class CardTile extends StatelessWidget {
  const CardTile({super.key, required this.card});

  final CardData card;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constrains) {
          print("@@@@ $constrains");
          double long = max<double>(constrains.maxHeight, constrains.maxWidth);
          return ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(long / 950 * 23)),
            child: AspectRatio(
              aspectRatio: 670 / 950,
              child: _CardImage(url: card.imageUrl),
            ),
          );
        },
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 32,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return const Center(child: CircularProgressIndicator.adaptive());
          },
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x11000000), Color(0x22000000)],
            ),
          ),
        ),
      ],
    );
  }
}
