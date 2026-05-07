import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';
import 'package:kuchtik/features/recipes/ui/view_models/favorite_recipes_view_model.dart';

enum RecipeCardVariant {
  urgent,
  perfectMatch,
  missingOne,
  discovery,
  favorites,
  ingredientFilter,
}

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

  double _bottomContentHeight(
    RecipeCardVariant variant,
    RecipeDashboardItem recipe,
  ) {
    var height = 50.0; // title height, reserved for max 2 lines

    final showIngredientMatch = recipe.totalIngredients > 0;
    final showUrgentText =
        variant == RecipeCardVariant.urgent &&
        recipe.urgentIngredientCount > 0;
    final showMissingOneText =
        variant == RecipeCardVariant.missingOne &&
        recipe.missingOneText != null;

    if (showIngredientMatch) {
      height += 34;
    }

    if (showUrgentText) {
      height += 22;
    }

    if (showMissingOneText) {
      height += 24;
    }

    return height;
  }

  String _urgentText(int count) {
    if (count <= 0) return '';

    if (count == 1) {
      return 'Zachráníš 1 surovinu';
    }

    if (count >= 2 && count <= 4) {
      return 'Zachráníš $count suroviny';
    }

    return 'Zachráníš $count surovin';
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

    final showIngredientMatch = recipe.totalIngredients > 0;
    final isPerfectIngredientMatch = showIngredientMatch &&
        recipe.availableIngredients >= recipe.totalIngredients;

    final showUrgentText =
        variant == RecipeCardVariant.urgent &&
        recipe.urgentIngredientCount > 0;
    final showMissingOneText =
        variant == RecipeCardVariant.missingOne &&
        recipe.missingOneText != null;

    final card = Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: recipe.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                ),
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
                      Colors.black.withValues(alpha: 0.10),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),

            if (recipe.prepTimeMinutes != null)
              Positioned(
                left: 12,
                top: 12,
                child: _RecipeBadge(
                  icon: Icons.schedule,
                  label: '${recipe.prepTimeMinutes} min',
                ),
              ),

            Positioned(
              right: 12,
              top: 12,
              child: IconButton.filledTonal(
                onPressed:
                    (favoriteIdsAsync.isLoading || favoriteIdsAsync.hasError)
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
                tooltip:
                    isFavorite ? 'Odebrat z oblíbených' : 'Uložit do oblíbených',
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
                    if (showIngredientMatch)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RecipeBadge(
                          icon: isPerfectIngredientMatch
                              ? Icons.check
                              : Icons.kitchen,
                          label:
                              '${recipe.availableIngredients}/${recipe.totalIngredients}',
                          dark: !isPerfectIngredientMatch,
                          success: isPerfectIngredientMatch,
                        ),
                      ),

                    if (showUrgentText)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _urgentText(recipe.urgentIngredientCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFFFE082),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                    if (showMissingOneText)
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

class _RecipeBadge extends StatelessWidget {
  const _RecipeBadge({
    required this.icon,
    required this.label,
    this.dark = false,
    this.success = false,
  });

  final IconData icon;
  final String label;
  final bool dark;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = success
        ? colorScheme.primaryContainer
        : dark
            ? colorScheme.surface.withValues(alpha: 0.22)
            : colorScheme.surface.withValues(alpha: 0.78);

    final foregroundColor = success
        ? colorScheme.onPrimaryContainer
        : dark
            ? Colors.white
            : colorScheme.onSurface;

    final borderColor = success
        ? colorScheme.primary.withValues(alpha: 0.40)
        : Colors.white.withValues(alpha: 0.16);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}