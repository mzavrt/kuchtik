
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/core/providers/supabase_client.dart';

class UserPantryRepository {
  final SupabaseClient _supabaseClient;

  UserPantryRepository(this._supabaseClient);

  
  Future<List<UserIngredient>> getUserPantry() async {
    final response = await _supabaseClient
        .from('user_pantry')
        .select('''
           id, amount, unit, price_paid, expires_at, is_discounted,
          ingredients(id, name, category, default_unit, search_aliases, density_g_ml)''',
        )
        .eq('user_id', _supabaseClient.auth.currentUser!.id);

    return response.map((json) => UserIngredient.fromJson(json)).toList();
  }

  Future<String> addIngredientToPantry({
    required String ingredientId,
    required double amount,
    required String unit,
    required double price,
    required DateTime expiresAt,
    bool isDiscounted = false,
  }) async {
    final response = await _supabaseClient.from('user_pantry').insert({
      //'user_id': _supabaseClient.auth.currentUser!.id, default value in supabase
      'ingredient_id': ingredientId,
      'amount': amount,
      'unit': unit,
      'price_paid': price,
      'expires_at': expiresAt.toIso8601String(),
      'is_discounted': isDiscounted,
    })
    .select('id') // Return the inserted record's ID
    .single(); // Get the single inserted record
  
    return response['id'] as String; // Return the UUID of the newly added ingredient

  }

  Future<void> addIngredientsToPantry(List<Map<String, Object?>> items) async {
    if (items.isEmpty) return;
    await _supabaseClient.from('user_pantry').insert(items);
  }

  Future<void> updateUserIngredient({
    required String id,
    required double amount,
    required String unit,
    required double price,
    required DateTime expiresAt,
    required bool isDiscounted,
  }) async {
    await _supabaseClient.from('user_pantry').update({
      'amount': amount,
      'unit': unit,
      'price_paid': price,
      'expires_at': expiresAt.toIso8601String(),
      'is_discounted': isDiscounted,
    }).eq('id', id);
  }

    Future<void> deleteIngredientFromPantry(String id) async {
    await _supabaseClient.from('user_pantry').delete().eq('id', id);
  }

}

final userPantryRepositoryProvider = Provider<UserPantryRepository>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return UserPantryRepository(supabaseClient);
});