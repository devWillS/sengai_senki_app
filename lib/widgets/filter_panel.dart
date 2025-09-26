import 'package:flutter/material.dart';
import 'package:senkai_sengi/models/card_data.dart';
import 'package:senkai_sengi/models/card_filter_state.dart';
import 'package:senkai_sengi/models/card_sort_option.dart';
import 'package:senkai_sengi/widgets/card_filter_sheet.dart';
import 'package:senkai_sengi/widgets/card_sort_dialog.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.allCards,
    required this.visibleCards,
  });

  final CardFilterState filter;
  final CardSortOption sort;
  final ValueChanged<CardFilterState> onFilterChanged;
  final ValueChanged<CardSortOption> onSortChanged;

  final List<CardData> allCards;
  final List<CardData> visibleCards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = _buildActiveFilterChips(context);

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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(spacing: 2, runSpacing: 2, children: chips),
                  ),
                ),
                const SizedBox(width: 8),
                if (filter.hasFilter)
                  Tooltip(
                    message: '条件を解除',
                    child: GestureDetector(
                      onTap: () => onFilterChanged(CardFilterState.empty),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'フィルター',
                  child: GestureDetector(
                    onTap: () => _openFilterSheet(context),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(
                        Icons.filter_alt,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: '並び替え',
                  child: GestureDetector(
                    onTap: () => _openSortDialog(context),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(sort.icon, color: Colors.white, size: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${visibleCards.length}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                Text(
                  '件',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActiveFilterChips(BuildContext context) {
    final chips = <Widget>[];

    if (filter.keyword.trim().isNotEmpty) {
      chips.add(
        createFilterChip(context, filter.keyword, () {
          onFilterChanged(filter.copyWith(keyword: ''));
        }),
      );
    }

    for (final color in filter.colors) {
      chips.add(
        createFilterChip(context, color, () {
          filter.colors.remove(color);
          onFilterChanged(filter.copyWith(colors: filter.colors));
        }),
      );
    }

    for (final rarity in filter.rarities) {
      chips.add(
        createFilterChip(context, rarity, () {
          filter.rarities.remove(rarity);
          onFilterChanged(filter.copyWith(rarities: filter.rarities));
        }),
      );
    }

    for (final type in filter.types) {
      chips.add(
        createFilterChip(context, type, () {
          filter.types.remove(type);
          onFilterChanged(filter.copyWith(types: filter.types));
        }),
      );
    }

    for (final cost in filter.costs) {
      chips.add(
        createFilterChip(context, '$cost', () {
          filter.costs.remove(cost);
          onFilterChanged(filter.copyWith(costs: filter.costs));
        }),
      );
    }

    return chips;
  }

  void _openFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<CardFilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardFilterSheet(initial: filter),
    );

    if (result != null && result != filter) {
      onFilterChanged(result);
    }
  }

  void _openSortDialog(BuildContext context) async {
    final result = await showDialog<CardSortOption>(
      context: context,
      builder: (context) => CardSortDialog(selected: sort),
    );

    if (result != null && result != sort) {
      onSortChanged(result);
    }
  }

  Widget createFilterChip(
    BuildContext context,
    String text,
    Function onTapped,
  ) {
    return FilterChip(
      visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      selectedColor: Theme.of(context).colorScheme.primary,
      showCheckmark: false,
      selected: true,
      label: Text(text, style: const TextStyle(fontSize: 12)),
      labelStyle: const TextStyle(color: Colors.white),
      onSelected: (bool value) {
        onTapped();
      },
    );
  }
}
