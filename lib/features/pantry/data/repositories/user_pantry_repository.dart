
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
           id, amount, unit, price_paid, expires_at, actual_value_per_piece,
          ingredients(id, name, category, default_unit, search_aliases, emoji, is_staple, measurement_type, default_value_per_piece, default_value_unit, est_price)''',
        )
        .eq('user_id', _supabaseClient.auth.currentUser!.id);

    return response.map((json) => UserIngredient.fromJson(json)).toList();
  }

  Future<void> addIngredientsToPantry(List<Map<String, Object?>> items) async {
    if (items.isEmpty) return;
    await _supabaseClient.from('user_pantry').insert(items);
  }

  Future<void> updatePantryItem(
    String id, {
    double? amount,
    double? pricePaid,
    DateTime? expiresAt,
    double? actualValuePerPiece,
  }) async {
    await _supabaseClient.from('user_pantry').update({
      ...?(amount == null ? null : {'amount': amount}),
      // These can be intentionally nullable, so callers should always pass them
      // when they want to change/clear them.
      'price_paid': pricePaid,
      'expires_at': expiresAt?.toIso8601String(),
      'actual_value_per_piece': actualValuePerPiece,
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