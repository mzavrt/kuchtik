import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/recipes/domain/recipe_detail.dart';
import 'package:kuchtik/features/recipes/domain/recipe_summary.dart';

class RecipeRepository  {

final SupabaseClient supabase;

  RecipeRepository(this.supabase);

    Future<List<RecipeSummary>> getRecipesBasedOnIngredients() async {
    final response = await supabase
    .from('recipes')
    .select('''id, title, image_url, created_by, is_public, tags,
      recipe_ingredient!inner(
        ingredients!inner(
          user_pantry!inner(user_id)
        )
      )
    ''')
    .eq('recipe_ingredient.ingredients.user_pantry.user_id', supabase.auth.currentUser!.id)
    .eq('is_public', true);

    return response.map((json) {
    final rawPath = json['image_url'] as String?;
    
    // Need to resolve the full URL using Supabase Storage if the path is not null
    String? fullUrl;
    if (rawPath != null && rawPath.isNotEmpty) {
      fullUrl = supabase.storage.from('images').getPublicUrl(rawPath);
    }

    return RecipeSummary.fromJson(json, resolvedImageUrl: fullUrl);
  }).toList();
  }

  Future<RecipeDetail> getRecipeDetail(String recipeId) async {
  final json = await supabase
      .from('recipes')
      .select('''
        id, 
        title, 
        instructions, 
        image_url, 
        is_public, 
        created_by,
        recipe_ingredient!inner (
          amount,
          unit,
          ingredients!inner (
            id,
            name,
            density_g_ml
          )
        )
      ''') // Ensure 'recipe_ingredients' and 'name' match your exact DB column/table names
      .eq('id', recipeId)
      .single();

   final rawPath = json['image_url'] as String?;
    
    // Need to resolve the full URL using Supabase Storage if the path is not null
    String? fullUrl;
    if (rawPath != null && rawPath.isNotEmpty) {
      fullUrl = supabase.storage.from('images').getPublicUrl(rawPath);
    }


  return RecipeDetail.fromJson(json, resolvedImageUrl: fullUrl);
}


}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return RecipeRepository(supabaseClient);
});


