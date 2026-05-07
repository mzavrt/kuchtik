import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/features/recipes/domain/cook_recipe_choice.dart';
import 'package:kuchtik/features/recipes/domain/cook_recipe_pantry_update_result.dart';

final cookRecipeRepositoryProvider = Provider<CookRecipeRepository>((ref) {
  return CookRecipeRepository(Supabase.instance.client);
});

class CookRecipeRepository {
  const CookRecipeRepository(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<CookRecipePantryUpdateResult> cookRecipe({
  required String recipeId,
  required List<CookRecipeChoice> choices,
}) async {
  final response = await _supabaseClient.rpc(
    'cook_recipe',
    params: {
      'p_recipe_id': recipeId,
      'p_choices': choices.map((x) => x.toJson()).toList(),
    },
  );

  if (response == null) {
    return CookRecipePantryUpdateResult.empty;
  }

  return CookRecipePantryUpdateResult.fromJson(
    Map<String, dynamic>.from(response as Map),
  );
}
}