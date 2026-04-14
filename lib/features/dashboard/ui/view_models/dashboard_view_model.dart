import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/dashboard/ui/states/dashboard_state.dart';
import 'package:kuchtik/features/recipes/data/repositories/recipe_repository.dart';

final recipeViewModelProvider =
    AsyncNotifierProvider<DashboardViewModel, DashboardState>(
      DashboardViewModel.new,
    );

class DashboardViewModel extends AsyncNotifier<DashboardState> {
  RecipeRepository get _recipeRepository => ref.read(recipeRepositoryProvider);

  @override
  Future<DashboardState> build() async {
    final urgent = await _recipeRepository.getUrgentRecipes();
    final perfectMatch = await _recipeRepository.getPerfectMatchRecipes();
    final missingOne = await _recipeRepository.getMissingOneRecipes();

    final excludeIds = <String>{
      ...urgent.map((r) => r.id),
      ...perfectMatch.map((r) => r.id),
      ...missingOne.map((r) => r.id),
    };

    final discovery = await _recipeRepository.getDiscoveryRecipes(
      excludeRecipeIds: excludeIds,
    );

    return DashboardState(
      urgentRecipes: urgent,
      perfectMatchRecipes: perfectMatch,
      missingOneRecipes: missingOne,
      discoveryRecipes: discovery,
    );
  }
}
