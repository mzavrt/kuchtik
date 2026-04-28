import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/recipes/domain/generated_recipe.dart';


class RecipeGenerationRepository {
  final SupabaseClient _supabaseClient;
  RecipeGenerationRepository(this._supabaseClient);

  Future<List<GeneratedRecipe>> generateRecipes({
    int maxRecipes = 3,
    bool quickOnly = true,
  }) async {
    final response = await _supabaseClient.functions.invoke(
      'generate-recipes',
      body: {
        'maxRecipes': maxRecipes,
        'quickOnly': quickOnly,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final recipes = data['recipes'] as List<dynamic>;

    return recipes
        .map((e) => GeneratedRecipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}


final recipeGenerationRepositoryProvider = Provider<RecipeGenerationRepository>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return RecipeGenerationRepository(supabaseClient);
});
