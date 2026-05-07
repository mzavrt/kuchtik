import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/dashboard/ui/states/dashboard_state.dart';
import 'package:kuchtik/features/recipes/data/repositories/recipe_repository.dart';

final dashboardViewModelProvider =
    FutureProvider.family<DashboardState, String?>(
  (ref, mealType) async {
    final repository = ref.read(recipeRepositoryProvider);

    final recipesState = await repository.getDashboardRecipes(
      mealType: mealType,
    );

    final ingredientFilters = await repository.getAvailableIngredientFilters(
      mealType: mealType,
    );

    return DashboardState(
      urgentRecipes: recipesState.urgentRecipes,
      perfectMatchRecipes: recipesState.perfectMatchRecipes,
      missingOneRecipes: recipesState.missingOneRecipes,
      discoveryRecipes: recipesState.discoveryRecipes,
      ingredientFilters: ingredientFilters,
    );
  },
);