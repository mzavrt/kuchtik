import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/features/recipes/domain/cook_recipe_choice.dart';

final cookRecipeRepositoryProvider = Provider<CookRecipeRepository>((ref) {
  return CookRecipeRepository(Supabase.instance.client);
});

class CookRecipeRepository {
  const CookRecipeRepository(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<void> cookRecipe({
    required String recipeId,
    required List<CookRecipeChoice> choices,
  }) async {
    try {
      await _supabaseClient.rpc(
      'cook_recipe',
      params: {
        'p_recipe_id': recipeId,
        'p_choices': choices.map((choice) => choice.toJson()).toList(),
      },
    );
    } catch (e) {
      // Handle error, e.g., log it or rethrow
      print('Error cooking recipe: $e');
      throw Exception('Failed to cook recipe');
    }
  }
}