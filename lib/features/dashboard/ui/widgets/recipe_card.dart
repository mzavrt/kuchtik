import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';
import 'package:kuchtik/features/recipes/ui/view_models/favorite_recipes_view_model.dart';
import 'package:kuchtik/features/pantry/providers/user_pantry_ingredient_ids_provider.dart';

enum RecipeCardVariant { urgent, perfectMatch, missingOne, discovery, favorites }

class RecipeCard extends ConsumerWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.variant,
    this.onTap,
    this.width = 220,
  });

  final RecipeDashboardItem recipe;
  final RecipeCardVariant variant;
  final VoidCallback? onTap;
  final double? width;

  int _countAvailableIngredients({
    required Set<String> pantryIngredientIds,
    required List<String> recipeIngredientIds,
  }) {
    if (recipeIngredientIds.isEmpty || pantryIngredientIds.isEmpty) return 0;

    var count = 0;
    final seen = <String>{};
    for (final id in recipeIngredientIds) {
      if (!seen.add(id)) continue;
      if (pantryIngredientIds.contains(id)) count += 1;
    }

    return count;
  }

  double _bottomContentHeight(
  RecipeCardVariant variant,
  RecipeDashboardItem recipe,
) {
  var height = 46.0; // reserved title height, always 2 lines

  if (recipe.ingredientIds.isNotEmpty) {
    height += 34; // ingredient chip + bottom padding
  }

  if (variant == RecipeCardVariant.missingOne &&
      recipe.missingOneText != null) {
    height += 24;
  }

  return height;
}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final favoriteIdsAsync = ref.watch(favoriteRecipeIdsProvider);
    final isFavorite = favoriteIdsAsync.maybeWhen(
      data: (ids) => ids.contains(recipe.id),
      orElse: () => false,
    );

    final pantryIdsAsync = ref.watch(userPantryIngredientIdsProvider);
    final totalIngredients = recipe.ingredientIds.toSet().length;
    final availableIngredients = pantryIdsAsync.maybeWhen(
      data: (ids) => _countAvailableIngredients(
        pantryIngredientIds: ids,
        recipeIngredientIds: recipe.ingredientIds,
      ),
      orElse: () => null,
    );

    final card = Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: recipe.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    ColoredBox(color: colorScheme.surfaceContainerHighest),
                errorWidget: (context, url, error) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 40,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton.filledTonal(
                onPressed: (favoriteIdsAsync.isLoading || favoriteIdsAsync.hasError)
                    ? null
                    : () {
                        ref
                            .read(favoriteRecipeIdsProvider.notifier)
                            .toggleFavorite(recipe.id);
                      },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? colorScheme.error : null,
                ),
                tooltip: isFavorite ? 'Odebrat z oblíbených' : 'Uložit do oblíbených',
              ),
            ),
            Positioned(
  left: 12,
  right: 12,
  bottom: 12,
  child: SizedBox(
    height: _bottomContentHeight(variant, recipe),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalIngredients > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.kitchen,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${availableIngredients ?? '—'}/$totalIngredients',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (variant == RecipeCardVariant.missingOne &&
            recipe.missingOneText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Chybí: ${recipe.missingOneText}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        SizedBox(
          height: 42,
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              recipe.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
          ],
        ),
      ),
    );

    if (width == null) return card;
    return SizedBox(width: width, child: card);
  }
}
