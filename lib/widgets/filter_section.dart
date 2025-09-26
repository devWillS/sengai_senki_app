import 'package:flutter/material.dart';

class FilterSection<T> extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.title,
    required this.list,
    required this.selectedList,
    required this.onSelected,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<T> list;
  final List<T> selectedList;
  final Function(bool selected, T element) onSelected;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontSize: 12)),
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: initiallyExpanded,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 5.0,
          runSpacing: 5.0,
          children: list.map((element) {
            final selected = selectedList.contains(element);
            return FilterChip(
              visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              selectedColor: Theme.of(context).colorScheme.primary,
              showCheckmark: false,
              selected: selected,
              label: Text(
                element.toString(),
                style: const TextStyle(fontSize: 12),
              ),
              labelStyle: selected
                  ? const TextStyle(color: Colors.white)
                  : null,
              onSelected: (bool value) {
                onSelected.call(value, element);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
