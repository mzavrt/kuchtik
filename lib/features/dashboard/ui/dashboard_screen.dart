import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/dashboard/ui/view_models/dashboard_view_model.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/ingredient_filtered_section.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/recipe_card.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/section_header_delegate.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/view_models/fridge_view_model.dart';
import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';
import 'package:kuchtik/features/recipes/ui/generated_recipes_screen.dart';
import 'package:kuchtik/features/recipes/ui/recipe_detail_screen.dart';
import 'package:kuchtik/core/widgets/app_empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    this.onOpenPantry,
  });

  final VoidCallback? onOpenPantry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(recipeViewModelProvider);
    final pantryAsync = ref.watch(fridgeViewModelProvider);

    return dashboardAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chyba: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (data) {
        final pantryItems = pantryAsync.maybeWhen(
          data: (items) => items,
          orElse: () => null,
        );

        final hasPantryItems =
            pantryItems != null && pantryItems.isNotEmpty;

        final availableIngredients = pantryItems == null
            ? const <String>[]
            : _availableIngredientLabels(pantryItems);

        final allRecipes = _deduplicateRecipes([
          ...data.urgentRecipes,
          ...data.perfectMatchRecipes,
          ...data.missingOneRecipes,
          ...data.discoveryRecipes,
        ]);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              if (!hasPantryItems)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 340,
                    child: AppEmptyState(
                      icon: Icons.kitchen_outlined,
                      title: 'Lednice je zatím prázdná',
                      message:
                          'Přidejte suroviny do lednice a ukážeme vám recepty podle toho, co máte doma.',
                      primaryLabel:
                          onOpenPantry == null ? null : 'Doplnit lednici',
                      onPrimaryPressed: onOpenPantry,
                    ),
                  ),
                ),

              if (hasPantryItems && data.urgentRecipes.isNotEmpty)
                _RecipeSection(
                  title: '🚨 Hoří to! / Zachraň mě!',
                  recipes: data.urgentRecipes,
                  variant: RecipeCardVariant.urgent,
                ),

              if (hasPantryItems && data.perfectMatchRecipes.isNotEmpty)
                _RecipeSection(
                  title: '✅ 100% Shoda (Rovnou k plotně)',
                  recipes: data.perfectMatchRecipes,
                  variant: RecipeCardVariant.perfectMatch,
                ),

              if (hasPantryItems && data.missingOneRecipes.isNotEmpty)
                _RecipeSection(
                  title: '🤏 Chybí jen maličkost',
                  recipes: data.missingOneRecipes,
                  variant: RecipeCardVariant.missingOne,
                ),

              if (hasPantryItems &&
                  availableIngredients.isNotEmpty &&
                  allRecipes.isNotEmpty)
                IngredientFilteredSection(
                  availableIngredients: availableIngredients,
                  allRecipes: allRecipes,
                  onRecipeTap: (recipe) {
                    _openRecipeDetail(context, recipe.id);
                  },
                ),

              if (data.discoveryRecipes.isNotEmpty)
                _RecipeSection(
                  title: hasPantryItems
                      ? 'Máš chuť na něco nového?'
                      : 'Objev recepty',
                  recipes: data.discoveryRecipes,
                  variant: RecipeCardVariant.discovery,
                ),

              if (data.discoveryRecipes.isEmpty && !hasPantryItems)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Zatím tu nejsou žádné recepty k objevení.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 96),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: hasPantryItems
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GeneratedRecipesScreen(),
                      ),
                    );
                  },
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  elevation: 4,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'AI Recept na míru',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _openRecipeDetail(BuildContext context, String recipeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipeId),
      ),
    );
  }

  List<String> _availableIngredientLabels(List<UserIngredient> items) {
    final seen = <String>{};
    final result = <String>[];

    for (final item in items) {
      if (item.ingredient.isStaple) continue;

      final name = item.ingredient.name.trim();
      if (name.isEmpty) continue;

      final emoji = (item.ingredient.emoji ?? '').trim();
      final label = emoji.isEmpty ? name : '$emoji $name';

      if (seen.add(label)) {
        result.add(label);
      }
    }

    return result;
  }

  List<RecipeDashboardItem> _deduplicateRecipes(
    List<RecipeDashboardItem> recipes,
  ) {
    final result = <RecipeDashboardItem>[];
    final seenIds = <String>{};

    for (final recipe in recipes) {
      if (seenIds.add(recipe.id)) {
        result.add(recipe);
      }
    }

    return result;
  }
}

class _RecipeSection extends StatelessWidget {
  const _RecipeSection({
    required this.title,
    required this.recipes,
    required this.variant,
  });

  final String title;
  final List<RecipeDashboardItem> recipes;
  final RecipeCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: SectionHeaderDelegate(title),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: RecipeCard(
                    recipe: recipe,
                    variant: variant,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeDetailScreen(recipeId: recipe.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}