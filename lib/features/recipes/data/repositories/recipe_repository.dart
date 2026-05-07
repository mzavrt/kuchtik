import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/recipes/domain/recipe_detail.dart';
import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';
import 'package:kuchtik/features/dashboard/ui/states/dashboard_state.dart';
import 'package:kuchtik/features/dashboard/domain/ingredient_chip.dart';

class RecipeRepository {
  final SupabaseClient supabase;

  RecipeRepository(this.supabase);

  String _resolveImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return '';
    return supabase.storage.from('images').getPublicUrl(rawPath);
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

  Future<DashboardState> getDashboardRecipes({
    String? mealType,
    int urgentDays = 3,
    int limitPerSection = 20,
    int discoveryLimit = 20,
    int urgentMaxMissing = 2,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to load dashboard recipes.');
    }

    final data = await supabase.rpc(
      'get_dashboard_recipes',
      params: {
        'p_urgent_days': urgentDays,
        'p_limit_per_section': limitPerSection,
        'p_discovery_limit': discoveryLimit,
        'p_urgent_max_missing': urgentMaxMissing,
        'p_meal_type': mealType,
      },
    ) as Map<String, dynamic>;

    List<RecipeDashboardItem> parseSection(String key) {
      final rows = data[key] as List<dynamic>? ?? const [];

      return rows
          .whereType<Map<String, dynamic>>()
          .map(_mapDashboardItem)
          .toList(growable: false);
    }

   return DashboardState(
  urgentRecipes: parseSection('urgent'),
  perfectMatchRecipes: parseSection('perfect_match'),
  missingOneRecipes: parseSection('missing_one'),
  discoveryRecipes: parseSection('discovery'),
  ingredientFilters: const [],
);
  }

  Future<List<RecipeDashboardItem>> getRecipesForIngredientFilter({
  required String ingredientId,
  String? mealType,
  int limit = 10,
}) async {
  final response = await supabase.rpc(
    'get_recipes_for_ingredient_filter',
    params: {
      'p_ingredient_id': ingredientId,
      'p_limit': limit,
      'p_meal_type': mealType,
    },
  );

  final rows = response as List<dynamic>? ?? const [];

  return rows
      .whereType<Map<String, dynamic>>()
      .map(_mapDashboardItem)
      .toList(growable: false);
}

 Future<List<IngredientChip>> getAvailableIngredientFilters({
  String? mealType,
}) async {
  final response = await supabase.rpc(
    'get_available_ingredient_filters',
    params: {
      'p_meal_type': mealType,
    },
  );

  final rows = response as List<dynamic>? ?? const [];

  return rows.whereType<Map<String, dynamic>>().map((json) {
    final id = json['id'] as String;
    final name = (json['name'] as String? ?? '').trim();
    final emoji = (json['emoji'] as String? ?? '').trim();
    final label = emoji.isEmpty ? name : '$emoji $name';

    return (id: id, label: label);
  }).toList(growable: false);
}

  Future<RecipeDetail> getRecipeDetail(String recipeId) async {
    final json = await supabase
        .from('recipes')
        .select(
          '''
          id,
          title,
          servings,
          instruction_steps,
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