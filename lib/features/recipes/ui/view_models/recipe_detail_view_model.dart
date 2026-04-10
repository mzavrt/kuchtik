import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuchtik/features/recipes/domain/recipe_detail.dart';
import 'package:kuchtik/features/recipes/data/repositories/recipe_repository.dart';



final recipeDetailViewModelProvider =
    AsyncNotifierProvider.autoDispose.family<RecipeDetailViewModel, RecipeDetail, String>(
  RecipeDetailViewModel.new,
);

class RecipeDetailViewModel
    extends AsyncNotifier<RecipeDetail> {

      final String recipeId;
      RecipeDetailViewModel(this.recipeId);


  RecipeRepository get _recipeRepository => ref.read(recipeRepositoryProvider);

  @override
  Future<RecipeDetail> build() async {
    return _recipeRepository.getRecipeDetail(recipeId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _recipeRepository.getRecipeDetail(recipeId));
  }
}