import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/dashboard/domain/ingredient_chip.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/recipe_card.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/section_header_delegate.dart';
import 'package:kuchtik/features/recipes/data/repositories/recipe_repository.dart';
import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';

typedef IngredientRecipeFilterArgs = ({
  String ingredientId,
  String? mealType,
});

final _selectedIngredientProvider =
    NotifierProvider.autoDispose<_SelectedIngredientNotifier, String?>(
  _SelectedIngredientNotifier.new,
);

class _SelectedIngredientNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String ingredientId) {
    state = ingredientId;
  }
}

final _filteredRecipesProvider = FutureProvider.autoDispose
    .family<List<RecipeDashboardItem>, IngredientRecipeFilterArgs>(
  (ref, args) {
    return ref.read(recipeRepositoryProvider).getRecipesForIngredientFilter(
          ingredientId: args.ingredientId,
          mealType: args.mealType,
        );
  },
);

class IngredientFilteredSection extends ConsumerWidget {
  const IngredientFilteredSection({
    super.key,
    required this.availableIngredients,
    required this.onRecipeTap,
    this.mealType,
  });

  final List<IngredientChip> availableIngredients;
  final ValueChanged<RecipeDashboardItem> onRecipeTap;
  final String? mealType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (availableIngredients.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox.shrink(),
      );
    }

    final selectedId = ref.watch(_selectedIngredientProvider);

    final effectiveSelectedId = selectedId == null ||
            !availableIngredients.any(
              (ingredient) => ingredient.id == selectedId,
            )
        ? availableIngredients.first.id
        : selectedId;

    final filteredAsync = ref.watch(
      _filteredRecipesProvider(
        (
          ingredientId: effectiveSelectedId,
          mealType: mealType,
        ),
      ),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: SectionHeaderDelegate('💡 Máš chuť na...'),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              itemCount: availableIngredients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final ingredient = availableIngredients[index];
                final isSelected = ingredient.id == effectiveSelectedId;

                return ChoiceChip(
                  label: Text(ingredient.label),
                  showCheckmark: false,
                  selected: isSelected,
                  onSelected: (_) {
                    ref
                        .read(_selectedIngredientProvider.notifier)
                        .select(ingredient.id);
                  },
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: switch (filteredAsync) {
              AsyncValue(isLoading: true) => const Center(
                  child: CircularProgressIndicator(),
                ),
              AsyncValue(hasError: true) => Center(
                  child: Text('Chyba: ${filteredAsync.error}'),
                ),
              AsyncValue(value: final recipes?) when recipes.isEmpty =>
                const Center(
                  child: Text('Pro tuto surovinu tu nic není.'),
                ),
              AsyncValue(value: final recipes?) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];

                    return RecipeCard(
                      recipe: recipe,
                      variant: RecipeCardVariant.ingredientFilter,
                      onTap: () => onRecipeTap(recipe),
                    );
                  },
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ],
    );
  }
}