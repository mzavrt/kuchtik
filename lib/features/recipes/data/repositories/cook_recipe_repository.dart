import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/pantry/domain/pantry_deduction.dart';

class CookRecipeRepository {
  final SupabaseClient _supabaseClient;

  CookRecipeRepository(this._supabaseClient);

  Future<void> cookWithDeductions({required List<PantryDeduction> deductions}) async {
    final payload = deductions.map((d) => d.toJson()).toList(growable: false);
    
    await _supabaseClient.rpc('cook_recipe', params: {'deductions': payload});
  }
}

final cookRecipeRepositoryProvider = Provider<CookRecipeRepository>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return CookRecipeRepository(supabaseClient);
});
