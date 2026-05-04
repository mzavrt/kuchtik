import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';
import 'package:kuchtik/features/recipes/data/repositories/cook_recipe_repository.dart';
import 'package:kuchtik/features/recipes/domain/cook_recipe_choice.dart';
import 'package:kuchtik/features/recipes/domain/recipe_detail.dart';

final cookRecipeViewModelProvider =
    AsyncNotifierProvider.autoDispose<CookRecipeViewModel, void>(
  CookRecipeViewModel.new,
);

class CookRecipeViewModel extends AsyncNotifier<void> {
  CookRecipeRepository get _repository =>
      ref.read(cookRecipeRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> cookByRecipe({
    required RecipeDetail recipe,
  }) async {
    await _cook(
      recipeId: recipe.id,
      choices: const [],
    );
  }

  Future<void> cookUsingAllAvailable({
    required RecipeDetail recipe,
  }) async {
    final choices = recipe.ingredients
        .map((ingredient) => ingredient.ingredientId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .map(
          (ingredientId) => CookRecipeChoice(
            ingredientId: ingredientId,
            usedAll: true,
          ),
        )
        .toList(growable: false);

    await _cook(
      recipeId: recipe.id,
      choices: choices,
    );
  }

  Future<void> cookWithoutPantryDeduction() async {
    if (state.isLoading) return;

    state = const AsyncLoading();

    try {
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> _cook({
    required String recipeId,
    required List<CookRecipeChoice> choices,
  }) async {
    if (state.isLoading) return;

    state = const AsyncLoading();

    try {
      await _repository.cookRecipe(
        recipeId: recipeId,
        choices: choices,
      );

      ref.invalidate(pantryViewModelProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}