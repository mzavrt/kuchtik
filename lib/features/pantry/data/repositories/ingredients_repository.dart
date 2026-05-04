import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import  'package:kuchtik/core/providers/supabase_client.dart';



class IngredientsRepository {
  final SupabaseClient _supabaseClient;

  IngredientsRepository(this._supabaseClient);

  Future<List<Ingredient>> getAllIngredients() async {
    final response = await _supabaseClient
        .schema('public')
        .from('ingredients')
        .select(
          'id, name, category, default_unit, search_aliases, emoji, is_staple, measurement_type, default_value_per_piece, default_value_unit, est_price, default_use_within_days',
        );

    return response
        .map((json) => Ingredient.fromJson(json))
        .where((ingredient) => ingredient.name.isNotEmpty)
        .toList();
  }


}

final ingredientsRepositoryProvider = Provider<IngredientsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return IngredientsRepository(supabaseClient);
});

final allIngredientsProvider = FutureProvider<List<Ingredient>>((ref) async {
  final repository = ref.watch(ingredientsRepositoryProvider);
  return repository.getAllIngredients();
});