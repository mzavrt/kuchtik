import 'package:kuchtik/features/recipes/domain/recipe_summary.dart';
import 'package:kuchtik/features/recipes/data/repositories/recipe_repository.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';



final recipesViewModelProvider =
    AsyncNotifierProvider<RecipesViewModel, List<RecipeSummary>>(
  RecipesViewModel.new,
);

class RecipesViewModel extends AsyncNotifier<List<RecipeSummary>> {
  RecipeRepository get _recipeRepository => ref.read(recipeRepositoryProvider);

  @override
  Future<List<RecipeSummary>> build() async {
    return loadRecipes();
  }

  Future<List<RecipeSummary>> loadRecipes() async {
    return _recipeRepository.getRecipesBasedOnIngredients();
  }


}