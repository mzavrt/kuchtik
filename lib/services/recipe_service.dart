import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/models/recipe.dart';

class RecipeService {

  final _supabase = Supabase.instance.client;

  Future<List<Recipe>> getRecipesBasedOnIngredients() async {
    final response = await _supabase.from('recipes').select('title,image_url, recipe_ingredient!inner(recipe_id, ingredient_id), user_pantry!inner(ingredient_id)').eq('used_id', _supabase.auth.currentUser!.id);
    return response.map((data) => Recipe.fromJson(data)).toList();
  }

  

}