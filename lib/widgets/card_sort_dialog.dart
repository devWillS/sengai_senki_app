import 'package:flutter/material.dart';
import 'package:senkai_sengi/models/card_sort_option.dart';

class CardSortDialog extends StatelessWidget {
  const CardSortDialog({super.key, required this.selected});

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
