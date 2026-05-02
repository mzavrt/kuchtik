import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/dashboard/ui/widgets/recipe_card.dart';
import 'package:kuchtik/features/recipes/ui/recipe_detail_screen.dart';
import 'package:kuchtik/features/recipes/ui/view_models/favorite_recipes_view_model.dart';

class FavoriteRecipesScreen extends ConsumerWidget {
  const FavoriteRecipesScreen({super.key});

  void _openDetail(BuildContext context, String recipeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIdsAsync = ref.watch(favoriteRecipeIdsProvider);

    return favoriteIdsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Nepodařilo se načíst oblíbené recepty',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(favoriteRecipeIdsProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Zkusit znovu'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (favoriteIds) {
        if (favoriteIds.isEmpty) {
          return const _EmptyFavoritesState();
        }

        final recipesAsync = ref.watch(favoriteRecipesProvider);

        return Scaffold(
          body: recipesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Nepodařilo se načíst oblíbené recepty',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        ref.invalidate(favoriteRecipesProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Zkusit znovu'),
                    ),
                  ],
                ),
              ),
            ),
            data: (recipes) {
              final visible = recipes
                  .where(
                    (r) => favoriteIds.contains(r.id),
                  )
                  .toList(growable: false);

              if (visible.isEmpty) {
                return const _EmptyFavoritesState();
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final recipe = visible[index];
                  return RecipeCard(
                    recipe: recipe,
                    variant: RecipeCardVariant.favorites,
                    width: null,
                    onTap: () => _openDetail(context, recipe.id),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Zatím žádné oblíbené recepty',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Uložte si recepty pomocí srdíčka a najdete je tady.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
