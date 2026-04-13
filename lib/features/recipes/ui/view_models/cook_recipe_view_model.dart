import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/domain/pantry_deduction.dart';
import 'package:kuchtik/features/pantry/ui/view_models/fridge_view_model.dart';
import 'package:kuchtik/features/recipes/data/repositories/cook_recipe_repository.dart';

final cookRecipeViewModelProvider =
    AsyncNotifierProvider.autoDispose<CookRecipeViewModel, void>(
  CookRecipeViewModel.new,
);

class CookRecipeViewModel extends AsyncNotifier<void> {
  CookRecipeRepository get _cookRecipeRepository =>
      ref.read(cookRecipeRepositoryProvider);

  FridgeViewModel get _fridgeViewModel => ref.read(fridgeViewModelProvider.notifier);

  @override
  Future<void> build() async {
   
  }

  Future<void> cook({required List<PantryDeduction> deductions}) async {
    if (state.isLoading) return;

    
    final previousPantrySnapshot = _fridgeViewModel.applyLocalDeductions(deductions);

   
    state = const AsyncLoading();
    try {
      await _cookRecipeRepository.cookWithDeductions(deductions: deductions);
      state = const AsyncData(null);
    } catch (e, st) {
    
      _fridgeViewModel.restoreLocalPantry(previousPantrySnapshot);
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
