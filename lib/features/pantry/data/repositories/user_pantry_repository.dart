
import 'package:kuchtik/features/pantry/domain/notification_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/pantry/domain/notification_data.dart';

class UserPantryRepository {
  final SupabaseClient _supabaseClient;

  UserPantryRepository(this._supabaseClient);

  
  Future<List<UserIngredient>> getUserPantry() async {
    final response = await _supabaseClient
        .from('user_pantry')
        .select('''
           id, amount, unit, price_paid, expires_at, value_per_piece, created_at, is_leftover,
          ingredients(id, name, category, default_unit, search_aliases, emoji, is_staple, measurement_type, default_value_per_piece, default_value_unit, est_price, default_use_within_days, pantry_tracking_mode)''',
        )
        .eq('user_id', _supabaseClient.auth.currentUser!.id);

    return response.map((json) => UserIngredient.fromJson(json)).toList();
  }

  Future<List<NotificationData>> addIngredientsToPantry(
  List<Map<String, Object?>> items,
) async {
  if (items.isEmpty) return [];

  //return list of inserted IDs and expiration dates for notificaions scheduling
  final insertedRows = await _supabaseClient
      .from('user_pantry')
      .insert(items)
      .select('''id, expires_at, price_paid,
      ingredients(id, name, est_price )'''); // Adjust the selected fields as needed


   return insertedRows
      .map<NotificationData>(
        (row) => NotificationData.fromJson(row),
      )
      .toList();
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
      'value_per_piece': actualValuePerPiece,

    }).eq('id', id);
  }

    Future<void> deleteIngredientFromPantry(String id) async {
    await _supabaseClient.from('user_pantry').delete().eq('id', id);
  }

  Future<void> clearUserPantry() async {
  final userId = _supabaseClient.auth.currentUser?.id;

  if (userId == null) {
    throw StateError('User is not authenticated.');
  }

  await _supabaseClient
      .from('user_pantry')
      .delete()
      .eq('user_id', userId);
}

}

final userPantryRepositoryProvider = Provider<UserPantryRepository>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return UserPantryRepository(supabaseClient);
});