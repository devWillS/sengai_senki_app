import 'package:flutter/material.dart';
import 'package:senkai_sengi/screens/holo_card.dart';
import 'package:senkai_sengi/widgets/card_info_row_base.dart';
import 'package:senkai_sengi/widgets/card_name.dart';

import '../models/card_data.dart';
import '../widgets/card_tile.dart';

class CardDetailOverlay extends StatefulWidget {
  const CardDetailOverlay({
    super.key,
    required this.initialIndex,
    required this.cards,
    this.heroTag,
  });

  final int initialIndex;
  final List<CardData> cards;
  final Object? heroTag;

  @override
  State<CardDetailOverlay> createState() => _CardDetailOverlayState();
}

class _CardDetailOverlayState extends State<CardDetailOverlay>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  late Animation<Offset> animation;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    animation = Tween<Offset>(
      begin: const Offset(0.0, 1.5),
      end: Offset.zero,
    ).animate(_animationController);
    _animationController.forward();
    _pageController.addListener(() {
      final page = _pageController.page?.round();
      if (page != null && page != _currentIndex) {
        setState(() {
          _currentIndex = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.cards;
    final heroTag = widget.heroTag;
    final ctrl = _animationController;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          ctrl.reverse();
          Navigator.of(context).pop();
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: PageView.builder(
                  itemCount: list.length,
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    final card = list[index];
                    return Hero(
                      tag: heroTag ?? index,
                      child: GestureDetector(
                        child: CardTile(card: card),
                        onLongPress: () {
                          ctrl.reverse();
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              opaque: false, // 背景を透明に
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    return GestureDetector(
                                      onTap: () {
                                        ctrl.forward();
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(20),
                                        child: Hero(
                                          tag: heroTag ?? index,
                                          child: HoloCard(
                                            card: card,
                                            showGlitter: card.rarity == "LR",
                                            showGloss:
                                                card.rarity == "SR" ||
                                                card.rarity == "LR",
                                            showRainbow:
                                                card.rarity == "SR" ||
                                                card.rarity == "LR",
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: AnimatedBuilder(
                  animation: ctrl,
                  builder: (context, child) {
                    return SlideTransition(
                      position: animation,
                      child: _CardDetailPage(card: list[_currentIndex]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDetailPage extends StatelessWidget {
  const _CardDetailPage({required this.card});

  final CardData card;

  @override
  Widget build(BuildContext context) {
    final attributes = card.attribute?.split(",") ?? [];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.id,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
                if (card.illustrator != null &&
                    card.illustrator!.isNotEmpty) ...[
                  Text(
                    'Art: ${card.illustrator}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ],
              ],
            ),
            CardName(name: card.name),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                card.cost != null
                    ? Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: card.getColor(),
                          border: Border.all(color: card.getColor()),
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        child: Center(
                          child: Text(
                            "${card.cost}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(width: 30, height: 30),
                SizedBox(width: 3),
                Text(card.type, style: TextStyle(fontSize: 15)),
                SizedBox(width: 3),
                Text(card.rarity, style: TextStyle(fontSize: 15)),
              ],
            ),
            _DetailStatList(card: card),
            if (card.attribute != null && card.attribute!.isNotEmpty) ...[
              Wrap(
                spacing: 2,
                children: List.generate(attributes.length, (index) {
                  final attribute = attributes[index];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      attribute,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
              ),
            ],
            if (card.feature != null && card.feature!.isNotEmpty) ...[
              const SizedBox(height: 5),
              CardInfoRowBase(value: card.feature!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailStatList extends StatelessWidget {
  const _DetailStatList({required this.card});

  final CardData card;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        card.ap != null || card.apCorrection != null
            ? Container(
                padding: EdgeInsetsGeometry.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    card.ap != null
                        ? Column(
                            children: [
                              Text(
                                "AP",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "${card.ap}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          )
                        : Container(),
                    card.apCorrection != null
                        ? Column(
                            children: [
                              Text(
                                "AP修正値",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "${card.apCorrection}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          )
                        : Container(),
                  ],
                ),
              )
            : Container(),
        card.hp != null || card.hpCorrection != null
            ? Container(
                padding: EdgeInsetsGeometry.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Row(
                  children: [
                    card.hp != null
                        ? Column(
                            children: [
                              Text(
                                "HP",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "${card.hp}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          )
                        : Container(),
                    card.hpCorrection != null
                        ? Column(
                            children: [
                              Text(
                                "HP修正値",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "${card.hpCorrection}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          )
                        : Container(),
                  ],
                ),
              )
            : Container(),
      ],
    );
  }
}
