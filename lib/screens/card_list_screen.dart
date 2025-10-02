import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:senkai_sengi/widgets/filter_panel.dart';

import '../models/card_data.dart';
import '../models/card_filter_state.dart';
import '../models/card_sort_option.dart';
import '../repositories/card_repository.dart';
import '../widgets/card_tile.dart';
import 'card_detail_overlay.dart';
import 'holo_card.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final CardRepository _repository = const CardRepository();
  final ScrollController _scrollController = ScrollController();

  late Future<void> _initialLoad;

  List<CardData> _allCards = const [];
  List<CardData> _visibleCards = const [];
  CardFilterState _filter = CardFilterState.empty;
  CardSortOption _sort = CardSortOption.idAscending;

  int _cardsPerLine = 4;

  @override
  void initState() {
    super.initState();
    _initialLoad = _loadCards();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final cards = await _repository.loadCards();
    cards.sort((a, b) => a.id.compareTo(b.id));

    if (!mounted) {
      return;
    }

    setState(() {
      _allCards = cards;
      _applyFilters(rebuild: false);
    });
  }

  Future<void> _reload() async {
    setState(() {
      _initialLoad = _loadCards();
    });
    await _initialLoad;
  }

  void _applyFilters({bool rebuild = true}) {
    final filtered = _filter.apply(_allCards)..sort(_sort.compare);
    if (rebuild) {
      setState(() {
        _visibleCards = filtered;
      });
    } else {
      _visibleCards = filtered;
    }
  }

  void _openCardDetail(int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: CardDetailOverlay(initialIndex: index, cards: _visibleCards),
          );
        },
      ),
    );
  }

  void _showHoloCard(CardData card, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 背景を透明に
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black54,
            body: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.all(20),
                child: Hero(
                  tag: index,
                  child: HoloCard(
                    card: card,
                    showGlitter: card.rarity == "LR",
                    showGloss: card.rarity == "SR" || card.rarity == "LR",
                    showRainbow: card.rarity == "SR" || card.rarity == "LR",
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  int _resolveCrossAxisCount(double maxWidth) {
    if (maxWidth >= 1200) {
      return 8;
    }
    if (maxWidth >= 1000) {
      return 7;
    }
    if (maxWidth >= 800) {
      return 6;
    }
    if (maxWidth >= 600) {
      return 5;
    }
    return _cardsPerLine;
  }

  void _cycleCardsPerLine() {
    setState(() {
      _cardsPerLine -= 1;
      if (_cardsPerLine < 1) {
        _cardsPerLine = 5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.primary,
        middle: const Text(
          'カード一覧',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      floatingActionButton: MediaQuery.of(context).size.width < 600
          ? FloatingActionButton(
              onPressed: _cycleCardsPerLine,
              child: const Icon(Icons.grid_view),
            )
          : null,
      body: FutureBuilder<void>(
        future: _initialLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text('カード情報の読み込みに失敗しました。'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterPanel(
                  filter: _filter,
                  sort: _sort,
                  allCards: _allCards,
                  visibleCards: _visibleCards,
                  onFilterChanged: (filter) {
                    setState(() {
                      _filter = filter;
                    });
                    _applyFilters();
                  },
                  onSortChanged: (sort) {
                    setState(() {
                      _sort = sort;
                    });
                    _applyFilters();
                  },
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, innerConstraints) {
                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: innerConstraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_visibleCards.isEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 80),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x11000000),
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.search_off, size: 48),
                                        const SizedBox(height: 12),
                                        Text(
                                          '条件に一致するカードがありません。',
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 75.0,
                                    ),
                                    child: GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 5,
                                      ),
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _visibleCards.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                _resolveCrossAxisCount(
                                                  innerConstraints.maxWidth,
                                                ),
                                            mainAxisSpacing: 5,
                                            crossAxisSpacing: 5,
                                            childAspectRatio: 670 / 950,
                                          ),
                                      itemBuilder: (context, index) {
                                        final card = _visibleCards[index];
                                        return GestureDetector(
                                          onTap: () => _openCardDetail(index),
                                          onLongPress: () =>
                                              _showHoloCard(card, index),
                                          child: Hero(
                                            tag: index,
                                            child: CardTile(card: card),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
