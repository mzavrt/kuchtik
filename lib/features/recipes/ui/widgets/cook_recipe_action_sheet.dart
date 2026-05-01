import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/recipes/domain/recipe_detail.dart';
import 'package:kuchtik/features/recipes/ui/view_models/cook_recipe_view_model.dart';

class CookRecipeActionSheet extends ConsumerWidget {
  const CookRecipeActionSheet({
    super.key,
    required this.recipe,
  });

  final RecipeDetail recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cookRecipeViewModelProvider);
    final isLoading = state.isLoading;
    final theme = Theme.of(context);

    Future<void> submit(Future<void> Function() action) async {
      try {
        await action();

        if (!context.mounted) return;

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zásoby byly aktualizovány.'),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při aktualizaci zásob: $e'),
          ),
        );
      }
    }

    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Uvařeno?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Jak chcete upravit zásoby?',
              style: theme.textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 16),

          _CookActionTile(
            icon: Icons.restaurant,
            title: 'Podle receptu',
            subtitle: 'Odečte se množství uvedené v receptu.',
            enabled: !isLoading,
            onTap: () {
              submit(
                () => ref
                    .read(cookRecipeViewModelProvider.notifier)
                    .cookByRecipe(recipe: recipe),
              );
            },
          ),

          _CookActionTile(
            icon: Icons.inventory_2_outlined,
            title: 'Použil jsem vše',
            subtitle: 'Odečtou se všechny zásoby surovin z tohoto receptu.',
            enabled: !isLoading,
            onTap: () {
              submit(
                () => ref
                    .read(cookRecipeViewModelProvider.notifier)
                    .cookUsingAllAvailable(recipe: recipe),
              );
            },
          ),

          _CookActionTile(
            icon: Icons.block,
            title: 'Neodečítat',
            subtitle: 'Zásoby zůstanou beze změny.',
            enabled: !isLoading,
            onTap: () {
              submit(
                () => ref
                    .read(cookRecipeViewModelProvider.notifier)
                    .cookWithoutPantryDeduction(),
              );
            },
          ),

          if (isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _CookActionTile extends StatelessWidget {
  const _CookActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}