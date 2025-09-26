import 'package:flutter/material.dart';
import 'package:senkai_sengi/models/card_filter_state.dart';
import 'package:senkai_sengi/utils/master.dart';
import 'package:senkai_sengi/widgets/filter_section.dart';

class CardFilterSheet extends StatefulWidget {
  CardFilterSheet({super.key, required this.initial});

  final CardFilterState initial;
  final List<String> colors = Master().colorList;
  final List<String> rarities = Master().rarityList;
  final List<String> types = Master().typeList;
  final List<int> costs = Master().costList;

  @override
  State<CardFilterSheet> createState() => CardFilterSheetState();
}

class CardFilterSheetState extends State<CardFilterSheet> {
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
        return SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              listTileTheme: ListTileTheme.of(context).copyWith(dense: true),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                        horizontal: 12,
                        vertical: 8,
                      ),
                      children: [
                        Text('絞り込み', style: TextStyle(fontSize: 20)),
                        SizedBox(height: 10),
                        TextField(
                          controller: _keywordController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10),
                            hintText: 'キーワード',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            isDense: true,
                            isCollapsed: true,
                          ),
                        ),
                        FilterSection(
                          title: '色',
                          list: widget.colors,
                          initiallyExpanded: true,
                          selectedList: _working.colors.toList(),
                          onSelected: (selected, element) {
                            setState(() {
                              _working = _working.toggleColor(element);
                            });
                          },
                        ),
                        FilterSection(
                          title: 'タイプ',
                          list: widget.types,
                          initiallyExpanded: true,
                          selectedList: _working.types.toList(),
                          onSelected: (selected, element) {
                            setState(() {
                              _working = _working.toggleType(element);
                            });
                          },
                        ),
                        FilterSection(
                          title: 'レアリティ',
                          list: widget.rarities,
                          initiallyExpanded: true,
                          selectedList: _working.rarities.toList(),
                          onSelected: (selected, element) {
                            setState(() {
                              _working = _working.toggleRarity(element);
                            });
                          },
                        ),
                        FilterSection(
                          title: 'コスト',
                          list: widget.costs,
                          initiallyExpanded: true,
                          selectedList: _working.costs.toList(),
                          onSelected: (selected, element) {
                            setState(() {
                              _working = _working.toggleCost(element);
                            });
                          },
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
            ),
          ),
        );
      },
    );
  }
}
