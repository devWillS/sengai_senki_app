import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:senkai_sengi/models/card_filter_state.dart';
import 'package:senkai_sengi/models/card_sort_option.dart';
import 'package:senkai_sengi/screens/card_detail_overlay.dart';
import 'package:senkai_sengi/widgets/card_tile.dart';
import 'package:senkai_sengi/widgets/filter_panel.dart';

import '../models/card_data.dart';
import '../models/deck.dart';
import '../view_models/deck_detail_view_model.dart';

// Providers
final visibleCardsProvider = StateProvider<List<CardData>>((ref) => []);
final cardsPerLineProvider = StateProvider<int>((ref) => 4);

class DeckEditScreen extends ConsumerStatefulWidget {
  const DeckEditScreen({
    super.key,
    required this.deck,
    required this.viewModel,
  });

  final Deck deck;
  final DeckDetailViewModel viewModel;

  @override
  ConsumerState<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends ConsumerState<DeckEditScreen> {
  late final DeckDetailViewModel viewModel;

  final ScrollController _scrollController = ScrollController();

  late Future<void> _initialLoad;

  List<CardData> _allCards = const [];
  CardFilterState _filter = CardFilterState.empty;
  CardSortOption _sort = CardSortOption.idAscending;

  @override
  void initState() {
    super.initState();
    viewModel = widget.viewModel;
    // プロバイダの状態は既に設定されているので、initFromDeckは呼ばない
    // デッキ詳細画面から渡されるdeck情報は現在の状態を反映している
    _initialLoad = _loadCards();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _removeCard(int index, bool isMainDeck) {
    viewModel.removeCard(index, isMainDeck);
    setState(() {});
  }

  void _addCard(CardData card) {
    viewModel.addCard(card);
    setState(() {});
  }

  Widget _buildCardGrid(
    List<CardData> cards,
    int totalSlots, {
    bool isMainDeck = false,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 0.7,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < cards.length) {
          final card = cards[index];

          return GestureDetector(
            onTap: () => _removeCard(index, isMainDeck),
            onLongPress: () {
              final mainDeckCards = ref.read(mainDeckCardsProvider);
              _showCardDetail(
                isMainDeck
                    ? index
                    : mainDeckCards.length + index,
                'deck-${card.id}-$index',
              );
            },
            child: Hero(
              tag: 'deck-${card.id}-$index',
              child: CardTile(card: card),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black38),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Watch providers for reactive updates
    final mainDeckCards = ref.watch(mainDeckCardsProvider);
    final magicDeckCards = ref.watch(magicDeckCardsProvider);
    final visibleCards = ref.watch(visibleCardsProvider);
    final cardsPerLine = ref.watch(cardsPerLineProvider);

    return SafeArea(
      top: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF3E3E3E),
        appBar: CupertinoNavigationBar(
          backgroundColor: theme.colorScheme.primary,
          leading: CupertinoNavigationBarBackButton(
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          middle: const Text(
            'デッキ編集',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        floatingActionButton: MediaQuery.of(context).size.width < 600
            ? FloatingActionButton(
                onPressed: _cycleCardsPerLine,
                child: const Icon(Icons.grid_view),
              )
            : null,
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  _buildCardGrid(
                    mainDeckCards,
                    20,
                    isMainDeck: true,
                  ),
                  const SizedBox(height: 1),
                  _buildCardGrid(magicDeckCards, 10),
                ],
              ),
            ),
            FilterPanel(
              filter: _filter,
              sort: _sort,
              allCards: _allCards,
              visibleCards: visibleCards,
              onFilterChanged: (filter) {
                setState(() {
                  _filter = filter;
                  _applyFilters();
                });
              },
              onSortChanged: (sort) {
                setState(() {
                  _sort = sort;
                  _applyFilters();
                });
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
                            if (visibleCards.isEmpty)
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
                                padding: const EdgeInsets.only(bottom: 75.0),
                                child: GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 5,
                                  ),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: visibleCards.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _resolveCrossAxisCount(
                                          innerConstraints.maxWidth,
                                          cardsPerLine,
                                        ),
                                        mainAxisSpacing: 5,
                                        crossAxisSpacing: 5,
                                        childAspectRatio: 670 / 950,
                                      ),
                                  itemBuilder: (context, index) {
                                    final card = visibleCards[index];
                                    return GestureDetector(
                                      onTap: () => _addCard(card),
                                      onLongPress: () => _openCardDetail(
                                        index,
                                        'card-${card.id}-$index',
                                      ),
                                      child: Hero(
                                        tag: 'card-${card.id}-$index',
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
      ),
    );
  }

  void _applyFilters() {
    final filtered = _filter.apply(_allCards)..sort(_sort.compare);
    ref.read(visibleCardsProvider.notifier).state = filtered;
  }

  Future<void> _loadCards() async {
    final cards = viewModel.masterCardList;
    cards.sort((a, b) => a.id.compareTo(b.id));

    if (!mounted) {
      return;
    }

    _allCards = cards;
    _applyFilters();
  }

  Future<void> _reload() async {
    _initialLoad = _loadCards();
    await _initialLoad;
  }

  void _openCardDetail(int index, Object tag) {
    final visibleCards = ref.read(visibleCardsProvider);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: CardDetailOverlay(
              initialIndex: index,
              cards: visibleCards,
              heroTag: tag,
            ),
          );
        },
      ),
    );
  }

  void _showCardDetail(int index, Object tag) {
    final mainDeckCards = ref.read(mainDeckCardsProvider);
    final magicDeckCards = ref.read(magicDeckCardsProvider);
    
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: CardDetailOverlay(
              initialIndex: index,
              cards: mainDeckCards + magicDeckCards,
              heroTag: tag,
            ),
          );
        },
      ),
    );
  }

  int _resolveCrossAxisCount(double maxWidth, int cardsPerLine) {
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
    return cardsPerLine;
  }

  void _cycleCardsPerLine() {
    final currentValue = ref.read(cardsPerLineProvider);
    final newValue = currentValue > 1 ? currentValue - 1 : 5;
    ref.read(cardsPerLineProvider.notifier).state = newValue;
  }
}