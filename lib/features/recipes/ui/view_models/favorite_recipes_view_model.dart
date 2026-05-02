import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/recipes/data/repositories/favorite_recipes_repository.dart';
import 'package:kuchtik/features/recipes/domain/recipe.dart';

final favoriteRecipeIdsProvider =
    AsyncNotifierProvider<FavoriteRecipeIdsViewModel, Set<String>>(
  FavoriteRecipeIdsViewModel.new,
);

class FavoriteRecipeIdsViewModel extends AsyncNotifier<Set<String>> {
  FavoriteRecipesRepository get _repository =>
      ref.read(favoriteRecipesRepositoryProvider);

  @override
  Future<Set<String>> build() async {
    return _repository.fetchFavoriteRecipeIds();
  }

  Future<void> toggleFavorite(String recipeId) async {
    final previous = state;

    final current = state.maybeWhen(
          data: (ids) => ids,
          orElse: () => null,
        ) ??
        await future;
    final wasFavorite = current.contains(recipeId);

    final next = <String>{...current};
    if (wasFavorite) {
      next.remove(recipeId);
    } else {
      next.add(recipeId);
    }

    state = AsyncData(next);

    try {
      if (wasFavorite) {
        await _repository.removeFavoriteRecipe(recipeId);
      } else {
        await _repository.addFavoriteRecipe(recipeId);
      }

      ref.invalidate(favoriteRecipesProvider);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchFavoriteRecipeIds);
  }
}

final favoriteRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(favoriteRecipesRepositoryProvider);
  return repository.fetchFavoriteRecipes();
});
