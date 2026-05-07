import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/recipes/data/repositories/generate_recipes_repository.dart';
import 'package:kuchtik/features/recipes/domain/generated_recipe.dart';

final generatedRecipesViewModelProvider = AsyncNotifierProvider.autoDispose<
    GeneratedRecipesViewModel, List<GeneratedRecipe>?>(
  GeneratedRecipesViewModel.new,
);

class GeneratedRecipesViewModel extends AsyncNotifier<List<GeneratedRecipe>?> {
  RecipeGenerationRepository get _repository =>
      ref.read(recipeGenerationRepositoryProvider);

  @override
  Future<List<GeneratedRecipe>?> build() async {
    return null;
  }

  Future<void> generateRecipes({
    String? mealType,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return _repository.generateRecipes(
        maxRecipes: 3,
        quickOnly: true,
        mealType: mealType,
      );
    });
  }

  Future<void> regenerateRecipes({
    String? mealType,
  }) async {
    await generateRecipes(mealType: mealType);
  }

  void clearResults() {
    state = const AsyncData(null);
  }
}