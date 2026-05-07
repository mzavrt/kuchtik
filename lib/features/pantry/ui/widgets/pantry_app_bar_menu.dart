import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';

class PantryAppBarMenu extends ConsumerWidget {
  const PantryAppBarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryAsync = ref.watch(pantryViewModelProvider);

    return pantryAsync.maybeWhen(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return PopupMenuButton<_PantryMenuAction>(
          tooltip: 'Další možnosti',
          icon: const Icon(Icons.more_vert),
          onSelected: (action) async {
            switch (action) {
              case _PantryMenuAction.clearPantry:
                await _confirmClearPantry(context, ref);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _PantryMenuAction.clearPantry,
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vymazat lednici',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

enum _PantryMenuAction {
  clearPantry,
}

Future<void> _confirmClearPantry(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Vymazat lednici?'),
        content: const Text(
          'Tímto odstraníte všechny ingredience ze své lednice. '
          'Tuto akci nelze vrátit zpět.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Vymazat'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  try {
    await ref.read(pantryViewModelProvider.notifier).clearPantry();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lednice byla vymazána.')),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chyba při mazání lednice: $e')),
    );
  }
}