import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/core/providers/supabase_client.dart';

final userPantryIngredientIdsProvider = FutureProvider<Set<String>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;
  if (user == null) {
    return <String>{};
  }

  final response = await supabase
      .from('user_pantry')
      .select('ingredient_id, amount')
      .eq('user_id', user.id)
      .gt('amount', 0);

  return response
      .map((row) => (row['ingredient_id'] as String?)?.trim())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();
});
