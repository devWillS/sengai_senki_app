import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senkai_sengi/screens/deck_detail_screen.dart';

import '../models/card_data.dart';
import '../models/deck.dart';
import '../repositories/card_repository.dart';
import '../view_models/deck_list_view_model.dart';

class DeckListScreen extends ConsumerStatefulWidget {
  const DeckListScreen({super.key});

  @override
  ConsumerState<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends ConsumerState<DeckListScreen> {
  final CardRepository _cardRepository = const CardRepository();
  final TextEditingController _searchController = TextEditingController();

  late Future<void> _initialLoad;
  Map<String, CardData> _cardLookup = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initialLoad = _loadData();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final cards = await _cardRepository.loadCards();
    setState(() {
      _cardLookup = {for (final card in cards) card.id: card};
    });
    await ref.read(deckListProvider.notifier).loadDecks();
  }

  void _applyFilter() {
    final query = _searchController.text.trim();
    ref.read(deckSearchQueryProvider.notifier).state = query;
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadData();
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _openDeck(Deck deck) async {
    final updated = await Navigator.of(context).push<Deck>(
      MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
    );
    if (updated != null) {
      if (deck.id.startsWith('user_')) {
        final key = int.parse(deck.id.replaceFirst('user_', ''));
        await ref.read(deckListProvider.notifier).updateDeck(key, updated);
      } else {
        await ref.read(deckListProvider.notifier).addDeck(updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final decksAsync = ref.watch(deckListProvider);
    final filteredDecks = ref.watch(filteredDeckListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.primary,
        middle: const Text(
          'デッキ一覧',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newDeck = Deck(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: '',
            description: '',
            mainDeck: const [],
            magicDeck: const [],
            updatedAt: DateTime.now(),
          );
          final updated = await Navigator.of(context).push<Deck>(
            MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: newDeck)),
          );
          if (updated != null) {
            await ref.read(deckListProvider.notifier).addDeck(updated);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<void>(
        future: _initialLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cardLookup.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return decksAsync.when(
            data: (_) => RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: 75,
                ),
                children: [
                  if (_isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),
                  if (filteredDecks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 140),
                      child: Column(
                        children: const [
                          Icon(Icons.inbox_outlined, size: 64),
                          SizedBox(height: 16),
                          Text('一致するデッキがありません。'),
                        ],
                      ),
                    )
                  else
                    ...filteredDecks.map(
                      (deck) => _DeckSummaryCard(
                        deck: deck,
                        cardLookup: _cardLookup,
                        onOpen: () => _openDeck(deck),
                      ),
                    ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text('デッキ情報の読み込みに失敗しました。'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeckSummaryCard extends StatelessWidget {
  const _DeckSummaryCard({
    required this.deck,
    required this.cardLookup,
    required this.onOpen,
  });

  final Deck deck;
  final Map<String, CardData> cardLookup;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updatedAt = deck.updatedAt;
    final updatedLabel = updatedAt == null
        ? '-'
        : '${updatedAt.month}/${updatedAt.day}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '${deck.totalCards}枚',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '怪 ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${deck.typeCount("怪魔")}枚',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '呪 ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${deck.typeCount("呪文")}枚',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '付 ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${deck.typeCount("付与")}枚',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '魔 ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${deck.typeCount("魔力")}枚',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
