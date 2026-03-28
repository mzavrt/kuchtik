import 'package:kuchtik/core/data/supabase_client.dart';
import 'package:kuchtik/features/recipes/domain/recipe.dart';

class RecipeService {
  Future<List<Recipe>> getRecipesBasedOnIngredients() async {
    final response = await supabase
        .from('recipes')
        .select(
          'title,image_url, recipe_ingredient!inner(recipe_id, ingredient_id), user_pantry!inner(ingredient_id)',
        )
        .eq('used_id', supabase.auth.currentUser!.id);

    return response.map((data) => Recipe.fromJson(data)).toList();
  }
}
