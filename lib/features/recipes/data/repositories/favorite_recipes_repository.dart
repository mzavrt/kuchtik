import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/recipes/domain/recipe.dart';
import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';

class FavoriteRecipesRepository {
  FavoriteRecipesRepository(this._supabase);

  final SupabaseClient _supabase;

  String _resolveImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return '';
    return _supabase.storage.from('images').getPublicUrl(rawPath);
  }

  RecipeDashboardItem _mapRecipeDashboardItem(Map<String, dynamic> json) {
    final rawPath = json['image_url'] as String?;
    final fullUrl = _resolveImageUrl(rawPath);
    return RecipeDashboardItem.fromJson(json, resolvedImageUrl: fullUrl);
  }

  Future<Set<String>> fetchFavoriteRecipeIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to load favorites.');
    }

    final response = await _supabase
        .from('user_favorite_recipes')
        .select('recipe_id')
        .eq('user_id', user.id);

    return response
        .map((row) => (row['recipe_id'] as String?)?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> addFavoriteRecipe(String recipeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to add favorites.');
    }

    await _supabase.from('user_favorite_recipes').insert({
      'user_id': user.id,
      'recipe_id': recipeId,
    });
  }

  Future<void> removeFavoriteRecipe(String recipeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to remove favorites.');
    }

    await _supabase
        .from('user_favorite_recipes')
        .delete()
        .eq('user_id', user.id)
        .eq('recipe_id', recipeId);
  }

  Future<List<Recipe>> fetchFavoriteRecipes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to load favorites.');
    }

    final response = await _supabase
        .from('user_favorite_recipes')
        .select('''
          created_at,
          recipes!inner(
            id,
            title,
            image_url,
            tags,
            prep_time_minutes,
            recipe_ingredient(
              ingredient_id,
              ingredients(id, name)
            )
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final items = <Recipe>[];
    for (final row in response) {
      final nested = row['recipes'];
      if (nested is Map<String, dynamic>) {
        items.add(_mapRecipeDashboardItem(nested));
      }
    }

    return items;
  }
}

final favoriteRecipesRepositoryProvider = Provider<FavoriteRecipesRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return FavoriteRecipesRepository(client);
});
