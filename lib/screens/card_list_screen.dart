import 'package:flutter/material.dart';

import '../models/card_data.dart';
import '../models/card_filter_state.dart';
import '../models/card_sort_option.dart';
import '../repositories/card_repository.dart';
import '../widgets/card_tile.dart';
import 'card_detail_overlay.dart';

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

  List<String> _availableColors = const [];
  List<String> _availableRarities = const [];
  List<String> _availableTypes = const [];
  List<int> _availableCosts = const [];

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

    final colors = {
      for (final card in cards)
        if (card.color.isNotEmpty) card.color,
    }.toList()..sort();

    final rarities = {
      for (final card in cards)
        if (card.rarity.isNotEmpty) card.rarity,
    }.toList()..sort();

    final types = {
      for (final card in cards)
        if (card.type.isNotEmpty) card.type,
    }.toList()..sort();

    final costs = {
      for (final card in cards)
        if (card.cost != null) card.cost,
    }.whereType<int>().toList()..sort();

    if (!mounted) {
      return;
    }

    setState(() {
      _allCards = cards;
      _availableColors = colors;
      _availableRarities = rarities;
      _availableTypes = types;
      _availableCosts = costs;
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

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<CardFilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CardFilterSheet(
        initial: _filter,
        colors: _availableColors,
        rarities: _availableRarities,
        types: _availableTypes,
        costs: _availableCosts,
      ),
    );

    if (result != null && result != _filter) {
      setState(() {
        _filter = result;
      });
      _applyFilters();
    }
  }

  void _openSortDialog() async {
    final result = await showDialog<CardSortOption>(
      context: context,
      builder: (context) => _CardSortDialog(selected: _sort),
    );

    if (result != null && result != _sort) {
      setState(() {
        _sort = result;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _filter = CardFilterState.empty;
    });
    _applyFilters();
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

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_filter.keyword.trim().isNotEmpty) {
      chips.add(
        InputChip(
          label: Text('キーワード: ${_filter.keyword}'),
          onDeleted: () {
            setState(() {
              _filter = _filter.copyWith(keyword: '');
            });
            _applyFilters();
          },
        ),
      );
    }

    for (final color in _filter.colors) {
      chips.add(
        InputChip(
          label: Text('色: $color'),
          onDeleted: () {
            setState(() {
              _filter = _filter.toggleColor(color);
            });
            _applyFilters();
          },
        ),
      );
    }

    for (final rarity in _filter.rarities) {
      chips.add(
        InputChip(
          label: Text(rarity),
          onDeleted: () {
            setState(() {
              _filter = _filter.toggleRarity(rarity);
            });
            _applyFilters();
          },
        ),
      );
    }

    for (final type in _filter.types) {
      chips.add(
        InputChip(
          label: Text(type),
          onDeleted: () {
            setState(() {
              _filter = _filter.toggleType(type);
            });
            _applyFilters();
          },
        ),
      );
    }

    for (final cost in _filter.costs) {
      chips.add(
        InputChip(
          label: Text('$cost'),
          onDeleted: () {
            setState(() {
              _filter = _filter.toggleCost(cost);
            });
            _applyFilters();
          },
        ),
      );
    }

    return chips;
  }

  Widget _buildFilterPanel() {
    final theme = Theme.of(context);
    final chips = _buildActiveFilterChips();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(spacing: 8, runSpacing: 8, children: chips),
                  ),
                ),
                const SizedBox(width: 8),
                if (_filter.hasFilter)
                  Tooltip(
                    message: '条件を解除',
                    child: GestureDetector(
                      onTap: _clearFilters,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'フィルター',
                  child: GestureDetector(
                    onTap: _openFilterSheet,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.filter_alt, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: '並び替え',
                  child: GestureDetector(
                    onTap: _openSortDialog,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(_sort.icon, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '表示件数: ${_visibleCards.length}',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '総カード数: ${_allCards.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
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
      backgroundColor: const Color(0xFF3e3e3e),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('カード一覧'),
        centerTitle: false,
        elevation: 0,
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
                _buildFilterPanel(),
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
          );
        },
      ),
    );
  }
}

class _CardSortDialog extends StatelessWidget {
  const _CardSortDialog({required this.selected});

  final CardSortOption selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleDialog(
      title: const Text('並び替え'),
      children: CardSortOption.values
          .map(
            (option) => SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(option),
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    color: option == selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.label,
                      style: option == selected
                          ? theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            )
                          : theme.textTheme.bodyLarge,
                    ),
                  ),
                  if (option == selected)
                    Icon(Icons.check, color: theme.colorScheme.primary),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CardFilterSheet extends StatefulWidget {
  const _CardFilterSheet({
    required this.initial,
    required this.colors,
    required this.rarities,
    required this.types,
    required this.costs,
  });

  final CardFilterState initial;
  final List<String> colors;
  final List<String> rarities;
  final List<String> types;
  final List<int> costs;

  @override
  State<_CardFilterSheet> createState() => _CardFilterSheetState();
}

class _CardFilterSheetState extends State<_CardFilterSheet> {
  late CardFilterState _working = widget.initial;
  late final TextEditingController _keywordController = TextEditingController(
    text: widget.initial.keyword,
  );

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(
      context,
    ).pop(_working.copyWith(keyword: _keywordController.text));
  }

  void _clear() {
    setState(() {
      _working = CardFilterState.empty;
      _keywordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 6,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  children: [
                    Text('カードを絞り込み', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keywordController,
                      decoration: const InputDecoration(
                        labelText: 'キーワード',
                        hintText: 'カード名 / カードID / 特徴',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FilterSection(
                      title: '色',
                      children: widget.colors
                          .map(
                            (color) => FilterChip(
                              label: Text(color),
                              selected: _working.colors.contains(color),
                              onSelected: (_) {
                                setState(() {
                                  _working = _working.toggleColor(color);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    _FilterSection(
                      title: 'タイプ',
                      children: widget.types
                          .map(
                            (type) => FilterChip(
                              label: Text(type),
                              selected: _working.types.contains(type),
                              onSelected: (_) {
                                setState(() {
                                  _working = _working.toggleType(type);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    _FilterSection(
                      title: 'レアリティ',
                      children: widget.rarities
                          .map(
                            (rarity) => FilterChip(
                              label: Text(rarity),
                              selected: _working.rarities.contains(rarity),
                              onSelected: (_) {
                                setState(() {
                                  _working = _working.toggleRarity(rarity);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    _FilterSection(
                      title: 'コスト',
                      children: widget.costs
                          .map(
                            (cost) => FilterChip(
                              label: Text(cost.toString()),
                              selected: _working.costs.contains(cost),
                              onSelected: (_) {
                                setState(() {
                                  _working = _working.toggleCost(cost);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        child: const Text('クリア'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _apply,
                        child: const Text('適用'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Text('該当する項目はありません', style: theme.textTheme.bodySmall)
        else
          Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}
