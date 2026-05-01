import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/recipes/domain/recipe_detail.dart';
import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';

class RecipeRepository {
  final SupabaseClient supabase;

  RecipeRepository(this.supabase);

  String _resolveImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return '';
    return supabase.storage.from('images').getPublicUrl(rawPath);
  }

  List<RecipeDashboardItem> _dedupeById(Iterable<RecipeDashboardItem> items) {
    final seen = <String>{};
    final result = <RecipeDashboardItem>[];
    for (final item in items) {
      if (seen.add(item.id)) {
        result.add(item);
      }
    }
    return result;
  }

  RecipeDashboardItem _mapDashboardItem(
    Map<String, dynamic> json, {
    String? missingOneText,
  }) {
    final rawPath = json['image_url'] as String?;
    final fullUrl = _resolveImageUrl(rawPath);
    return RecipeDashboardItem.fromJson(
      json,
      resolvedImageUrl: fullUrl,
      missingOneText: missingOneText,
    );
  }

  Future<Set<String>> _getUserPantryIngredientIds() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to load pantry-based recipes.');
    }

    final response = await supabase
        .from('user_pantry')
        .select('ingredient_id')
        .eq('user_id', user.id);

    return response
        .map((r) => r['ingredient_id'] as String)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<List<Map<String, dynamic>>> _getPublicRecipesWithIngredients({
    int limit = 60,
  }) async {
    final response = await supabase
        .from('recipes')
        .select('''
          id,
          title,
          image_url,
          tags,
          recipe_ingredient(
            ingredient_id,
              ingredients(id, name)
          )
          ''')
        .eq('is_public', true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  ({int missingCount, String? missingName}) _computeMissingInfo({
    required List<dynamic> recipeIngredients,
    required Set<String> pantryIngredientIds,
  }) {
    var missingCount = 0;
    String? missingName;

    for (final ri in recipeIngredients) {
      if (ri is! Map<String, dynamic>) continue;
      final ingredientId = ri['ingredient_id'] as String?;
      if (ingredientId == null) continue;

      if (!pantryIngredientIds.contains(ingredientId)) {
        missingCount += 1;

        final ingredient = ri['ingredients'];
        if (missingCount == 1 && ingredient is Map<String, dynamic>) {
          missingName = ingredient['name'] as String?;
        }
      }
    }

    return (missingCount: missingCount, missingName: missingName);
  }

  Future<List<RecipeDashboardItem>> getUrgentRecipes({
    int daysThreshold = 3,
    int limit = 20,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to load urgent recipes.');
    }

    final cutoff = DateTime.now().add(Duration(days: daysThreshold));

    final expiring = await supabase
        .from('user_pantry')
        .select('ingredient_id, expires_at')
        .eq('user_id', user.id)
        .lte('expires_at', cutoff.toIso8601String());

    final urgentIngredientIds = expiring
        .map((r) => r['ingredient_id'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (urgentIngredientIds.isEmpty) return [];

    final response = await supabase
        .from('recipes')
        .select('''
          id,
          title,
          image_url,
          tags,
          recipe_ingredient!inner(
            ingredient_id,
              ingredients(id, name)
          )
          ''')
        .eq('is_public', true)
        .inFilter(
          'recipe_ingredient.ingredient_id',
          urgentIngredientIds.toList(),
        )
        .limit(limit);

    final items = List<Map<String, dynamic>>.from(
      response,
    ).map(_mapDashboardItem);
    return _dedupeById(items);
  }

  Future<List<RecipeDashboardItem>> getPerfectMatchRecipes({
    int limit = 20,
  }) async {
    final pantryIngredientIds = await _getUserPantryIngredientIds();
    final recipes = await _getPublicRecipesWithIngredients(limit: 80);

    final result = <RecipeDashboardItem>[];
    for (final json in recipes) {
      final recipeIngredients =
          json['recipe_ingredient'] as List<dynamic>? ?? const [];

      if (recipeIngredients.isEmpty) {
        continue;
      }
      final missingInfo = _computeMissingInfo(
        recipeIngredients: recipeIngredients,
        pantryIngredientIds: pantryIngredientIds,
      );

      if (missingInfo.missingCount == 0) {
        result.add(_mapDashboardItem(json));
      }

      if (result.length >= limit) break;
    }

    return _dedupeById(result);
  }

  Future<List<RecipeDashboardItem>> getMissingOneRecipes({
    int limit = 20,
  }) async {
    final pantryIngredientIds = await _getUserPantryIngredientIds();
    final recipes = await _getPublicRecipesWithIngredients(limit: 120);

    final result = <RecipeDashboardItem>[];
    for (final json in recipes) {
      final recipeIngredients =
          json['recipe_ingredient'] as List<dynamic>? ?? const [];

      if (recipeIngredients.isEmpty) {
        continue;
      }
      final missingInfo = _computeMissingInfo(
        recipeIngredients: recipeIngredients,
        pantryIngredientIds: pantryIngredientIds,
      );

      if (missingInfo.missingCount == 1) {
        result.add(
          _mapDashboardItem(json, missingOneText: missingInfo.missingName),
        );
      }

      if (result.length >= limit) break;
    }

    return _dedupeById(result);
  }

  Future<List<RecipeDashboardItem>> getDiscoveryRecipes({
    Set<String> excludeRecipeIds = const {},
    int limit = 20,
  }) async {
    final recipes = await _getPublicRecipesWithIngredients(limit: 120);
    final result = <RecipeDashboardItem>[];

    for (final json in recipes) {
      final id = json['id'] as String?;
      if (id == null || id.isEmpty) continue;
      if (excludeRecipeIds.contains(id)) continue;

      result.add(_mapDashboardItem(json));

      if (result.length >= limit) break;
    }

    return _dedupeById(result);
  }

  Future<RecipeDetail> getRecipeDetail(String recipeId) async {
    final json = await supabase
        .from('recipes')
        .select(
          '''
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
            name
          )
        )
      ''',
        )
        .eq('id', recipeId)
        .single();

    final rawPath = json['image_url'] as String?;

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
