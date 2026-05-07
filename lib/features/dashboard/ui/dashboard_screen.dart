import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/core/widgets/app_empty_state.dart';
import 'package:kuchtik/features/dashboard/ui/providers/meal_type_filter_provider.dart';
import 'package:kuchtik/features/dashboard/ui/view_models/dashboard_view_model.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/ingredient_filtered_section.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/recipe_card.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/section_header_delegate.dart';
import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';
import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';
import 'package:kuchtik/features/recipes/ui/generated_recipes_screen.dart';
import 'package:kuchtik/features/recipes/ui/recipe_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    this.onOpenPantry,
  });

  final VoidCallback? onOpenPantry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMealType = ref.watch(selectedMealTypeProvider);

    final dashboardAsync = ref.watch(
      dashboardViewModelProvider(selectedMealType),
    );

    final pantryAsync = ref.watch(pantryViewModelProvider);

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

        final hasPantryItems = pantryItems != null && pantryItems.isNotEmpty;
        final availableIngredients = data.ingredientFilters;

        final hasAnyRecipes =
            data.urgentRecipes.isNotEmpty ||
            data.perfectMatchRecipes.isNotEmpty ||
            data.missingOneRecipes.isNotEmpty ||
            data.discoveryRecipes.isNotEmpty;

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

              if (hasPantryItems || data.discoveryRecipes.isNotEmpty)
                const _MealTypeFilter(),

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

              if (hasPantryItems && availableIngredients.isNotEmpty)
                IngredientFilteredSection(
                  availableIngredients: availableIngredients,
                  mealType: selectedMealType,
                  onRecipeTap: (recipe) => _openRecipeDetail(
                    context,
                    recipe.id,
                  ),
                ),

              if (data.discoveryRecipes.isNotEmpty)
                _RecipeSection(
                  title: hasPantryItems
                      ? 'Máš chuť na něco nového?'
                      : 'Objev recepty',
                  recipes: data.discoveryRecipes,
                  variant: RecipeCardVariant.discovery,
                ),

              if (!hasAnyRecipes)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        selectedMealType == null
                            ? 'Zatím tu nejsou žádné recepty.'
                            : 'Pro vybraný typ jídla tu zatím nejsou žádné recepty.',
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
                        builder: (_) => GeneratedRecipesScreen(
                          initialMealType: selectedMealType,
                        ),
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
                    'Vymyslet z mých zásob',
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
}

class _MealTypeFilter extends ConsumerWidget {
  const _MealTypeFilter();

  static const filters = <({String? value, String label})>[
    (value: null, label: 'Vše'),
    (value: 'breakfast', label: 'Snídaně'),
    (value: 'main_course', label: 'Hlavní chod'),
    (value: 'soup', label: 'Polévka'),
    (value: 'snack', label: 'Svačina'),
    (value: 'dessert', label: 'Dezert'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMealTypeProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Co chceš vařit?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selected == filter.value;

                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) {
                      ref
                          .read(selectedMealTypeProvider.notifier)
                          .select(filter.value);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
                          builder: (_) => RecipeDetailScreen(
                            recipeId: recipe.id,
                          ),
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