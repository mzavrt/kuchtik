import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/core/extensions/string_extension.dart';
import 'package:kuchtik/core/services/notification_service.dart';
import 'package:kuchtik/features/dashboard/ui/view_models/dashboard_view_model.dart';
import 'package:kuchtik/features/pantry/data/repositories/ingredients_repository.dart';
import 'package:kuchtik/features/pantry/data/repositories/user_pantry_repository.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';


final pantryViewModelProvider =
    AsyncNotifierProvider<PantryViewModel, List<UserIngredient>>(
  PantryViewModel.new,
);

class PantryViewModel extends AsyncNotifier<List<UserIngredient>> {
  UserPantryRepository get _userPantryRepository =>
      ref.read(userPantryRepositoryProvider);

  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);

  @override
  Future<List<UserIngredient>> build() async {
    return loadUserPantry();
  }

  Future<List<UserIngredient>> loadUserPantry() async {
    return _userPantryRepository.getUserPantry();
  }

  void _invalidatePantryDependents() {
    ref.invalidate(dashboardViewModelProvider);
  }

  Future<void> updateUserIngredient(UserIngredient updated) async {
    state = const AsyncLoading<List<UserIngredient>>();

    try {
      await _userPantryRepository.updatePantryItem(
        updated.id,
        amount: updated.amount,
        pricePaid: updated.pricePaid,
        expiresAt: updated.expiresAt,
        actualValuePerPiece: updated.valuePerPiece,
      );

      state = AsyncData(await loadUserPantry());
      _invalidatePantryDependents();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteIngredientFromPantry(String id) async {
    state = const AsyncLoading<List<UserIngredient>>();

    try {
      await _userPantryRepository.deleteIngredientFromPantry(id);

      _notificationService.cancelNotification(
        id.createNotificationIdFromUuid(),
      );

      state = AsyncData(await loadUserPantry());
      _invalidatePantryDependents();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> clearPantry() async {
    final currentItems = state.value ?? await loadUserPantry();

    state = const AsyncLoading<List<UserIngredient>>();

    try {
      await _userPantryRepository.clearUserPantry();

      for (final item in currentItems) {
        _notificationService.cancelNotification(
          item.id.createNotificationIdFromUuid(),
        );
      }

      state = const AsyncData([]);
      _invalidatePantryDependents();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

List<Ingredient> filterIngredientSuggestions(
  List<Ingredient> all,
  String query,
) {
  if (query.isEmpty) {
    return all.take(5).toList();
  }

  final normalizedQuery = removeDiacritics(query).toLowerCase().trim();

  return all
      .where(
        (ingredient) =>
            removeDiacritics(ingredient.name)
                .toLowerCase()
                .contains(normalizedQuery) ||
            ingredient.searchAliases.any(
              (alias) => removeDiacritics(alias)
                  .toLowerCase()
                  .contains(normalizedQuery),
            ),
      )
      .take(5)
      .toList();
}

final ingredientSuggestionsProvider =
    Provider.family<AsyncValue<List<Ingredient>>, String>((ref, query) {
  final allAsync = ref.watch(allIngredientsProvider);

  return allAsync.whenData(
    (all) => filterIngredientSuggestions(all, query),
  );
});