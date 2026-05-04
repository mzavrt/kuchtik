import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kuchtik/features/recipes/domain/recipe_ingredient.dart';
import 'package:kuchtik/features/recipes/ui/view_models/cook_recipe_view_model.dart';
import 'package:kuchtik/features/recipes/ui/view_models/recipe_detail_view_model.dart';
import 'package:kuchtik/features/recipes/ui/view_models/favorite_recipes_view_model.dart';
import 'package:kuchtik/features/recipes/ui/widgets/cook_recipe_action_sheet.dart';
import 'package:kuchtik/features/recipes/domain/recipe_detail.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  final String recipeId;

  String _formatAmount(num value) {
    if (value is int) return value.toString();

    final intValue = value.toInt();
    if (value == intValue) return intValue.toString();

    return value.toString();
  }

  String _formatIngredientQuantity(RecipeIngredient ingredient) {
    final amount = ingredient.amount;
    final unit = (ingredient.unit ?? '').trim();

    if (amount == null) return unit;

    final amountText = _formatAmount(amount);
    if (unit.isEmpty) return amountText;

    return '$amountText $unit';
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _openCookSheet({
    required BuildContext context,
    required RecipeDetail recipe,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return CookRecipeActionSheet(
          recipe: recipe,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(recipeDetailViewModelProvider(recipeId));
    final cookAsync = ref.watch(cookRecipeViewModelProvider);
    final favoriteIdsAsync = ref.watch(favoriteRecipeIdsProvider);

    final isFavorite = favoriteIdsAsync.maybeWhen(
      data: (ids) => ids.contains(recipeId),
      orElse: () => false,
    );

    final appBarTitle = detailAsync.maybeWhen(
      data: (recipe) => recipe.title,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle?.isNotEmpty == true ? appBarTitle! : 'Recipe',
        ),
        actions: [
          IconButton(
            onPressed: (favoriteIdsAsync.isLoading || favoriteIdsAsync.hasError)
                ? null
                : () {
                    ref
                        .read(favoriteRecipeIdsProvider.notifier)
                        .toggleFavorite(recipeId);
                  },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            tooltip: isFavorite
                ? 'Odebrat z oblíbených'
                : 'Uložit do oblíbených',
          ),
        ],
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (recipe) {
          return SafeArea(
            minimum: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: cookAsync.isLoading
                    ? null
                    : () {
                        _openCookSheet(
                          context: context,
                          recipe: recipe,
                        );
                      },
                icon: cookAsync.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restaurant),
                label: Text(
                  cookAsync.isLoading ? 'Ukládám...' : 'Uvařeno',
                ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, st) => Center(
          child: Text('Error: $e'),
        ),
        data: (recipe) {
          final theme = Theme.of(context);
          final steps = recipe.steps;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (recipe.imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: recipe.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 220,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                recipe.title,
                style: theme.textTheme.headlineSmall,
              ),

              if (recipe.createdBy.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'By ${recipe.createdBy}',
                  style: theme.textTheme.bodySmall,
                ),
              ],

              if (recipe.servings > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Servings: ${recipe.servings}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(context, 'Ingredients'),
                      const SizedBox(height: 8),
                      if (recipe.ingredients.isEmpty)
                        const Text('No ingredients listed.')
                      else
                        ...List.generate(recipe.ingredients.length, (index) {
                          final ingredient = recipe.ingredients[index];
                          final quantity =
                              _formatIngredientQuantity(ingredient);
                          final showQuantity = quantity.trim().isNotEmpty;

                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(ingredient.name),
                                trailing: showQuantity
                                    ? Text(
                                        quantity,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              ),
                              if (index != recipe.ingredients.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(context, 'Instructions'),
                      const SizedBox(height: 8),
                      if (steps.isEmpty)
                        Text(
                          'No instructions provided.',
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        ...steps.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text('${entry.key + 1}'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}